package rhi_vulkan

import "../collections"
import "../debug"
import "../window"
import "core:c"
import glm "core:math/linalg"
import win32 "core:sys/windows"
import "vendor:sdl2"
import vk "vendor:vulkan"

createSubsystem :: proc() -> SubsystemState {
    state := SubsystemState{}

    {
        vk_dll := win32.LoadLibraryW(win32.utf8_to_wstring("vulkan-1.dll"))

        get_instance_proc_address := auto_cast win32.GetProcAddress(vk_dll, "vkGetInstanceProcAddr")

        if get_instance_proc_address == nil {
            panic("vkGetInstanceProcAddr not loaded")
        }
        vk.load_proc_addresses_global(get_instance_proc_address)
    }

    tempWindow := sdl2.CreateWindow(
        "temp window to get instance extensions",
        0,
        0,
        800,
        600,
        sdl2.WINDOW_VULKAN | sdl2.WINDOW_ALLOW_HIGHDPI | sdl2.WINDOW_SHOWN,
    )
    defer sdl2.DestroyWindow(tempWindow)

    instance: vk.Instance = ---
    {
        extensionsCount := u32(0)
        sdl2.Vulkan_GetInstanceExtensions((^sdl2.Window)(tempWindow), &extensionsCount, nil)
        extensions := make([]cstring, extensionsCount)
        defer delete(extensions)
        sdl2.Vulkan_GetInstanceExtensions((^sdl2.Window)(tempWindow), &extensionsCount, raw_data(extensions))

        // create vulkan instance
        appInfo := vk.ApplicationInfo {
            sType              = vk.StructureType.APPLICATION_INFO,
            pNext              = nil,
            pApplicationName   = "RenderPractice",
            applicationVersion = vk.MAKE_VERSION(1, 0, 0),
            pEngineName        = "No Engine",
            engineVersion      = vk.MAKE_VERSION(1, 0, 0),
            apiVersion         = vk.API_VERSION_1_0,
        }

        instanceInfo := vk.InstanceCreateInfo {
            sType                   = vk.StructureType.INSTANCE_CREATE_INFO,
            pNext                   = nil,
            flags                   = {},
            pApplicationInfo        = &appInfo,
            enabledLayerCount       = 0,
            ppEnabledLayerNames     = nil,
            enabledExtensionCount   = extensionsCount,
            ppEnabledExtensionNames = raw_data(extensions),
        }

        checkResult(vk.CreateInstance(&instanceInfo, nil, &instance), "CreateInstance")
        vk.load_proc_addresses_instance(instance)
        state.instance = instance
    }

    windowSurface: vk.SurfaceKHR = ---
    if !sdl2.Vulkan_CreateSurface(tempWindow, instance, &windowSurface) {
        panic("Failed to create window surface")
    }
    defer vk.DestroySurfaceKHR(instance, windowSurface, nil)

    // pick device
    {
        physicalDeviceCount := u32(0)
        checkResult(vk.EnumeratePhysicalDevices(instance, &physicalDeviceCount, nil), "EnumeratePhysicalDevices")
        physicalDevices := make([]vk.PhysicalDevice, physicalDeviceCount)
        defer delete(physicalDevices)
        checkResult(
            vk.EnumeratePhysicalDevices(instance, &physicalDeviceCount, raw_data(physicalDevices)),
            "EnumeratePhysicalDevices",
        )

        for i := u32(0); i < physicalDeviceCount; i += 1 {
            dev := physicalDevices[i]

            properties: vk.PhysicalDeviceProperties = ---
            vk.GetPhysicalDeviceProperties(dev, &properties)

            if properties.deviceType != vk.PhysicalDeviceType.DISCRETE_GPU {
                continue
            }

            features: vk.PhysicalDeviceFeatures = ---
            vk.GetPhysicalDeviceFeatures(dev, &features)

            if !features.geometryShader {
                continue
            }

            physicalDevice := PhysicalDevice {
                device = rawptr(dev),
            }

            if !collections.tryAdd(&state.physicalDevices.buffer, physicalDevice) {
                debug.log("VulkanRenderer", debug.LogLevel.ERROR, "Failed to add physical device to buffer")
                break
            }
        }

        if physicalDeviceCount == 0 {
            debug.log("VulkanRenderer", debug.LogLevel.ERROR, "No physical devices found")
        }

        state.selectedDeviceIdx = 0
    }

    // pick queues
    graphicsIndex, presentIndex := -1, -1
    {
        physicalDevice := vk.PhysicalDevice(
            collections.access(&state.physicalDevices.buffer, u64(state.selectedDeviceIdx)).device,
        )

        queueFamilyCount := u32(0)
        vk.GetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, nil)
        queueFamilies := make([]vk.QueueFamilyProperties, queueFamilyCount)
        defer delete(queueFamilies)
        vk.GetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, raw_data(queueFamilies))

        for i := u32(0); i < queueFamilyCount; i += 1 {
            queueFamily := queueFamilies[i]

            if queueFamily.queueCount > 0 && .GRAPHICS in queueFamily.queueFlags {
                graphicsIndex = int(i)
            }

            surfaceSupported: b32 = false
            checkResult(
                vk.GetPhysicalDeviceSurfaceSupportKHR(physicalDevice, i, windowSurface, &surfaceSupported),
                "GetPhysicalDeviceSurfaceSupportKHR",
            )
            if queueFamily.queueCount > 0 && surfaceSupported {
                presentIndex = int(i)
            }

            if graphicsIndex != -1 && presentIndex != -1 {
                break
            }
        }

        if graphicsIndex == -1 || presentIndex == -1 {
            panic("Failed to find graphics and present queues")
        }
    }

    {
        physicalDevice := vk.PhysicalDevice(
            collections.access(&state.physicalDevices.buffer, u64(state.selectedDeviceIdx)).device,
        )

        enabledLayers := []cstring{}
        extensions := []cstring{vk.KHR_SWAPCHAIN_EXTENSION_NAME}
        queuePriority := []f32{1}
        uniqueQueueIndices: collections.FixedSizeBuffer(u32, 2)
        if graphicsIndex == presentIndex {
            uniqueQueueIndices.count = 1
            uniqueQueueIndices.buffer[0] = u32(graphicsIndex)
        } else {
            uniqueQueueIndices.count = 2
            uniqueQueueIndices.buffer[0] = u32(graphicsIndex)
            uniqueQueueIndices.buffer[1] = u32(presentIndex)
        }

        queueCreateInfos: collections.FixedSizeBuffer(vk.DeviceQueueCreateInfo, 2)
        for i in 0 ..< uniqueQueueIndices.count {
            if !collections.tryAdd(
                &queueCreateInfos,
                vk.DeviceQueueCreateInfo {
                    sType = vk.StructureType.DEVICE_QUEUE_CREATE_INFO,
                    pNext = nil,
                    flags = {},
                    queueFamilyIndex = uniqueQueueIndices.buffer[i],
                    queueCount = 1,
                    pQueuePriorities = raw_data(queuePriority),
                },
            ) {
                debug.log("VulkanRenderer", debug.LogLevel.ERROR, "Failed to add queue create info to buffer")
            }
        }

        physicalDeviceFeatures := vk.PhysicalDeviceFeatures {
            geometryShader    = true,
            samplerAnisotropy = true,
        }

        deviceCreateInfo := vk.DeviceCreateInfo {
            sType                   = vk.StructureType.DEVICE_CREATE_INFO,
            pNext                   = nil,
            flags                   = {},
            queueCreateInfoCount    = u32(queueCreateInfos.count),
            pQueueCreateInfos       = &queueCreateInfos.buffer[0],
            enabledLayerCount       = u32(len(enabledLayers)),
            ppEnabledLayerNames     = raw_data(enabledLayers),
            enabledExtensionCount   = u32(len(extensions)),
            ppEnabledExtensionNames = raw_data(extensions),
            pEnabledFeatures        = &physicalDeviceFeatures,
        }

        device: vk.Device = ---
        checkResult(vk.CreateDevice(physicalDevice, &deviceCreateInfo, nil, &device), "CreateDevice")
        vk.load_proc_addresses_device(device)

        graphicsQueue, presentQueue := vk.Queue{}, vk.Queue{}
        vk.GetDeviceQueue(device, u32(graphicsIndex), 0, &graphicsQueue)
        vk.GetDeviceQueue(device, u32(presentIndex), 0, &presentQueue)

        state.device = Device {
            device           = rawptr(device),
            graphicsQueue    = rawptr(graphicsQueue),
            graphicsQueueIdx = u32(graphicsIndex),
            presentQueue     = rawptr(presentQueue),
            presentQueueIdx  = u32(presentIndex),
        }
    }

    return state
}

