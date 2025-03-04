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

#if OS == .WINDOWS {
    ENABLE_VULKAN :: true;
    ENABLE_DIRECTX :: false; // TODO: Implement DirectX
    ENABLE_METAL :: false;
} else #if OS == .LINUX {
    ENABLE_VULKAN :: true;
    ENABLE_DIRECTX :: false;
    ENABLE_METAL :: false;
} else #if OS == .ANDROID {
    ENABLE_VULKAN :: true;
    ENABLE_DIRECTX :: false;
    ENABLE_METAL :: false;
} else #if OS == .MACOS {
    ENABLE_VULKAN :: false;
    ENABLE_DIRECTX :: false;
    ENABLE_METAL :: false; // TODO: Implement Metal
} else {
    #assert(false, "Unsupported OS");
}

nl :: #import "rhi_null";

#if ENABLE_VULKAN {
    vk :: #import "rhi_vulkan";
} else {
    vk :: #import "rhi_null";
}

#if ENABLE_DIRECTX {
    dx :: #import "rhi_directx";
} else {
    dx :: #import "rhi_null";
}

#if ENABLE_METAL {
    mt :: #import "rhi_metal";
} else {
    mt :: #import "rhi_null";
}

#scope_file
#import "Basic";
