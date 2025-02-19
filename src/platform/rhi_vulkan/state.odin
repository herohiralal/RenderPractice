package rhi_vulkan

import "../collections"

SubsystemState :: struct {
    instance:          rawptr,
    selectedDeviceIdx: i32,
    device:            Device,
    physicalDevices:   PhysicalDeviceBuffer,
    windows:           WindowStateBuffer,
    commandPool:       u64,
}

WindowStateBuffer :: struct {
    buffer: collections.FixedSizeBuffer(WindowState, 16),
}

PhysicalDeviceBuffer :: struct {
    buffer: collections.FixedSizeBuffer(PhysicalDevice, 16),
}

WindowState :: struct {
    handle:                  u64,
    surface:                 u64,
    swapchain:               u64,
    swapchainImageViews:     ImageViewBuffer,
    swapchainFences:         FencesBuffer,
    depthImage:              u64,
    depthImageView:          u64,
    renderPass:              u64, // TODO: figure out what render pass???
    framebuffers:            FramebufferBuffer,
    commandBuffers:          CommandBufferBuffer,
    imageAvailableSemaphore: u64,
    renderFinishedSemaphore: u64,
}

ImageViewBuffer :: struct {
    buffer: collections.FixedSizeBuffer(u64, 32),
}

FencesBuffer :: struct {
    buffer: collections.FixedSizeBuffer(u64, 32),
}

FramebufferBuffer :: struct {
    buffer: collections.FixedSizeBuffer(u64, 32),
}

CommandBufferBuffer :: struct {
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
