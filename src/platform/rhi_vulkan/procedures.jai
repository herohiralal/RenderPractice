SDL_Vulkan_GetInstanceExtensions :: (window: *SDL_Window, pCount: *u32, pNames: **u8) -> s32 #foreign SDL2;

createVulkanSubsystem :: () -> VulkanSubsystemState {
    state: VulkanSubsystemState;

    tempWindow := SDL_CreateWindow(
        "temp window to get instance extensions",
        0,
        0,
        16,
        16,
        .SDL_WINDOW_VULKAN | .SDL_WINDOW_ALLOW_HIGHDPI | .SDL_WINDOW_MINIMIZED,
    );
    defer SDL_DestroyWindow(tempWindow);

    #if DEBUG {
        layerCount: u32;
        vkEnumerateInstanceLayerProperties(*layerCount, null);
        layersArray := NewArray(layerCount, VkLayerProperties,, allocator = temp);
        vkEnumerateInstanceLayerProperties(*layerCount, layersArray.data);
        log("VulkanRenderer", .INFO, "Vulkan layers:");
        for layer: layersArray {
            log("VulkanRenderer", .INFO, "  % (%)", to_string(layer.layerName.data), layer.specVersion);
        }

        extensionCount: u32;
        vkEnumerateInstanceExtensionProperties(null, *extensionCount, null);
        extensionsArray := NewArray(extensionCount, VkExtensionProperties,, allocator = temp);
        vkEnumerateInstanceExtensionProperties(null, *extensionCount, extensionsArray.data);
        log("VulkanRenderer", .INFO, "Vulkan extensions:");
        for ext: extensionsArray {
            log("VulkanRenderer", .INFO, "  % (%)", to_string(ext.extensionName.data), ext.specVersion);
        }
    }

    instance: VkInstance = ---;
    {
        extensionsCount: u32 = 0;
        SDL_Vulkan_GetInstanceExtensions(tempWindow, *extensionsCount, null);
        extensions: []*u8 = NewArray(extensionsCount + (1 * xx DEBUG), *u8,, allocator = temp);
        SDL_Vulkan_GetInstanceExtensions(tempWindow, *extensionsCount, extensions.data);
        #if DEBUG {
            extensions[extensionsCount] = VK_EXT_DEBUG_UTILS_EXTENSION_NAME;
            extensionsCount += 1;
        }

        log("VulkanRenderer", .INFO, "Required Vulkan extensions:");
        for ext: extensions {
            log("VulkanRenderer", .INFO, "  %", to_string(ext));
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
        #if DEBUG {
            instanceInfo.enabledLayerCount = debugLayers.count;
            instanceInfo.ppEnabledLayerNames = debugLayers.data;
        }

        checkResult(vkCreateInstance(*instanceInfo, null, *instance), "vkCreateInstance");
        state.instance = instance;

        #if DEBUG {
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
                            log("VulkanRenderer", .ERROR, "VULKAN VALIDATION: %", to_string(pCallbackData.pMessage));
                        } else if messageSeverity >= .WARNING_BIT_EXT {
                            log("VulkanRenderer", .WARNING, "VULKAN VALIDATION: %", to_string(pCallbackData.pMessage));
                        } else {
                            // log("VulkanRenderer", .INFO, "VULKAN VALIDATION: %", to_string(pCallbackData.pMessage));
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
                log("VulkanRenderer", .ERROR, "Failed to get debug report creation function.");
            }
        } else {
            state.debugCallback = null;
        }
    }

    return state;
}

destroyVulkanSubsystem :: (state: *VulkanSubsystemState) {
    #if DEBUG {
        if state.debugCallback {
            vkDestroyDebugUtilsMessengerEXT: PFN_vkDestroyDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(state.instance, "vkDestroyDebugUtilsMessengerEXT");
            if vkDestroyDebugUtilsMessengerEXT {
                vkDestroyDebugUtilsMessengerEXT(state.instance, state.debugCallback, null);
            } else {
                log("VulkanRenderer", .ERROR, "Failed to get debug report destroy function.");
            }
            state.debugCallback = null;
        }
    }

    vkDestroyInstance(state.instance, null);
    state.instance = null;
}

updateVulkanSubsystem :: (windowState: *WindowSubsystemState, state: *VulkanSubsystemState) { }

#scope_file

DEBUG :: true;
