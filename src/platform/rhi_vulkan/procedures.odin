package rhi_vulkan

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
