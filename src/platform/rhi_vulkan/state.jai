SubsystemState :: struct {
    instance: *void;
    debugCallback: *void;
    selectedDeviceIdx: s32;
    device: VulkanDevice;
    physicalDevices: FixedSizeBuffer(VulkanPhysicalDevice, 16);
    windows: FixedSizeBuffer(VulkanWindowState, 16);
    commandPool: u64;
    shaders: VulkanShaders;
}

VulkanDevice :: struct {
    device: *void;
    graphicsQueue: *void;
    graphicsQueueIdx: u32;
    presentQueue: *void;
    presentQueueIdx: u32;
}

VulkanPhysicalDevice :: struct {
    device: *void;
}

VulkanWindowState :: struct {
    handle: u64;
    surface: u64;
    swapchain: u64;
    width, height: u32;
    swapchainImageViews: FixedSizeBuffer(u64, 32);
    swapchainFences: FixedSizeBuffer(u64, 32);
    depthImage: u64;
    depthImageMemory: u64;
    depthImageView: u64;
    renderPass: u64;
    framebuffers: FixedSizeBuffer(u64, 32);
    commandBuffers: FixedSizeBuffer(u64, 32);
    imageAvailableSemaphore: u64;
    renderFinishedSemaphore: u64;
    frameIdx: u32;
}

VulkanShaders :: struct {
    triangle: VulkanShader;
}

VulkanShader :: struct {
    vs, fs: u64;
    layout: u64;
}
