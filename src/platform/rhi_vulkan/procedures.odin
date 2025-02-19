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

    return state
}

destroySubsystem :: proc(state: ^SubsystemState) {
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
}
