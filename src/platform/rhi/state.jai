SubsystemState :: struct {
    api: GraphicsAPI;
    graphicsAPIState: GraphicsAPIState;
}

GraphicsAPI :: enum u8 {
    Vulkan;
    DirectX;
}

GraphicsAPIState :: union {
    vulkan: vk.SubsystemState;
    directX: dx.SubsystemState;
}
