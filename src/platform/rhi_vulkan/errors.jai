#import "Vulkan";

checkResult :: (result: VkResult, fnName: string) {
    if result == {
        case .SUCCESS;
            return;
        case .NOT_READY;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%]. ",
                fnName,
                "NOT_READY",
            );
        case .TIMEOUT;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].   ",
                fnName,
                "TIMEOUT",
            );
        case .EVENT_SET;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%]. ",
                fnName,
                "EVENT_SET",
            );
        case .EVENT_RESET;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "EVENT_RESET",
            );
        case .INCOMPLETE;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "INCOMPLETE",
            );
        case .ERROR_OUT_OF_HOST_MEMORY;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_OUT_OF_HOST_MEMORY",
            );
        case .ERROR_OUT_OF_DEVICE_MEMORY;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_OUT_OF_DEVICE_MEMORY",
            );
        case .ERROR_INITIALIZATION_FAILED;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_INITIALIZATION_FAILED",
            );
        case .ERROR_DEVICE_LOST;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_DEVICE_LOST",
            );
        case .ERROR_MEMORY_MAP_FAILED;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_MEMORY_MAP_FAILED",
            );
        case .ERROR_LAYER_NOT_PRESENT;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_LAYER_NOT_PRESENT",
            );
        case .ERROR_EXTENSION_NOT_PRESENT;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_EXTENSION_NOT_PRESENT",
            );
        case .ERROR_FEATURE_NOT_PRESENT;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_FEATURE_NOT_PRESENT",
            );
        case .ERROR_INCOMPATIBLE_DRIVER;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_INCOMPATIBLE_DRIVER",
            );
        case .ERROR_TOO_MANY_OBJECTS;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_TOO_MANY_OBJECTS",
            );
        case .ERROR_FORMAT_NOT_SUPPORTED;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_FORMAT_NOT_SUPPORTED",
            );
        case .ERROR_FRAGMENTED_POOL;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_FRAGMENTED_POOL",
            );
        case .ERROR_OUT_OF_POOL_MEMORY;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_OUT_OF_POOL_MEMORY",
            );
        case .ERROR_INVALID_EXTERNAL_HANDLE;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_INVALID_EXTERNAL_HANDLE",
            );
        case .ERROR_SURFACE_LOST_KHR;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_SURFACE_LOST_KHR",
            );
        case .ERROR_NATIVE_WINDOW_IN_USE_KHR;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_NATIVE_WINDOW_IN_USE_KHR",
            );
        case .SUBOPTIMAL_KHR;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "SUBOPTIMAL_KHR",
            );
        case .ERROR_OUT_OF_DATE_KHR;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_OUT_OF_DATE_KHR",
            );
        case .ERROR_INCOMPATIBLE_DISPLAY_KHR;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_INCOMPATIBLE_DISPLAY_KHR",
            );
        case .ERROR_VALIDATION_FAILED_EXT;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_VALIDATION_FAILED_EXT",
            );
        case .ERROR_INVALID_SHADER_NV;
            logError(
                "VulkanRenderer",
                "Failure on calling Vulkan API [%]: [%].",
                fnName,
                "ERROR_INVALID_SHADER_NV",
            );
    }

    assert(false, "Vulkan call failed.");
}