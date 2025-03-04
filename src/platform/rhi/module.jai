#load "state.jai";
#load "procedures.jai";

window :: #import "window";
#if OS == .WINDOWS {
    ENABLE_VULKAN :: true;
    ENABLE_DIRECTX :: true;
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
    ENABLE_METAL :: true;
} else {
    #assert(false, "Unsupported OS");
}

#if ENABLE_VULKAN {
    vk :: #import "rhi_vulkan";
}

#if ENABLE_DIRECTX {
    dx :: #import "rhi_directx";
}

#if ENABLE_METAL {
    mt :: #import "rhi_metal";
}