destroySubsystem :: proc(state: ^SubsystemState) {
    vk.DestroyDevice(vk.Device(state.device.device), nil)
    state.device = Device{}

    collections.clear(&state.physicalDevices.buffer)
    state.physicalDevices = PhysicalDeviceBuffer{}

    vk.DestroyInstance(vk.Instance(state.instance), nil)
    state.instance = nil
}

updateSubsystem :: proc(windowState: ^window.SubsystemState, state: ^SubsystemState) {
    instance := vk.Instance(state.instance)

    // deinit windows about to be closed
    for i := u64(0); i < collections.getCount(&windowState.windowsToBeClosed.buffer); i += 1 {
        windowIdx := collections.access(&windowState.windowsToBeClosed.buffer, i)^
        windowState := collections.access(&windowState.windows.buffer, u64(windowIdx))

        rwsIdx, ok := collections.search(&state.windows.buffer, proc(ws: WindowState, handle: u64) -> bool {
                return ws.handle == handle
            }, windowState.handle)

        if !ok {
            // window was never initialised for renderer successfully
            continue
        }

        rendererWindowStatePtr := collections.access(&state.windows.buffer, rwsIdx)
        rendererWindowState := rendererWindowStatePtr^
        collections.tryRemoveAt(&state.windows.buffer, rwsIdx, 1)

        for i := u64(0); i < collections.getCount(&rendererWindowState.framebuffers.buffer); i += 1 {
            framebuffer := collections.access(&rendererWindowState.framebuffers.buffer, i)^
            vk.DestroyFramebuffer(vk.Device(state.device.device), vk.Framebuffer(framebuffer), nil)
        }
        rendererWindowState.framebuffers.buffer.count = 0
        vk.DestroyRenderPass(vk.Device(state.device.device), vk.RenderPass(rendererWindowState.renderPass), nil)
        vk.DestroyImageView(vk.Device(state.device.device), vk.ImageView(rendererWindowState.depthImageView), nil)
        vk.DestroyImage(vk.Device(state.device.device), vk.Image(rendererWindowState.depthImage), nil)
        for i := u64(0); i < collections.getCount(&rendererWindowState.swapchainImageViews.buffer); i += 1 {
            imageView := collections.access(&rendererWindowState.swapchainImageViews.buffer, i)^
            vk.DestroyImageView(vk.Device(state.device.device), vk.ImageView(imageView), nil)
        }
        rendererWindowState.swapchainImageViews.buffer.count = 0
        vk.DestroySwapchainKHR(vk.Device(state.device.device), vk.SwapchainKHR(rendererWindowState.swapchain), nil)
        vk.DestroySurfaceKHR(instance, vk.SurfaceKHR(rendererWindowState.surface), nil)
    }

    // init new windows
    for i := u64(0); i < collections.getCount(&windowState.createdWindows.buffer); i += 1 {
        windowIdx := collections.access(&windowState.createdWindows.buffer, i)^
        windowState := collections.access(&windowState.windows.buffer, u64(windowIdx))

        windowPtr := windowState.ptr

        valid := false
        surface: vk.SurfaceKHR = ---
        surfaceFormat: vk.SurfaceFormatKHR = ---
        swapchain: vk.SwapchainKHR = ---
        width, height: u32 = ---, ---
        {     // create surface and swapchain
            valid = bool(sdl2.Vulkan_CreateSurface((^sdl2.Window)(windowPtr), instance, &surface))

            if valid {
                physicalDeviceState := collections.access(&state.physicalDevices.buffer, u64(state.selectedDeviceIdx))
                physicalDevice := vk.PhysicalDevice(physicalDeviceState.device)

                formatsCount := u32(0)
                checkResult(
                    vk.GetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, &formatsCount, nil),
                    "GetPhysicalDeviceSurfaceFormatsKHR",
                )
                formats := make([]vk.SurfaceFormatKHR, formatsCount)
                defer delete(formats)
                checkResult(
                    vk.GetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, &formatsCount, raw_data(formats)),
                    "GetPhysicalDeviceSurfaceFormatsKHR",
                )

                foundFormat := false
                for format in formats {
                    if format.format == .B8G8R8A8_SRGB && format.colorSpace == .SRGB_NONLINEAR {
                        surfaceFormat = format
                        foundFormat = true
                        break
                    }
                }
                valid &&= foundFormat

                presentModesCount := u32(0)
                checkResult(
                    vk.GetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, &presentModesCount, nil),
                    "GetPhysicalDeviceSurfacePresentModesKHR",
                )
                presentModes := make([]vk.PresentModeKHR, presentModesCount)
                defer delete(presentModes)
                checkResult(
                    vk.GetPhysicalDeviceSurfacePresentModesKHR(
                        physicalDevice,
                        surface,
                        &presentModesCount,
                        raw_data(presentModes),
                    ),
                    "GetPhysicalDeviceSurfacePresentModesKHR",
                )

                presentMode: vk.PresentModeKHR = .FIFO
                for mode in presentModes {
                    if mode == .MAILBOX {
                        presentMode = mode
                        break
                    }
                }

                surfaceCapabilities: vk.SurfaceCapabilitiesKHR = ---
                checkResult(
                    vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(physicalDevice, surface, &surfaceCapabilities),
                    "GetPhysicalDeviceSurfaceCapabilitiesKHR",
                )

                widthUnclamped, heightUnclamped := c.int(0), c.int(0)
                sdl2.Vulkan_GetDrawableSize((^sdl2.Window)(windowPtr), &widthUnclamped, &heightUnclamped)

                width = glm.clamp(
                    u32(widthUnclamped),
                    surfaceCapabilities.minImageExtent.width,
                    surfaceCapabilities.maxImageExtent.width,
                )
                height = glm.clamp(
                    u32(heightUnclamped),
                    surfaceCapabilities.minImageExtent.height,
                    surfaceCapabilities.maxImageExtent.height,
                )

                imageCount := surfaceCapabilities.minImageCount + 1
                if surfaceCapabilities.maxImageCount > 0 && imageCount > surfaceCapabilities.maxImageCount {
                    imageCount = surfaceCapabilities.maxImageCount
                }

                if valid {
                    queueFamilyIndices: [2]u32 = {state.device.graphicsQueueIdx, state.device.presentQueueIdx}
                    swapchainCreateInfo := vk.SwapchainCreateInfoKHR {
                        sType = .SWAPCHAIN_CREATE_INFO_KHR,
                        pNext = nil,
                        flags = {},
                        surface = surface,
                        minImageCount = imageCount,
                        imageFormat = surfaceFormat.format,
                        imageColorSpace = surfaceFormat.colorSpace,
                        imageExtent = vk.Extent2D{width = width, height = height},
                        imageArrayLayers = 1,
                        imageUsage = {.COLOR_ATTACHMENT},
                        preTransform = surfaceCapabilities.currentTransform,
                        compositeAlpha = {.OPAQUE},
                        presentMode = presentMode,
                        clipped = true,
                    }

                    if state.device.graphicsQueueIdx != state.device.presentQueueIdx {
                        swapchainCreateInfo.imageSharingMode = .CONCURRENT
                        swapchainCreateInfo.queueFamilyIndexCount = 2
                        swapchainCreateInfo.pQueueFamilyIndices = raw_data(&queueFamilyIndices)
                    } else {
                        swapchainCreateInfo.imageSharingMode = .EXCLUSIVE
                    }

                    checkResult(
                        vk.CreateSwapchainKHR(vk.Device(state.device.device), &swapchainCreateInfo, nil, &swapchain),
                        "CreateSwapchainKHR",
                    )
                }
            }
        }

        if !collections.tryAdd(
            &state.windows.buffer,
            WindowState{handle = windowState.handle, surface = u64(surface), swapchain = u64(swapchain)},
        ) {
            debug.log("VulkanRenderer", debug.LogLevel.ERROR, "Failed to add window state to buffer")
            break
        }

        idx := collections.getCount(&state.windows.buffer) - 1
        rendererWindowState := collections.access(&state.windows.buffer, idx)

        swapchainImageCount := u32(0)
        {     // swapchain image views
            vk.GetSwapchainImagesKHR(vk.Device(state.device.device), swapchain, &swapchainImageCount, nil)
            swapchainImages := make([]vk.Image, swapchainImageCount)
            defer delete(swapchainImages)
            vk.GetSwapchainImagesKHR(
                vk.Device(state.device.device),
                swapchain,
                &swapchainImageCount,
                raw_data(swapchainImages),
            )

            rendererWindowState.swapchainImageViews.buffer.count = u64(swapchainImageCount)
            for img, idx in swapchainImages {
                imageViewCreateInfo := vk.ImageViewCreateInfo {
                    sType = .IMAGE_VIEW_CREATE_INFO,
                    pNext = nil,
                    flags = {},
                    image = img,
                    viewType = .D2,
                    format = surfaceFormat.format,
                    components = vk.ComponentMapping{r = .IDENTITY, g = .IDENTITY, b = .IDENTITY, a = .IDENTITY},
                    subresourceRange = vk.ImageSubresourceRange {
                        aspectMask = {.COLOR},
                        baseMipLevel = 0,
                        levelCount = 1,
                        baseArrayLayer = 0,
                        layerCount = 1,
                    },
                }

                imageViewPtr := (^vk.ImageView)(collections.access(&rendererWindowState.swapchainImageViews.buffer, u64(idx)))
                checkResult(
                    vk.CreateImageView(vk.Device(state.device.device), &imageViewCreateInfo, nil, imageViewPtr),
                    "CreateImageView",
                )
            }
        }

        {     // depth image
            imageCreateInfo := vk.ImageCreateInfo {
                sType = .IMAGE_CREATE_INFO,
                pNext = nil,
                flags = {},
                imageType = .D2,
                format = .D32_SFLOAT_S8_UINT,
                extent = vk.Extent3D{width = width, height = height, depth = 1},
                mipLevels = 1,
                arrayLayers = 1,
                samples = {._1},
                tiling = .OPTIMAL,
                usage = {.DEPTH_STENCIL_ATTACHMENT},
                sharingMode = .EXCLUSIVE,
                queueFamilyIndexCount = 0,
                pQueueFamilyIndices = nil,
                initialLayout = .UNDEFINED,
            }

            depthImage: vk.Image = ---
            checkResult(vk.CreateImage(vk.Device(state.device.device), &imageCreateInfo, nil, &depthImage), "CreateImage")
            rendererWindowState.depthImage = u64(depthImage)

            memReq: vk.MemoryRequirements = ---
            vk.GetImageMemoryRequirements(vk.Device(state.device.device), depthImage, &memReq)

            physicalDevice := vk.PhysicalDevice(
                collections.access(&state.physicalDevices.buffer, u64(state.selectedDeviceIdx)).device,
            )
            memProps: vk.PhysicalDeviceMemoryProperties = ---
            vk.GetPhysicalDeviceMemoryProperties(physicalDevice, &memProps)

            memTypeIndex, memTypeIndexFound := u32(0), false
            for i := u32(0); i < memProps.memoryTypeCount; i += 1 {
                if memReq.memoryTypeBits & (1 << i) != 0 {
                    if .DEVICE_LOCAL in memProps.memoryTypes[i].propertyFlags {
                        memTypeIndex = i
                        memTypeIndexFound = true
                        break
                    }
                }
            }

            if !memTypeIndexFound {
                panic("Failed to find suitable memory type for depth image")
            }

            allocInfo := vk.MemoryAllocateInfo {
                sType           = .MEMORY_ALLOCATE_INFO,
                pNext           = nil,
                allocationSize  = memReq.size,
                memoryTypeIndex = memTypeIndex,
            }

            depthImageMemory: vk.DeviceMemory = ---
            checkResult(
                vk.AllocateMemory(vk.Device(state.device.device), &allocInfo, nil, &depthImageMemory),
                "AllocateMemory",
            )
            vk.BindImageMemory(vk.Device(state.device.device), depthImage, depthImageMemory, 0)

            imageViewCreateInfo := vk.ImageViewCreateInfo {
                sType = .IMAGE_VIEW_CREATE_INFO,
                pNext = nil,
                flags = {},
                image = depthImage,
                viewType = .D2,
                format = .D32_SFLOAT_S8_UINT,
                components = vk.ComponentMapping{r = .IDENTITY, g = .IDENTITY, b = .IDENTITY, a = .IDENTITY},
                subresourceRange = vk.ImageSubresourceRange {
                    aspectMask = {.DEPTH},
                    baseMipLevel = 0,
                    levelCount = 1,
                    baseArrayLayer = 0,
                    layerCount = 1,
                },
            }

            checkResult(
                vk.CreateImageView(
                    vk.Device(state.device.device),
                    &imageViewCreateInfo,
                    nil,
                    (^vk.ImageView)(&rendererWindowState.depthImageView),
                ),
                "CreateImageView",
            )
        }

        {     // render pass
            depthFormat: vk.Format
            depthFormats := [?]vk.Format{.D32_SFLOAT_S8_UINT, .D32_SFLOAT, .D24_UNORM_S8_UINT, .D16_UNORM_S8_UINT, .D16_UNORM}
            for format in depthFormats {
                formatProps: vk.FormatProperties = ---
                physicalDevice := vk.PhysicalDevice(
                    collections.access(&state.physicalDevices.buffer, u64(state.selectedDeviceIdx)).device,
                )
                vk.GetPhysicalDeviceFormatProperties(physicalDevice, format, &formatProps)
                if .DEPTH_STENCIL_ATTACHMENT in formatProps.optimalTilingFeatures {
                    depthFormat = format
                    break
                }
            }

            attachments := [?]vk.AttachmentDescription {
                {
                    format = surfaceFormat.format,
                    samples = {._1},
                    loadOp = .CLEAR,
                    storeOp = .STORE,
                    stencilLoadOp = .DONT_CARE,
                    stencilStoreOp = .DONT_CARE,
                    initialLayout = .UNDEFINED,
                    finalLayout = .PRESENT_SRC_KHR,
                },
                {
                    format = depthFormat,
                    samples = {._1},
                    loadOp = .CLEAR,
                    storeOp = .STORE,
                    stencilLoadOp = .CLEAR,
                    stencilStoreOp = .DONT_CARE,
                    initialLayout = .UNDEFINED,
                    finalLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                },
            }

            colorReference := vk.AttachmentReference {
                attachment = 0,
                layout     = .COLOR_ATTACHMENT_OPTIMAL,
            }

            depthReference := vk.AttachmentReference {
                attachment = 1,
                layout     = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
            }

            subpass := vk.SubpassDescription {
                flags                   = {},
                pipelineBindPoint       = .GRAPHICS,
                colorAttachmentCount    = 1,
                pColorAttachments       = &colorReference,
                pDepthStencilAttachment = &depthReference,
                inputAttachmentCount    = 0,
                pInputAttachments       = nil,
                preserveAttachmentCount = 0,
                pPreserveAttachments    = nil,
                pResolveAttachments     = nil,
            }

            subpassDependency := vk.SubpassDependency {
                srcSubpass      = vk.SUBPASS_EXTERNAL,
                dstSubpass      = 0,
                srcStageMask    = {.BOTTOM_OF_PIPE},
                dstStageMask    = {.COLOR_ATTACHMENT_OUTPUT},
                srcAccessMask   = {.MEMORY_READ},
                dstAccessMask   = {.COLOR_ATTACHMENT_READ, .COLOR_ATTACHMENT_WRITE},
                dependencyFlags = {.BY_REGION},
            }

            renderPassCreateInfo := vk.RenderPassCreateInfo {
                sType           = .RENDER_PASS_CREATE_INFO,
                pNext           = nil,
                attachmentCount = len(attachments),
                pAttachments    = raw_data(&attachments),
                subpassCount    = 1,
                pSubpasses      = &subpass,
                dependencyCount = 1,
                pDependencies   = &subpassDependency,
            }

            checkResult(
                vk.CreateRenderPass(
                    vk.Device(state.device.device),
                    &renderPassCreateInfo,
                    nil,
                    (^vk.RenderPass)(&rendererWindowState.renderPass),
                ),
                "CreateRenderPass",
            )
        }

        {     // swapchain frame buffers
            rendererWindowState.framebuffers.buffer.count = u64(swapchainImageCount)
            for i := u64(0); i < u64(swapchainImageCount); i += 1 {
                imageView := collections.access(&rendererWindowState.swapchainImageViews.buffer, i)^
                attachments := [?]vk.ImageView{vk.ImageView(imageView), vk.ImageView(rendererWindowState.depthImageView)}
                framebufferCreateInfo := vk.FramebufferCreateInfo {
                    sType           = .FRAMEBUFFER_CREATE_INFO,
                    pNext           = nil,
                    flags           = {},
                    renderPass      = vk.RenderPass(rendererWindowState.renderPass),
                    attachmentCount = len(attachments),
                    pAttachments    = raw_data(&attachments),
                    width           = width,
                    height          = height,
                    layers          = 1,
                }

                framebufferPtr := (^vk.Framebuffer)(collections.access(&rendererWindowState.framebuffers.buffer, i))
                checkResult(
                    vk.CreateFramebuffer(vk.Device(state.device.device), &framebufferCreateInfo, nil, framebufferPtr),
                    "CreateFramebuffer",
                )
            }
        }

    }
}
