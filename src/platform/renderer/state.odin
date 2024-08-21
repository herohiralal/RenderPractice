package renderer

import "../collections"

SubsystemState :: struct {
    instance:          rawptr,
    selectedDeviceIdx: i32,
    device:            Device,
    devices:           PhysicalDeviceBuffer,
    windows:           WindowStateBuffer,
}

WindowStateBuffer :: struct {
    buffer: collections.FixedSizeBuffer(WindowState, 16),
}

PhysicalDeviceBuffer :: struct {
    buffer: collections.FixedSizeBuffer(PhysicalDevice, 16),
}

WindowState :: struct {
    handle:  u64,
    surface: u64,
}

Device :: struct {
    device:        rawptr,
    graphicsQueue: rawptr,
    presentQueue:  rawptr,
}

PhysicalDevice :: struct {
    device: rawptr,
}
