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
        16,
        16,
        sdl2.WINDOW_VULKAN | sdl2.WINDOW_ALLOW_HIGHDPI | sdl2.WINDOW_MINIMIZED,
    )
    defer sdl2.DestroyWindow(tempWindow)

    instance: vk.Instance = ---
    {
        extensionsCount := u32(0)
        sdl2.Vulkan_GetInstanceExtensions((^sdl2.Window)(tempWindow), &extensionsCount, nil)
        extensions := make([]cstring, extensionsCount + 5) // for good measure
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

        when ODIN_DEBUG {
            debugLayers := []cstring{"VK_LAYER_KHRONOS_validation"}
            instanceInfo.enabledLayerCount = u32(len(debugLayers))
            instanceInfo.ppEnabledLayerNames = raw_data(debugLayers)
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

        commandPoolCreateInfo := vk.CommandPoolCreateInfo {
            sType            = .COMMAND_POOL_CREATE_INFO,
            pNext            = nil,
            flags            = {.RESET_COMMAND_BUFFER, .TRANSIENT},
            queueFamilyIndex = state.device.graphicsQueueIdx,
        }

        state.device = Device {
            device           = rawptr(device),
            graphicsQueue    = rawptr(graphicsQueue),
            graphicsQueueIdx = u32(graphicsIndex),
            presentQueue     = rawptr(presentQueue),
            presentQueueIdx  = u32(presentIndex),
        }

        commandPool: vk.CommandPool = ---
        checkResult(
            vk.CreateCommandPool(vk.Device(state.device.device), &commandPoolCreateInfo, nil, &commandPool),
            "CreateCommandPool",
        )
        state.commandPool = u64(commandPool)
    }

    {     // shaders
        state.shaders.triangle = compileShader(vk.Device(state.device.device), "triangle")
    }

    return state
}

destroySubsystem :: proc(state: ^SubsystemState) {
    clearShader(vk.Device(state.device.device), &state.shaders.triangle)

    vk.DestroyCommandPool(vk.Device(state.device.device), vk.CommandPool(state.commandPool), nil)
    state.commandPool = 0

    vk.DestroyDevice(vk.Device(state.device.device), nil)
    state.device = Device{}

    collections.clear(&state.physicalDevices.buffer)
    state.physicalDevices = PhysicalDeviceBuffer{}

    vk.DestroyInstance(vk.Instance(state.instance), nil)
    state.instance = nil
}

updateSubsystem :: proc(windowState: ^window.SubsystemState, state: ^SubsystemState) {
    shutdownWindowsToBeClosed(windowState, state)
    initializeNewWindows(windowState, state)
    processResizedWindows(windowState, state)

    for i := u64(0); i < state.windows.buffer.count; i += 1 {
        rendererWindowState := collections.access(&state.windows.buffer, i)

        vk.AcquireNextImageKHR(
            vk.Device(state.device.device),
            vk.SwapchainKHR(rendererWindowState.swapchain),
            c.UINT64_MAX,
            vk.Semaphore(rendererWindowState.imageAvailableSemaphore),
            vk.Fence(0),
            &rendererWindowState.frameIdx,
        )

        fence := (^vk.Fence)(
            collections.access(&rendererWindowState.swapchainFences.buffer, u64(rendererWindowState.frameIdx)),
        )
        vk.WaitForFences(vk.Device(state.device.device), 1, fence, false, c.UINT64_MAX)
        vk.ResetFences(vk.Device(state.device.device), 1, fence)

        cmdBuff := (^vk.CommandBuffer)(
            collections.access(&rendererWindowState.commandBuffers.buffer, u64(rendererWindowState.frameIdx)),
        )
        image := (^vk.ImageView)(
            collections.access(&rendererWindowState.swapchainImageViews.buffer, u64(rendererWindowState.frameIdx)),
        )
        frameBuff := (^vk.Framebuffer)(
            collections.access(&rendererWindowState.framebuffers.buffer, u64(rendererWindowState.frameIdx)),
        )

        vk.ResetCommandBuffer(cmdBuff^, {})

        cmdBuffBeginInfo := vk.CommandBufferBeginInfo {
            sType            = .COMMAND_BUFFER_BEGIN_INFO,
            pNext            = nil,
            flags            = {.SIMULTANEOUS_USE},
            pInheritanceInfo = nil,
        }
        vk.BeginCommandBuffer(cmdBuff^, &cmdBuffBeginInfo)
        {
            clearValues := [?]vk.ClearValue {
                {color = {float32 = {0.0, 0.0, 0.0, 1.0}}},
                {depthStencil = {depth = 1.0, stencil = 0}},
            }
            renderPassBeginInfo := vk.RenderPassBeginInfo {
                sType = .RENDER_PASS_BEGIN_INFO,
                pNext = nil,
                renderPass = vk.RenderPass(rendererWindowState.renderPass),
                framebuffer = frameBuff^,
                renderArea = {
                    offset = {x = 0, y = 0},
                    extent = {width = rendererWindowState.width, height = rendererWindowState.height},
                },
                clearValueCount = len(clearValues),
                pClearValues = raw_data(&clearValues),
            }

            vk.CmdBeginRenderPass(cmdBuff^, &renderPassBeginInfo, .INLINE)
            {
                // TODO: more rendering?
            }
            vk.CmdEndRenderPass(cmdBuff^)
        }
        vk.EndCommandBuffer(cmdBuff^)

        submitInfo := vk.SubmitInfo {
            sType                = .SUBMIT_INFO,
            pNext                = nil,
            waitSemaphoreCount   = 1,
            pWaitSemaphores      = (^vk.Semaphore)(&rendererWindowState.imageAvailableSemaphore),
            pWaitDstStageMask    = &vk.PipelineStageFlags{.TRANSFER},
            commandBufferCount   = 1,
            pCommandBuffers      = cmdBuff,
            signalSemaphoreCount = 1,
            pSignalSemaphores    = (^vk.Semaphore)(&rendererWindowState.renderFinishedSemaphore),
        }

        vk.QueueSubmit(vk.Queue(state.device.graphicsQueue), 1, &submitInfo, fence^)

        presentInfo := vk.PresentInfoKHR {
            sType              = .PRESENT_INFO_KHR,
            pNext              = nil,
            waitSemaphoreCount = 1,
            pWaitSemaphores    = (^vk.Semaphore)(&rendererWindowState.renderFinishedSemaphore),
            swapchainCount     = 1,
            pSwapchains        = (^vk.SwapchainKHR)(&rendererWindowState.swapchain),
            pImageIndices      = &rendererWindowState.frameIdx,
            pResults           = nil,
        }

        vk.QueuePresentKHR(vk.Queue(state.device.presentQueue), &presentInfo)
        vk.QueueWaitIdle(vk.Queue(state.device.presentQueue))
    }
}
