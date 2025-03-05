createSubsystem :: () -> SubsystemState {
    state: SubsystemState;

    tempWindow := SDL_CreateWindow(
        "temp window to get instance extensions",
        0,
        0,
        16,
        16,
        .SDL_WINDOW_VULKAN | .SDL_WINDOW_ALLOW_HIGHDPI | .SDL_WINDOW_MINIMIZED,
    );
    defer SDL_DestroyWindow(tempWindow);

    #if RHI_VK_DEBUG {
        layerCount: u32;
        vkEnumerateInstanceLayerProperties(*layerCount, null);
        layersArray := NewArray(layerCount, VkLayerProperties,, allocator = temp);
        vkEnumerateInstanceLayerProperties(*layerCount, layersArray.data);
        dbg.log("VulkanRenderer", "Vulkan layers:");
        for layer: layersArray {
            dbg.log("VulkanRenderer", "  % (%)", to_string(layer.layerName.data), layer.specVersion);
        }

        extensionCount: u32;
        vkEnumerateInstanceExtensionProperties(null, *extensionCount, null);
        extensionsArray := NewArray(extensionCount, VkExtensionProperties,, allocator = temp);
        vkEnumerateInstanceExtensionProperties(null, *extensionCount, extensionsArray.data);
        dbg.log("VulkanRenderer", "Vulkan extensions:");
        for ext: extensionsArray {
            dbg.log("VulkanRenderer", "  % (%)", to_string(ext.extensionName.data), ext.specVersion);
        }
    }

    instance: VkInstance = ---;
    {
        extensionsCount: u32 = 0;
        SDL_Vulkan_GetInstanceExtensions(tempWindow, *extensionsCount, null);
        extensions: []*u8 = NewArray(extensionsCount + (1 * xx RHI_VK_DEBUG), *u8,, allocator = temp);
        SDL_Vulkan_GetInstanceExtensions(tempWindow, *extensionsCount, extensions.data);
        #if RHI_VK_DEBUG {
            extensions[extensionsCount] = VK_EXT_DEBUG_UTILS_EXTENSION_NAME;
            extensionsCount += 1;
        }

        dbg.log("VulkanRenderer", "Required Vulkan extensions:");
        for ext: extensions {
            dbg.log("VulkanRenderer", "  %", to_string(ext));
        }

        appInfo: VkApplicationInfo = .{
            sType = .APPLICATION_INFO,
            pNext = null,
            pApplicationName = "RenderPractice",
            applicationVersion = VK_MAKE_VERSION(1, 0, 0),
            pEngineName = "No Engine",
            engineVersion = VK_MAKE_VERSION(1, 0, 0),
            apiVersion = VK_API_VERSION_1_0,
        };

        instanceInfo: VkInstanceCreateInfo = .{
            sType = .INSTANCE_CREATE_INFO,
            pNext = null,
            flags = 0,
            pApplicationInfo = *appInfo,
            enabledLayerCount = 0,
            ppEnabledLayerNames = null,
            enabledExtensionCount = extensionsCount,
            ppEnabledExtensionNames = extensions.data,
        };

        debugLayers := *u8.["VK_LAYER_KHRONOS_validation"];
        #if RHI_VK_DEBUG {
            instanceInfo.enabledLayerCount = debugLayers.count;
            instanceInfo.ppEnabledLayerNames = debugLayers.data;
        }

        checkResult(vkCreateInstance(*instanceInfo, null, *instance), "vkCreateInstance");
        state.instance = instance;

        #if RHI_VK_DEBUG {
            cbHandle: VkDebugUtilsMessengerEXT = ---;

            vkCreateDebugUtilsMessengerEXT: PFN_vkCreateDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");

            if vkCreateDebugUtilsMessengerEXT {
                DbgCallback :: (
                    messageSeverity: VkDebugUtilsMessageSeverityFlagBitsEXT,
                    messageType: VkDebugUtilsMessageTypeFlagsEXT,
                    pCallbackData: *VkDebugUtilsMessengerCallbackDataEXT,
                    pUserData: *void
                ) -> VkBool32 #c_call {
                    push_context {
                        if messageSeverity >= .ERROR_BIT_EXT {
                            dbg.log("VulkanRenderer", .ERROR, "VULKAN VALIDATION: %", to_string(pCallbackData.pMessage));
                        } else if messageSeverity >= .WARNING_BIT_EXT {
                            dbg.log("VulkanRenderer", .WARNING, "VULKAN VALIDATION: %", to_string(pCallbackData.pMessage));
                        } else {
                            // dbg.log("VulkanRenderer", "VULKAN VALIDATION: %", to_string(pCallbackData.pMessage));
                            // disabled for now
                        }
                    }

                    return xx false;
                }

                dbgCbCrInf := VkDebugUtilsMessengerCreateInfoEXT.{
                    sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
                    pNext = null,
                    flags = 0,
                    messageSeverity = .VERBOSE_BIT_EXT | .WARNING_BIT_EXT | .ERROR_BIT_EXT,
                    messageType = .GENERAL_BIT_EXT | .VALIDATION_BIT_EXT | .PERFORMANCE_BIT_EXT,
                    pfnUserCallback = DbgCallback,
                    pUserData = null,
                };

                checkResult(vkCreateDebugUtilsMessengerEXT(instance, *dbgCbCrInf, null, *cbHandle), "vkCreateDebugReportCallbackEXT");
                state.debugCallback = cbHandle;
            } else {
                state.debugCallback = null;
                dbg.log("VulkanRenderer", .ERROR, "Failed to get debug report creation function.");
            }
        } else {
            state.debugCallback = null;
        }
    }

    windowSurface: VkSurfaceKHR = ---;
    if !SDL_Vulkan_CreateSurface(tempWindow, instance, *windowSurface) {
        assert(false, "Failed to create Vulkan surface.");
    }
    defer vkDestroySurfaceKHR(instance, windowSurface, null);

    // pick device
    {
        physicalDeviceCount: u32 = 0;
        checkResult(vkEnumeratePhysicalDevices(instance, *physicalDeviceCount, null), "vkEnumeratePhysicalDevices");
        physicalDevices := NewArray(physicalDeviceCount, VkPhysicalDevice,, allocator = temp);
        checkResult(vkEnumeratePhysicalDevices(instance, *physicalDeviceCount, physicalDevices.data), "vkEnumeratePhysicalDevices");

        for dev : physicalDevices {
            properties: VkPhysicalDeviceProperties = ---;
            vkGetPhysicalDeviceProperties(dev, *properties);

            dbg.log("VulkanRenderer", "Device: %", to_string(properties.deviceName.data));

            if properties.deviceType != .DISCRETE_GPU {
                continue;
            }

            features: VkPhysicalDeviceFeatures = ---;
            vkGetPhysicalDeviceFeatures(dev, *features);

            if !features.geometryShader {
                continue;
            }

            physicalDevice := VulkanPhysicalDevice.{
                device = dev,
            };

            if !tryAdd(*state.physicalDevices, physicalDevice) {
                dbg.logError("VulkanRenderer", "Failed to add physical device to list.");
                break;
            }
        }

        if state.physicalDevices.num == 0 {
            assert(false, "No suitable Vulkan physical devices found.");
        }

        state.selectedDeviceIdx = 0;
    }

    // pick queues
    graphicsIndex, presentIndex := -1, -1;
    {
        physicalDevice := access(*state.physicalDevices, state.selectedDeviceIdx).device;

        queueFamilyCount: u32 = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, *queueFamilyCount, null);
        queueFamilies := NewArray(queueFamilyCount, VkQueueFamilyProperties,, allocator = temp);
        vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, *queueFamilyCount, queueFamilies.data);

        for queueFamily, i : queueFamilies {
            if queueFamily.queueCount > 0 && (queueFamily.queueFlags & .GRAPHICS_BIT) != 0 {
                graphicsIndex = i;
            }

            surfaceSupported: VkBool32 = xx false;
            checkResult(
                vkGetPhysicalDeviceSurfaceSupportKHR(physicalDevice, xx i, windowSurface, *surfaceSupported),
                "vkGetPhysicalDeviceSurfaceSupportKHR"
            );

            if queueFamily.queueCount > 0 && surfaceSupported {
                presentIndex = i;
            }

            if graphicsIndex != -1 && presentIndex != -1 {
                break;
            }
        }

        {
            physicalDevice: VkPhysicalDevice = access(*state.physicalDevices, state.selectedDeviceIdx).device;

            #if RHI_VK_DEBUG {
                enabledLayers: []*u8 = .["VK_LAYER_KHRONOS_validation"];
            } else {
                enabledLayers: []*u8 = .[];
            }
            extensions: []*u8 = .[VK_KHR_SWAPCHAIN_EXTENSION_NAME];
            queuePriority: []float = .[1];
            uniqueQueueIndices: FixedSizeBuffer(u32, 2);
            if graphicsIndex == presentIndex {
                uniqueQueueIndices.num = 1;
                uniqueQueueIndices.buffer[0] = xx graphicsIndex;
            } else {
                uniqueQueueIndices.num = 2;
                uniqueQueueIndices.buffer[0] = xx graphicsIndex;
                uniqueQueueIndices.buffer[1] = xx presentIndex;
            }

            queueCreateInfos: FixedSizeBuffer(VkDeviceQueueCreateInfo, 2);
            for i : 0..(uniqueQueueIndices.num - 1) {
                if !tryAdd(
                    *queueCreateInfos,
                    VkDeviceQueueCreateInfo.{
                        sType = .DEVICE_QUEUE_CREATE_INFO,
                        pNext = null,
                        flags = 0,
                        queueFamilyIndex = uniqueQueueIndices.buffer[i],
                        queueCount = 1,
                        pQueuePriorities = queuePriority.data,
                    }
                ) {
                    dbg.logError("VulkanRenderer", "Failed to add queue create info.");
                    break;
                }
            }

            physicalDeviceFeatures := VkPhysicalDeviceFeatures.{
                geometryShader = xx true,
                samplerAnisotropy = xx true,
            };

            deviceCreateInfo := VkDeviceCreateInfo.{
                sType = .DEVICE_CREATE_INFO,
                pNext = null,
                flags = 0,
                queueCreateInfoCount = xx queueCreateInfos.num,
                pQueueCreateInfos = *queueCreateInfos.buffer[0],
                enabledLayerCount = xx enabledLayers.count,
                ppEnabledLayerNames = enabledLayers.data,
                enabledExtensionCount = xx extensions.count,
                ppEnabledExtensionNames = extensions.data,
                pEnabledFeatures = *physicalDeviceFeatures,
            };

            device: VkDevice = ---;
            checkResult(vkCreateDevice(physicalDevice, *deviceCreateInfo, null, *device), "vkCreateDevice");

            graphicsQueue, presentQueue: VkQueue;
            vkGetDeviceQueue(device, xx graphicsIndex, 0, *graphicsQueue);
            vkGetDeviceQueue(device, xx presentIndex, 0, *presentQueue);

            state.device = .{
                device = device,
                graphicsQueue = graphicsQueue,
                graphicsQueueIdx = xx graphicsIndex,
                presentQueue = presentQueue,
                presentQueueIdx = xx presentIndex,
            };

            commandPoolCreateInfo := VkCommandPoolCreateInfo.{
                sType = .COMMAND_POOL_CREATE_INFO,
                pNext = null,
                flags = .RESET_COMMAND_BUFFER_BIT | .TRANSIENT_BIT,
                queueFamilyIndex = state.device.graphicsQueueIdx,
            };

            commandPool: VkCommandPool = ---;
            checkResult(vkCreateCommandPool(state.device.device, *commandPoolCreateInfo, null, *commandPool), "vkCreateCommandPool");
            state.commandPool = commandPool;
        }
    }

    return state;
}

