getCurrentGraphicsAPI :: () -> GraphicsAPI {
    return .Vulkan;
}

createRhiSubsystem :: (api: GraphicsAPI) -> RhiSubsystemState {
    result := RhiSubsystemState.{
        api = api,
    };

    if api == {
    case .Vulkan;
        result.graphicsAPIState.vulkan = createVulkanSubsystem();
    case .DirectX;
        result.graphicsAPIState.directX = createDirectXSubsystem();
    }

    return result;
}

destroyRhiSubsystem :: (state: *RhiSubsystemState) {
    if state.api == {
    case .Vulkan;
        destroyVulkanSubsystem(*state.graphicsAPIState.vulkan);
    case .DirectX;
        destroyDirectXSubsystem(*state.graphicsAPIState.directX);
    }
}

updateRhiSubsystem :: (windowState: *WindowSubsystemState, state: *RhiSubsystemState) {
    // change api if changed
    {
        newApi := getCurrentGraphicsAPI();
        if newApi != state.api {
            destroyRhiSubsystem(state);
            <<state = createRhiSubsystem(newApi);
        }
    }

    if state.api == {
    case .Vulkan;
        updateVulkanSubsystem(windowState, *state.graphicsAPIState.vulkan);
    case .DirectX;
        updateDirectXSubsystem(windowState, *state.graphicsAPIState.directX);
    }
}
