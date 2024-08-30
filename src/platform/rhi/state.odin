package rhi

import "../rhi_directx"
import "../rhi_vulkan"

SubsystemState :: struct {
    api:              GraphicsAPI,
    graphicsAPIState: GraphicsAPIState,
}

GraphicsAPI :: enum {
    Vulkan,
    DirectX,
}

GraphicsAPIState :: struct #raw_union {
    vulkan:  rhi_vulkan.SubsystemState,
    directX: rhi_directx.SubsystemState,
}
