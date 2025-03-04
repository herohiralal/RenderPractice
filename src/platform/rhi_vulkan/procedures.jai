#import "Basic";
#import "Vulkan";
#import "SDL";

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

    {
        extension_count: u32;
        vkEnumerateInstanceExtensionProperties(null, *extension_count, null);
        extension_array := NewArray(extension_count, VkExtensionProperties,, allocator = temp);
        vkEnumerateInstanceExtensionProperties(null, *extension_count, extension_array.data);
        print("Vulkan extensions:\n");
        for ext: extension_array {
            print("  % (%)\n", to_string(ext.extensionName.data), ext.specVersion);
        }
    }

    instance: VkInstance = ---;
    {
        extensionsCount: u32 = 0;
        SDL_Vulkan_GetInstanceExtensions(tempWindow, *extensionsCount, null);
        extensions: []*u8 = NewArray(extensionsCount, *u8,, allocator = temp);
        SDL_Vulkan_GetInstanceExtensions(tempWindow, *extensionsCount, extensions.data);
        print("Required Vulkan extensions:\n");
        for ext: extensions {
            print("  %\n", to_string(ext));
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
        instanceInfo.enabledLayerCount = debugLayers.count;
        instanceInfo.ppEnabledLayerNames = debugLayers.data;

        instRes := vkCreateInstance(*instanceInfo, null, *instance);
        checkResult(instRes, "vkCreateInstance");
        state.instance = instance;
    }

    return state;
}

destroyVulkanSubsystem :: (state: *VulkanSubsystemState) {
    vkDestroyInstance(state.instance, null);
    state.instance = null;
}

updateVulkanSubsystem :: (windowState: *WindowSubsystemState, state: *VulkanSubsystemState) { }