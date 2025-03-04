SubsystemState :: struct {
    api: GraphicsAPI;
    graphicsAPIState: GraphicsAPIState;
}

GraphicsAPI :: enum u8 {
    Null;
    Vulkan;
    DirectX;
    Metal;
}

GraphicsAPIState :: union {
    nil: nl.SubsystemState;
    vulkan: vk.SubsystemState;
    directX: dx.SubsystemState;
    metal: mt.SubsystemState;
}

nl :: #import "rhi_null";

#if OS == .WINDOWS || OS == .LINUX || OS == .ANDROID {
    vk :: #import "rhi_vulkan";
} else {
    vk :: #import "rhi_null";
}

// TODO: Implement DirectX
#if false && (OS == .WINDOWS || OS == .XBOX) {
    dx :: #import "rhi_directx";
} else {
    dx :: #import "rhi_null";
}

// TODO: Implement Metal
#if false && (OS == .MACOS) {
    mt :: #import "rhi_metal";
} else {
    mt :: #import "rhi_null";
}

#scope_file
#import "Basic";
