RhiSubsystemState :: struct {
    api: GraphicsAPI;
    graphicsAPIState: GraphicsAPIState;
}

GraphicsAPI :: enum u8 {
    Vulkan;
    DirectX;
}

GraphicsAPIState :: union {
    vulkan: VulkanSubsystemState;
    directX: DirectXSubsystemState;
}