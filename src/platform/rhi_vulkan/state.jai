RHI_VK_DEBUG :: true;

SubsystemState :: struct {
    instance: VkInstance;
    debugCallback: VkDebugUtilsMessengerEXT;
    selectedDeviceIdx: s32;
    device: VulkanDevice;
    physicalDevices: FixedSizeBuffer(VulkanPhysicalDevice, 16);
    windows: FixedSizeBuffer(VulkanWindowState, 16);
    commandPool: VkCommandPool;
    shaders: VulkanShaders;
}

VulkanDevice :: struct {
    device: VkDevice;
    graphicsQueue: VkQueue;
    graphicsQueueIdx: u32;
    presentQueue: VkQueue;
    presentQueueIdx: u32;
}

VulkanPhysicalDevice :: struct {
    device: VkPhysicalDevice;
}

VulkanWindowState :: struct {
    handle: u64;
    surface: VkSurfaceKHR;
    swapchain: VkSwapchainKHR;
    width, height: u32;
    swapchainImageViews: FixedSizeBuffer(VkImageView, 32);
    swapchainFences: FixedSizeBuffer(VkFence, 32);
    depthImage: VkImage;
    depthImageMemory: VkDeviceMemory;
    depthImageView: VkImageView;
    renderPass: VkRenderPass;
    framebuffers: FixedSizeBuffer(VkFramebuffer, 32);
    commandBuffers: FixedSizeBuffer(VkCommandBuffer, 32);
    imageAvailableSemaphore: VkSemaphore;
    renderFinishedSemaphore: VkSemaphore;
    frameIdx: u32;
}

VulkanShaders :: struct {
    triangle: VulkanShader;
}

VulkanShader :: struct {
    vs, fs: VkShaderModule;
    layout: VkPipelineLayout;
}

#scope_file
#import "collections";
#import "Vulkan";
