package rhi

import "../rhi_null"
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
    directX: rhi_null.SubsystemState,
}
