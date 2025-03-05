SDL_Vulkan_GetInstanceExtensions :: (window: *SDL_Window, pCount: *u32, pNames: **u8) -> s32 #foreign SDL2;
SDL_Vulkan_CreateSurface :: (window: *SDL_Window, instance: VkInstance, surface: *VkSurfaceKHR) -> s32 #foreign SDL2;
SDL_Vulkan_GetDrawableSize :: (window: *SDL_Window, w: *s32, h: *s32) -> void #foreign SDL2;

shutdownWindowsToBeClosed :: (windowState2: *window.SubsystemState, state: *SubsystemState) {
    instance: VkInstance = state.instance;
    for i : 0..(windowState2.windowsToBeClosed.num - 1) {
        windowIdx := << (access(*windowState2.windowsToBeClosed, i));
        windowState := access(*windowState2.windows, windowIdx);

        rendererWindowStatePtr, rwsIdx := search(*state.windows, *windowState.handle, (ws, h) => ws.handle == (<< h));

        if !rendererWindowStatePtr {
            // window was never initialised for renderer successfully
            continue;
        }

        rendererWindowState := << rendererWindowStatePtr;
        tryEraseSwapBack(*state.windows, rwsIdx);

        vkDestroySemaphore(state.device.device, rendererWindowState.renderFinishedSemaphore, null);
        vkDestroySemaphore(state.device.device, rendererWindowState.imageAvailableSemaphore, null);
        vkFreeCommandBuffers(
            state.device.device,
            state.commandPool,
            xx rendererWindowState.commandBuffers.num,
            *rendererWindowState.commandBuffers.buffer[0],
        );
        for i: 0..(rendererWindowState.framebuffers.num - 1) {
            framebuffer := << access(*rendererWindowState.framebuffers, i);
            vkDestroyFramebuffer(state.device.device, framebuffer, null);
        }
        rendererWindowState.framebuffers = .{};
        vkDestroyRenderPass(state.device.device, rendererWindowState.renderPass, null);
        vkDestroyImageView(state.device.device, rendererWindowState.depthImageView, null);
        vkDestroyImage(state.device.device, rendererWindowState.depthImage, null);
        vkFreeMemory(state.device.device, rendererWindowState.depthImageMemory, null);
        for i: 0..(rendererWindowState.swapchainFences.num - 1) {
            fence := << access(*rendererWindowState.swapchainFences, i);
            vkDestroyFence(state.device.device, fence, null);
        }
        rendererWindowState.swapchainFences = .{};
        for i: 0..(rendererWindowState.swapchainImageViews.num - 1) {
            imageView := << access(*rendererWindowState.swapchainImageViews, i);
            vkDestroyImageView(state.device.device, imageView, null);
        }
        rendererWindowState.swapchainImageViews = .{};
        vkDestroySwapchainKHR(state.device.device, rendererWindowState.swapchain, null);
        vkDestroySurfaceKHR(state.instance, rendererWindowState.surface, null);
    }
}

