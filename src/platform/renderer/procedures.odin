package renderer

import "../collections"
import "../debug"
import "../window"
import win32 "core:sys/windows"
import "vendor:sdl2"
import "vendor:vulkan"

createSubsystem :: proc() -> SubsystemState {
    state := SubsystemState{}

    {
        vk_dll := win32.LoadLibraryW(win32.utf8_to_wstring("vulkan-1.dll"))

        get_instance_proc_address := auto_cast win32.GetProcAddress(vk_dll, "vkGetInstanceProcAddr")

        if get_instance_proc_address == nil {
            panic("vkGetInstanceProcAddr not loaded")
        }
        vulkan.load_proc_addresses_global(get_instance_proc_address)
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

    instance: vulkan.Instance = ---
    {
        extensionsCount := u32(0)
        sdl2.Vulkan_GetInstanceExtensions((^sdl2.Window)(tempWindow), &extensionsCount, nil)
        extensions := make([]cstring, extensionsCount)
        defer delete(extensions)
        sdl2.Vulkan_GetInstanceExtensions((^sdl2.Window)(tempWindow), &extensionsCount, raw_data(extensions))

        // create vulkan instance
        appInfo := vulkan.ApplicationInfo {
            sType              = vulkan.StructureType.APPLICATION_INFO,
            pNext              = nil,
            pApplicationName   = "RenderPractice",
            applicationVersion = vulkan.MAKE_VERSION(1, 0, 0),
            pEngineName        = "No Engine",
            engineVersion      = vulkan.MAKE_VERSION(1, 0, 0),
            apiVersion         = vulkan.API_VERSION_1_0,
        }

        instanceInfo := vulkan.InstanceCreateInfo {
            sType                   = vulkan.StructureType.INSTANCE_CREATE_INFO,
            pNext                   = nil,
            flags                   = {},
            pApplicationInfo        = &appInfo,
            enabledLayerCount       = 0,
            ppEnabledLayerNames     = nil,
            enabledExtensionCount   = extensionsCount,
            ppEnabledExtensionNames = raw_data(extensions),
        }

        checkResult(vulkan.CreateInstance(&instanceInfo, nil, &instance), "CreateInstance")
        vulkan.load_proc_addresses_instance(instance)
        state.instance = instance
    }

    windowSurface: vulkan.SurfaceKHR = ---
    if !sdl2.Vulkan_CreateSurface(tempWindow, instance, &windowSurface) {
        panic("Failed to create window surface")
    }
    defer vulkan.DestroySurfaceKHR(instance, windowSurface, nil)

    // pick device
    {
        physicalDeviceCount := u32(0)
        checkResult(vulkan.EnumeratePhysicalDevices(instance, &physicalDeviceCount, nil), "EnumeratePhysicalDevices")
        physicalDevices := make([]vulkan.PhysicalDevice, physicalDeviceCount)
        defer delete(physicalDevices)
        checkResult(
            vulkan.EnumeratePhysicalDevices(instance, &physicalDeviceCount, raw_data(physicalDevices)),
            "EnumeratePhysicalDevices",
        )

        for i := u32(0); i < physicalDeviceCount; i += 1 {
            dev := physicalDevices[i]

            properties: vulkan.PhysicalDeviceProperties = ---
            vulkan.GetPhysicalDeviceProperties(dev, &properties)

            if properties.deviceType != vulkan.PhysicalDeviceType.DISCRETE_GPU {
                continue
            }

            features: vulkan.PhysicalDeviceFeatures = ---
            vulkan.GetPhysicalDeviceFeatures(dev, &features)

            if !features.geometryShader {
                continue
            }

            physicalDevice := PhysicalDevice {
                device = rawptr(dev),
            }

            if !collections.tryAdd(&state.devices.buffer, physicalDevice) {
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
        physicalDevice := vulkan.PhysicalDevice(collections.access(&state.devices.buffer, u64(state.selectedDeviceIdx)).device)

        queueFamilyCount := u32(0)
        vulkan.GetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, nil)
        queueFamilies := make([]vulkan.QueueFamilyProperties, queueFamilyCount)
        defer delete(queueFamilies)
        vulkan.GetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, raw_data(queueFamilies))

        for i := u32(0); i < queueFamilyCount; i += 1 {
            queueFamily := queueFamilies[i]

            if queueFamily.queueCount > 0 && .GRAPHICS in queueFamily.queueFlags {
                graphicsIndex = int(i)
            }

            surfaceSupported: b32 = false
            vulkan.GetPhysicalDeviceSurfaceSupportKHR(physicalDevice, i, windowSurface, &surfaceSupported)
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
        physicalDevice := vulkan.PhysicalDevice(collections.access(&state.devices.buffer, u64(state.selectedDeviceIdx)).device)

        enabledLayers := []cstring{}
        extensions := []cstring{vulkan.KHR_SWAPCHAIN_EXTENSION_NAME}
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

        queueCreateInfos: collections.FixedSizeBuffer(vulkan.DeviceQueueCreateInfo, 2)
        for i in 0 ..< uniqueQueueIndices.count {
            if !collections.tryAdd(
                &queueCreateInfos,
                vulkan.DeviceQueueCreateInfo {
                    sType = vulkan.StructureType.DEVICE_QUEUE_CREATE_INFO,
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

        physicalDeviceFeatures := vulkan.PhysicalDeviceFeatures {
            geometryShader    = true,
            samplerAnisotropy = true,
        }

        deviceCreateInfo := vulkan.DeviceCreateInfo {
            sType                   = vulkan.StructureType.DEVICE_CREATE_INFO,
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

        device: vulkan.Device = ---
        vulkan.CreateDevice(physicalDevice, &deviceCreateInfo, nil, &device)
        vulkan.load_proc_addresses_device(device)

        graphicsQueue, presentQueue := vulkan.Queue{}, vulkan.Queue{}
        vulkan.GetDeviceQueue(device, u32(graphicsIndex), 0, &graphicsQueue)
        vulkan.GetDeviceQueue(device, u32(presentIndex), 0, &presentQueue)

        state.device = Device {
            device        = rawptr(device),
            graphicsQueue = rawptr(graphicsQueue),
            presentQueue  = rawptr(presentQueue),
        }
    }

    return state
}

destroySubsystem :: proc(state: ^SubsystemState) {
    vulkan.DestroyDevice(vulkan.Device(state.device.device), nil)
    state.device = Device{}

    collections.clear(&state.devices.buffer)
    state.devices = PhysicalDeviceBuffer{}

    vulkan.DestroyInstance(vulkan.Instance(state.instance), nil)
    state.instance = nil
}

updateSubsystem :: proc(windowState: ^window.SubsystemState, state: ^SubsystemState) {
    instance := vulkan.Instance(state.instance)

    // deinit windows about to be closed
    for i := u64(0); i < collections.getCount(&windowState.windowsToBeClosed.buffer); i += 1 {
        windowIdx := collections.access(&windowState.windowsToBeClosed.buffer, i)^
        windowState := collections.access(&windowState.windows.buffer, u64(windowIdx))

        windowPtr := windowState.ptr
    }

    // init new windows
    for i := u64(0); i < collections.getCount(&windowState.createdWindows.buffer); i += 1 {
        windowIdx := collections.access(&windowState.createdWindows.buffer, i)^
        windowState := collections.access(&windowState.windows.buffer, u64(windowIdx))

        windowPtr := windowState.ptr

        // surface: vulkan.SurfaceKHR = ---
        // {
        //     sdl2.Vulkan_CreateSurface((^sdl2.Window)(windowPtr), instance, &surface)
        // }
    }
}

@(private = "file")
checkResult :: proc(result: vulkan.Result, fnName: string) {
    switch result {
        case vulkan.Result.SUCCESS:
            return
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
