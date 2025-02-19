package rhi_vulkan

import "../collections"

SubsystemState :: struct {
    instance:          rawptr,
    selectedDeviceIdx: i32,
    device:            Device,
    physicalDevices:   PhysicalDeviceBuffer,
    windows:           WindowStateBuffer,
}

WindowStateBuffer :: struct {
    buffer: collections.FixedSizeBuffer(WindowState, 16),
}

PhysicalDeviceBuffer :: struct {
    buffer: collections.FixedSizeBuffer(PhysicalDevice, 16),
}

WindowState :: struct {
    handle:              u64,
    surface:             u64,
    swapchain:           u64,
    swapchainImageViews: ImageViewBuffer,
    depthImage:          u64,
    depthImageView:      u64,
    renderPass:          u64, // TODO: figure out what render pass???
    framebuffers:        FramebufferBuffer,
}

ImageViewBuffer :: struct {
    buffer: collections.FixedSizeBuffer(u64, 32),
}

FramebufferBuffer :: struct {
    buffer: collections.FixedSizeBuffer(u64, 32),
}

Device :: struct {
    device:           rawptr,
    graphicsQueue:    rawptr,
    graphicsQueueIdx: u32,
    presentQueue:     rawptr,
    presentQueueIdx:  u32,
}

PhysicalDevice :: struct {
    device: rawptr,
}
