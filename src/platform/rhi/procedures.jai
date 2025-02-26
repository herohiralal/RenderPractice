getCurrentGraphicsAPI :: () -> GraphicsAPI {
    return .Vulkan;
}

createSubsystem :: (api: GraphicsAPI) -> RhiSubsystemState {
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

destroySubsystem :: (state: *RhiSubsystemState) {
    if state.api == {
    case .Vulkan;
        destroyVulkanSubsystem(*state.graphicsAPIState.vulkan);
    case .DirectX;
        destroyDirectXSubsystem(*state.graphicsAPIState.directX);
    }
}

updateSubsystem :: (windowState: *WindowSubsystemState, state: *RhiSubsystemState) {
    // change api if changed
    {
        newApi := getCurrentGraphicsAPI();
        if newApi != state.api {
            destroySubsystem(state);
            <<state = createSubsystem(newApi);
        }
    }

    if state.api == {
    case .Vulkan;
        updateVulkanSubsystem(windowState, *state.graphicsAPIState.vulkan);
    case .DirectX;
        updateDirectXSubsystem(windowState, *state.graphicsAPIState.directX);
    }
}