initializeNewWindows :: (windowState2: *window.SubsystemState, state: *SubsystemState) {
    instance: VkInstance = state.instance;

    for i: 0..(windowState2.createdWindows.num - 1) {
        windowIdx := << access(*windowState2.createdWindows, i);
        windowState := access(*windowState2.windows, windowIdx);

        windowPtr := windowState.ptr;

        valid := false;
        surface: VkSurfaceKHR = ---;
        surfaceFormat: VkSurfaceFormatKHR = ---;
        swapChain: VkSwapchainKHR = ---;
        width: u32 = ---;
        height: u32 = ---;

        { // create surface and swapchain
            valid = cast(bool) SDL_Vulkan_CreateSurface(windowPtr, instance, *surface);

            if valid {
                physicalDeviceState := access(*state.physicalDevices, state.selectedDeviceIdx);
                physicalDevice := physicalDeviceState.device;

                formatsCount: u32;
                checkResult(vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, *formatsCount, null), "vkGetPhysicalDeviceSurfaceFormatsKHR");
                formats := NewArray(formatsCount, VkSurfaceFormatKHR,, temp);
                checkResult(vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, *formatsCount, formats.data), "vkGetPhysicalDeviceSurfaceFormatsKHR");

                foundFormat := false;
                for format: formats {
                    if format.format == .B8G8R8A8_SRGB && format.colorSpace == .COLOR_SPACE_SRGB_NONLINEAR_KHR {
                        surfaceFormat = format;
                        foundFormat = true;
                        break;
                    }
                }
                valid &&= foundFormat;

                presentModesCount: u32;
                checkResult(vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, *presentModesCount, null), "vkGetPhysicalDeviceSurfacePresentModesKHR");
                presentModes := NewArray(presentModesCount, VkPresentModeKHR,, temp);
                checkResult(vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, *presentModesCount, presentModes.data), "vkGetPhysicalDeviceSurfacePresentModesKHR");

                presentMode: VkPresentModeKHR = .FIFO_KHR;
                for mode: presentModes {
                    if mode == .MAILBOX_KHR {
                        presentMode = mode;
                        break;
                    }
                }

                surfaceCapabilities: VkSurfaceCapabilitiesKHR = ---;
                checkResult(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physicalDevice, surface, *surfaceCapabilities), "vkGetPhysicalDeviceSurfaceCapabilitiesKHR");

                widthUnclamped, heightUnclamped: s32;
                SDL_Vulkan_GetDrawableSize(windowPtr, *widthUnclamped, *heightUnclamped);

                width = clamp(
                    cast(u32) widthUnclamped,
                    surfaceCapabilities.minImageExtent.width,
                    surfaceCapabilities.maxImageExtent.width
                );
                height = clamp(
                    cast(u32) heightUnclamped,
                    surfaceCapabilities.minImageExtent.height,
                    surfaceCapabilities.maxImageExtent.height
                );

                imageCount := surfaceCapabilities.minImageCount + 1;
                if surfaceCapabilities.maxImageCount > 0 && imageCount > surfaceCapabilities.maxImageCount {
                    imageCount = surfaceCapabilities.maxImageCount;
                }

                if valid {
                    queueFamilyIndices := u32.[state.device.graphicsQueueIdx, state.device.presentQueueIdx];
                    swapchainCreateInfo := VkSwapchainCreateInfoKHR.{
                        sType = .SWAPCHAIN_CREATE_INFO_KHR,
                        pNext = null,
                        flags = 0,
                        surface = surface,
                        minImageCount = imageCount,
                        imageFormat = surfaceFormat.format,
                        imageColorSpace = surfaceFormat.colorSpace,
                        imageExtent = .{width = width, height = height},
                        imageArrayLayers = 1,
                        imageUsage = .COLOR_ATTACHMENT_BIT,
                        preTransform = surfaceCapabilities.currentTransform,
                        compositeAlpha = .OPAQUE_BIT_KHR,
                        presentMode = presentMode,
                        clipped = xx true,
                    };

                    if state.device.graphicsQueueIdx != state.device.presentQueueIdx {
                        swapchainCreateInfo.imageSharingMode = .CONCURRENT;
                        swapchainCreateInfo.queueFamilyIndexCount = 2;
                        swapchainCreateInfo.pQueueFamilyIndices = queueFamilyIndices.data;
                    } else {
                        swapchainCreateInfo.imageSharingMode = .EXCLUSIVE;
                        swapchainCreateInfo.queueFamilyIndexCount = 0;
                        swapchainCreateInfo.pQueueFamilyIndices = null;
                    }

                    checkResult(
                        vkCreateSwapchainKHR(state.device.device, *swapchainCreateInfo, null, *swapChain),
                        "vkCreateSwapchainKHR"
                    );
                }
            }
        }

        if !tryAdd(
            *state.windows,
            VulkanWindowState.{
                handle = windowState.handle,
                surface = surface,
                swapchain = swapChain,
                width = width,
                height = height,
            }
        ) {
            dbg.logError("VulkanRenderer", "Failed to add window state to buffer");
            break;
        }

        idx := state.windows.num - 1;
        rendererWindowState := access(*state.windows, idx);

        swapchainImageCount: u32;
        { // swapchain image views & their fences
            vkGetSwapchainImagesKHR(state.device.device, swapChain, *swapchainImageCount, null);
            swapchainImages := NewArray(swapchainImageCount, VkImage,, temp);
            vkGetSwapchainImagesKHR(state.device.device, swapChain, *swapchainImageCount, swapchainImages.data);

            rendererWindowState.swapchainImageViews.num = swapchainImageCount;
            for img, idx: swapchainImages {
                imageViewCreateInfo := VkImageViewCreateInfo.{
                    sType = .IMAGE_VIEW_CREATE_INFO,
                    pNext = null,
                    flags = 0,
                    image = img,
                    viewType = ._2D,
                    format = surfaceFormat.format,
                    components = .{
                        r = .IDENTITY,
                        g = .IDENTITY,
                        b = .IDENTITY,
                        a = .IDENTITY
                    },
                    subresourceRange = .{
                        aspectMask = .COLOR_BIT,
                        baseMipLevel = 0,
                        levelCount = 1,
                        baseArrayLayer = 0,
                        layerCount = 1,
                    }
                };

                imageViewPtr := access(*rendererWindowState.swapchainImageViews, idx);
                checkResult(
                    vkCreateImageView(state.device.device, *imageViewCreateInfo, null, imageViewPtr),
                    "vkCreateImageView"
                );
            }

            rendererWindowState.swapchainFences.num = swapchainImageCount;
            for i: 0..swapchainImageCount-1 {
                fenceCreateInfo := VkFenceCreateInfo.{
                    sType = .FENCE_CREATE_INFO,
                    pNext = null,
                    flags = .SIGNALED_BIT
                };
                checkResult(
                    vkCreateFence(
                        state.device.device,
                        *fenceCreateInfo,
                        null,
                        access(*rendererWindowState.swapchainFences, i)
                    ),
                    "vkCreateFence"
                );
            }
        }

        { // depth image
            imageCreateInfo := VkImageCreateInfo.{
                sType = .IMAGE_CREATE_INFO,
                pNext = null,
                flags = 0,
                imageType = ._2D,
                format = .D32_SFLOAT_S8_UINT,
                extent = .{
                    width = width,
                    height = height,
                    depth = 1
                },
                mipLevels = 1,
                arrayLayers = 1,
                samples = ._1_BIT,
                tiling = .OPTIMAL,
                usage = .DEPTH_STENCIL_ATTACHMENT_BIT,
                sharingMode = .EXCLUSIVE,
                queueFamilyIndexCount = 0,
                pQueueFamilyIndices = null,
                initialLayout = .UNDEFINED
            };

            checkResult(
                vkCreateImage(state.device.device, *imageCreateInfo, null, *rendererWindowState.depthImage),
                "vkCreateImage"
            );

            memReq: VkMemoryRequirements = ---;
            vkGetImageMemoryRequirements(state.device.device, rendererWindowState.depthImage, *memReq);

            physicalDevice := access(*state.physicalDevices, state.selectedDeviceIdx).device;
            memProps: VkPhysicalDeviceMemoryProperties = ---;
            vkGetPhysicalDeviceMemoryProperties(physicalDevice, *memProps);

            memTypeIndex: u32 = 0;
            memTypeIndexFound := false;
            for i: 0..memProps.memoryTypeCount-1 {
                if (memReq.memoryTypeBits & (1 << i)) &&
                    (memProps.memoryTypes[i].propertyFlags & .DEVICE_LOCAL_BIT) {
                    memTypeIndex = i;
                    memTypeIndexFound = true;
                    break;
                }
            }

            if !memTypeIndexFound {
                assert(false, "Failed to find suitable memory type for depth image.");
            }

            allocInfo := VkMemoryAllocateInfo.{
                sType = .MEMORY_ALLOCATE_INFO,
                pNext = null,
                allocationSize = memReq.size,
                memoryTypeIndex = memTypeIndex
            };

            checkResult(
                vkAllocateMemory(state.device.device, *allocInfo, null, *rendererWindowState.depthImageMemory),
                "vkAllocateMemory"
            );

            vkBindImageMemory(state.device.device, rendererWindowState.depthImage, rendererWindowState.depthImageMemory, 0);

            imageViewCreateInfo := VkImageViewCreateInfo.{
                sType = .IMAGE_VIEW_CREATE_INFO,
                pNext = null,
                flags = 0,
                image = rendererWindowState.depthImage,
                viewType = ._2D,
                format = .D32_SFLOAT_S8_UINT,
                components = .{
                    r = .IDENTITY,
                    g = .IDENTITY,
                    b = .IDENTITY,
                    a = .IDENTITY
                },
                subresourceRange = .{
                    aspectMask = .DEPTH_BIT,
                    baseMipLevel = 0,
                    levelCount = 1,
                    baseArrayLayer = 0,
                    layerCount = 1
                }
            };

            checkResult(
                vkCreateImageView(state.device.device, *imageViewCreateInfo, null, *rendererWindowState.depthImageView),
                "vkCreateImageView"
            );
        }

        { // render pass
            depthFormat: VkFormat;
            depthFormats := VkFormat.[.D32_SFLOAT_S8_UINT, .D32_SFLOAT, .D24_UNORM_S8_UINT, .D16_UNORM_S8_UINT, .D16_UNORM];
            for format: depthFormats {
                formatProps: VkFormatProperties = ---;
                physicalDevice := state.physicalDevices.buffer[state.selectedDeviceIdx].device;
                vkGetPhysicalDeviceFormatProperties(physicalDevice, format, *formatProps);
                if formatProps.optimalTilingFeatures & .DEPTH_STENCIL_ATTACHMENT_BIT {
                    depthFormat = format;
                    break;
                }
            }

            attachmentDescriptions := VkAttachmentDescription.[
                .{ // Color attachment
                    flags = 0,
                    format = surfaceFormat.format,
                    samples = ._1_BIT,
                    loadOp = .CLEAR,
                    storeOp = .STORE,
                    stencilLoadOp = .DONT_CARE,
                    stencilStoreOp = .DONT_CARE,
                    initialLayout = .UNDEFINED,
                    finalLayout = .PRESENT_SRC_KHR
                },
                .{ // Depth attachment
                    flags = 0,
                    format = depthFormat,
                    samples = ._1_BIT,
                    loadOp = .CLEAR,
                    storeOp = .STORE,
                    stencilLoadOp = .CLEAR,
                    stencilStoreOp = .DONT_CARE,
                    initialLayout = .UNDEFINED,
                    finalLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL
                }
            ];

            colorAttachmentRef := VkAttachmentReference.{
                attachment = 0,
                layout = .COLOR_ATTACHMENT_OPTIMAL
            };

            depthAttachmentRef := VkAttachmentReference.{
                attachment = 1,
                layout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL
            };

            subpass := VkSubpassDescription.{
                flags = 0,
                pipelineBindPoint = .GRAPHICS,
                inputAttachmentCount = 0,
                pInputAttachments = null,
                colorAttachmentCount = 1,
                pColorAttachments = *colorAttachmentRef,
                pResolveAttachments = null,
                pDepthStencilAttachment = *depthAttachmentRef,
                preserveAttachmentCount = 0,
                pPreserveAttachments = null
            };

            dependency := VkSubpassDependency.{
                srcSubpass = VK_SUBPASS_EXTERNAL,
                dstSubpass = 0,
                srcStageMask = .BOTTOM_OF_PIPE_BIT,
                dstStageMask = .COLOR_ATTACHMENT_OUTPUT_BIT,
                srcAccessMask = .MEMORY_READ_BIT,
                dstAccessMask = .COLOR_ATTACHMENT_READ_BIT | .COLOR_ATTACHMENT_WRITE_BIT,
                dependencyFlags = .BY_REGION_BIT
            };

            renderPassInfo := VkRenderPassCreateInfo.{
                sType = .RENDER_PASS_CREATE_INFO,
                pNext = null,
                flags = 0,
                attachmentCount = attachmentDescriptions.count,
                pAttachments = attachmentDescriptions.data,
                subpassCount = 1,
                pSubpasses = *subpass,
                dependencyCount = 1,
                pDependencies = *dependency
            };

            checkResult(
                vkCreateRenderPass(state.device.device, *renderPassInfo, null, *rendererWindowState.renderPass),
                "vkCreateRenderPass"
            );
        }

        { // swapchain frame buffers
            rendererWindowState.framebuffers.num = swapchainImageCount;
            for i: 0..swapchainImageCount-1 {
                attachments := VkImageView.[
                    rendererWindowState.swapchainImageViews.buffer[i],
                    rendererWindowState.depthImageView
                ];

                framebufferCreateInfo := VkFramebufferCreateInfo.{
                    sType = .FRAMEBUFFER_CREATE_INFO,
                    pNext = null,
                    flags = 0,
                    renderPass = rendererWindowState.renderPass,
                    attachmentCount = attachments.count,
                    pAttachments = attachments.data,
                    width = width,
                    height = height,
                    layers = 1
                };

                checkResult(
                    vkCreateFramebuffer(
                        state.device.device,
                        *framebufferCreateInfo,
                        null,
                        access(*rendererWindowState.framebuffers, i)
                    ),
                    "vkCreateFramebuffer"
                );
            }
        }

        { // per swapchain image command buffers
            rendererWindowState.commandBuffers.num = swapchainImageCount;
            allocInfo := VkCommandBufferAllocateInfo.{
                sType = .COMMAND_BUFFER_ALLOCATE_INFO,
                pNext = null,
                commandPool = state.commandPool,
                level = .PRIMARY,
                commandBufferCount = swapchainImageCount
            };

            checkResult(
                vkAllocateCommandBuffers(
                    state.device.device,
                    *allocInfo,
                    *rendererWindowState.commandBuffers.buffer[0]
                ),
                "vkAllocateCommandBuffers"
            );
        }

        { // semaphores
            semaphoreCreateInfo := VkSemaphoreCreateInfo.{
                sType = .SEMAPHORE_CREATE_INFO,
                pNext = null,
                flags = 0
            };

            checkResult(
                vkCreateSemaphore(state.device.device, *semaphoreCreateInfo, null, *rendererWindowState.imageAvailableSemaphore),
                "vkCreateSemaphore"
            );
            checkResult(
                vkCreateSemaphore(state.device.device, *semaphoreCreateInfo, null, *rendererWindowState.renderFinishedSemaphore),
                "vkCreateSemaphore"
            );
        }
    }
}

processResizedWindows :: (windowState: *window.SubsystemState, state: *SubsystemState) {
}

#scope_file
#import,file "state.jai";
#import,file "errors.jai";
#import "Basic";
#import "collections";
dbg :: #import "debug";
#import "SDL";
#import "Vulkan";
window :: #import "window";