destroySubsystem :: (state: *SubsystemState) {
    vkDestroyCommandPool(state.device.device, state.commandPool, null);
    state.commandPool = null;

    vkDestroyDevice(state.device.device, null);
    state.device = .{};

    state.physicalDevices = .{};

    #if RHI_VK_DEBUG {
        if state.debugCallback {
            vkDestroyDebugUtilsMessengerEXT: PFN_vkDestroyDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(state.instance, "vkDestroyDebugUtilsMessengerEXT");
            if vkDestroyDebugUtilsMessengerEXT {
                vkDestroyDebugUtilsMessengerEXT(state.instance, state.debugCallback, null);
            } else {
                dbg.log("VulkanRenderer", .ERROR, "Failed to get debug report destroy function.");
            }
            state.debugCallback = null;
        }
    }

    vkDestroyInstance(state.instance, null);
    state.instance = null;
}

updateSubsystem :: (windowState: *window.SubsystemState, state: *SubsystemState) {
    shutdownWindowsToBeClosed(windowState, state);
    initializeNewWindows(windowState, state);
    processResizedWindows(windowState, state);

    for i: 0..state.windows.num - 1 {
        rendererWindowState := access(*state.windows, i);

        vkAcquireNextImageKHR(
            state.device.device,
            rendererWindowState.swapchain,
            math.U64_MAX,
            rendererWindowState.imageAvailableSemaphore,
            VK_NULL_HANDLE,
            *rendererWindowState.frameIdx,
        );

        fence := rendererWindowState.swapchainFences.buffer[rendererWindowState.frameIdx];
        vkWaitForFences(state.device.device, 1, *fence, VK_TRUE, math.U64_MAX);
        vkResetFences(state.device.device, 1, *fence);
        
        cmdBuff := *rendererWindowState.commandBuffers.buffer[rendererWindowState.frameIdx];
        image := rendererWindowState.swapchainImageViews.buffer[rendererWindowState.frameIdx];
        frameBuff := rendererWindowState.framebuffers.buffer[rendererWindowState.frameIdx];

        vkResetCommandBuffer(<< cmdBuff, 0);

        
        {
            cmdBeginInfo := VkCommandBufferBeginInfo.{
                sType = .COMMAND_BUFFER_BEGIN_INFO,
                pNext = null,
                flags = .SIMULTANEOUS_USE_BIT,
                pInheritanceInfo = null,
            };

            vkBeginCommandBuffer(<< cmdBuff, *cmdBeginInfo);
            defer vkEndCommandBuffer(<< cmdBuff);

            {
                clearValues := VkClearValue.[
                    .{color = .{_float32 = .[0,0,0,1]}},
                    .{depthStencil = .{depth = 1.0, stencil = 0}},
                ];
                renderPassBeginInfo := VkRenderPassBeginInfo.{
                    sType = .RENDER_PASS_BEGIN_INFO,
                    pNext = null,
                    renderPass = rendererWindowState.renderPass,
                    framebuffer = frameBuff,
                    renderArea = .{
                        offset = .{x = 0, y = 0},
                        extent = .{width = rendererWindowState.width, height = rendererWindowState.height},
                    },
                    clearValueCount = clearValues.count,
                    pClearValues = clearValues.data,
                };

                vkCmdBeginRenderPass(<< cmdBuff, *renderPassBeginInfo, .INLINE);
                defer vkCmdEndRenderPass(<< cmdBuff);
            }
        }

        pipelineStageFlag: VkPipelineStageFlags = .TRANSFER_BIT;
        submitInfo := VkSubmitInfo.{
            sType = .SUBMIT_INFO,
            pNext = null,
            waitSemaphoreCount = 1,
            pWaitSemaphores = *rendererWindowState.imageAvailableSemaphore,
            pWaitDstStageMask = *pipelineStageFlag,
            commandBufferCount = 1,
            pCommandBuffers = cmdBuff,
            signalSemaphoreCount = 1,
            pSignalSemaphores = *rendererWindowState.renderFinishedSemaphore,
        };

        vkQueueSubmit(state.device.graphicsQueue, 1, *submitInfo, fence);

        presentInfo := VkPresentInfoKHR.{
            sType = .PRESENT_INFO_KHR,
            pNext = null,
            waitSemaphoreCount = 1,
            pWaitSemaphores = *rendererWindowState.renderFinishedSemaphore,
            swapchainCount = 1,
            pSwapchains = *rendererWindowState.swapchain,
            pImageIndices = *rendererWindowState.frameIdx,
            pResults = null,
        };

        vkQueuePresentKHR(state.device.presentQueue, *presentInfo);
        vkQueueWaitIdle(state.device.presentQueue);
    }
}

#scope_file
#import,file "state.jai";
#import,file "errors.jai";
#import,file "window_lifetime.jai";
#import "Basic";
#import "collections";
dbg :: #import "debug";
math :: #import "Math";
#import "SDL";
#import "Vulkan";
window :: #import "window";
