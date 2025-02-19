package rhi_vulkan

import "../debug"
import "vendor:vulkan"

@(private)
checkResult :: proc(result: vulkan.Result, fnName: string) {
    switch result {
        case vulkan.Result.SUCCESS:
            return
        case vulkan.Result.PIPELINE_BINARY_MISSING_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "PIPELINE_BINARY_MISSING_KHR",
            )
            break
        case vulkan.Result.ERROR_NOT_ENOUGH_SPACE_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_NOT_ENOUGH_SPACE_KHR",
            )
            break
        case vulkan.Result.NOT_READY:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s]. ",
                fnName,
                "NOT_READY",
            )
            break
        case vulkan.Result.TIMEOUT:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].   ",
                fnName,
                "TIMEOUT",
            )
            break
        case vulkan.Result.EVENT_SET:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s]. ",
                fnName,
                "EVENT_SET",
            )
            break
        case vulkan.Result.EVENT_RESET:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "EVENT_RESET",
            )
            break
        case vulkan.Result.INCOMPLETE:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "INCOMPLETE",
            )
            break
        case vulkan.Result.ERROR_OUT_OF_HOST_MEMORY:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_OUT_OF_HOST_MEMORY",
            )
            break
        case vulkan.Result.ERROR_OUT_OF_DEVICE_MEMORY:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_OUT_OF_DEVICE_MEMORY",
            )
            break
        case vulkan.Result.ERROR_INITIALIZATION_FAILED:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_INITIALIZATION_FAILED",
            )
            break
        case vulkan.Result.ERROR_DEVICE_LOST:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_DEVICE_LOST",
            )
            break
        case vulkan.Result.ERROR_MEMORY_MAP_FAILED:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_MEMORY_MAP_FAILED",
            )
            break
        case vulkan.Result.ERROR_LAYER_NOT_PRESENT:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_LAYER_NOT_PRESENT",
            )
            break
        case vulkan.Result.ERROR_EXTENSION_NOT_PRESENT:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_EXTENSION_NOT_PRESENT",
            )
            break
        case vulkan.Result.ERROR_FEATURE_NOT_PRESENT:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_FEATURE_NOT_PRESENT",
            )
            break
        case vulkan.Result.ERROR_INCOMPATIBLE_DRIVER:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_INCOMPATIBLE_DRIVER",
            )
            break
        case vulkan.Result.ERROR_TOO_MANY_OBJECTS:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_TOO_MANY_OBJECTS",
            )
            break
        case vulkan.Result.ERROR_FORMAT_NOT_SUPPORTED:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_FORMAT_NOT_SUPPORTED",
            )
            break
        case vulkan.Result.ERROR_FRAGMENTED_POOL:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_FRAGMENTED_POOL",
            )
            break
        case vulkan.Result.ERROR_UNKNOWN:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_UNKNOWN",
            )
            break
        case vulkan.Result.ERROR_OUT_OF_POOL_MEMORY:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_OUT_OF_POOL_MEMORY",
            )
            break
        case vulkan.Result.ERROR_INVALID_EXTERNAL_HANDLE:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_INVALID_EXTERNAL_HANDLE",
            )
            break
        case vulkan.Result.ERROR_FRAGMENTATION:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_FRAGMENTATION",
            )
            break
        case vulkan.Result.ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS",
            )
            break
        case vulkan.Result.PIPELINE_COMPILE_REQUIRED:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "PIPELINE_COMPILE_REQUIRED",
            )
            break
        case vulkan.Result.ERROR_SURFACE_LOST_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_SURFACE_LOST_KHR",
            )
            break
        case vulkan.Result.ERROR_NATIVE_WINDOW_IN_USE_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_NATIVE_WINDOW_IN_USE_KHR",
            )
            break
        case vulkan.Result.SUBOPTIMAL_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "SUBOPTIMAL_KHR",
            )
            break
        case vulkan.Result.ERROR_OUT_OF_DATE_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_OUT_OF_DATE_KHR",
            )
            break
        case vulkan.Result.ERROR_INCOMPATIBLE_DISPLAY_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_INCOMPATIBLE_DISPLAY_KHR",
            )
            break
        case vulkan.Result.ERROR_VALIDATION_FAILED_EXT:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_VALIDATION_FAILED_EXT",
            )
            break
        case vulkan.Result.ERROR_INVALID_SHADER_NV:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_INVALID_SHADER_NV",
            )
            break
        case vulkan.Result.ERROR_IMAGE_USAGE_NOT_SUPPORTED_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_IMAGE_USAGE_NOT_SUPPORTED_KHR",
            )
            break
        case vulkan.Result.ERROR_VIDEO_PICTURE_LAYOUT_NOT_SUPPORTED_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_VIDEO_PICTURE_LAYOUT_NOT_SUPPORTED_KHR",
            )
            break
        case vulkan.Result.ERROR_VIDEO_PROFILE_OPERATION_NOT_SUPPORTED_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_VIDEO_PROFILE_OPERATION_NOT_SUPPORTED_KHR",
            )
            break
        case vulkan.Result.ERROR_VIDEO_PROFILE_FORMAT_NOT_SUPPORTED_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_VIDEO_PROFILE_FORMAT_NOT_SUPPORTED_KHR",
            )
            break
        case vulkan.Result.ERROR_VIDEO_PROFILE_CODEC_NOT_SUPPORTED_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_VIDEO_PROFILE_CODEC_NOT_SUPPORTED_KHR",
            )
            break
        case vulkan.Result.ERROR_VIDEO_STD_VERSION_NOT_SUPPORTED_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_VIDEO_STD_VERSION_NOT_SUPPORTED_KHR",
            )
            break
        case vulkan.Result.ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT",
            )
            break
        case vulkan.Result.ERROR_NOT_PERMITTED_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_NOT_PERMITTED_KHR",
            )
            break
        case vulkan.Result.ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT",
            )
            break
        case vulkan.Result.THREAD_IDLE_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "THREAD_IDLE_KHR",
            )
            break
        case vulkan.Result.THREAD_DONE_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "THREAD_DONE_KHR",
            )
            break
        case vulkan.Result.OPERATION_DEFERRED_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "OPERATION_DEFERRED_KHR",
            )
            break
        case vulkan.Result.OPERATION_NOT_DEFERRED_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "OPERATION_NOT_DEFERRED_KHR",
            )
            break
        case vulkan.Result.ERROR_INVALID_VIDEO_STD_PARAMETERS_KHR:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_INVALID_VIDEO_STD_PARAMETERS_KHR",
            )
            break
        case vulkan.Result.ERROR_COMPRESSION_EXHAUSTED_EXT:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_COMPRESSION_EXHAUSTED_EXT",
            )
            break
        case vulkan.Result.ERROR_INCOMPATIBLE_SHADER_BINARY_EXT:
            debug.log(
                "VulkanRenderer",
                debug.LogLevel.ERROR,
                "Failure on calling Vulkan API [%s]: [%s].",
                fnName,
                "ERROR_INCOMPATIBLE_SHADER_BINARY_EXT",
            )
            break
    }

    panic("Vulkan API call failed.")
}
