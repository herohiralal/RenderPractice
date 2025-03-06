getCurrentGraphicsAPI :: () -> GraphicsAPI {
    return .Vulkan;
}

createSubsystem :: (api: GraphicsAPI) -> SubsystemState {
    result := SubsystemState.{
        api = api,
    };

    if #complete api == {
    case .Null;
        result.graphicsAPIState.nil = nl.createSubsystem();
    case .Vulkan;
        result.graphicsAPIState.vulkan = vk.createSubsystem();
    case .DirectX;
        result.graphicsAPIState.directX = dx.createSubsystem();
    case .Metal;
        result.graphicsAPIState.metal = mt.createSubsystem();
    }

    return result;
}

destroySubsystem :: (state: *SubsystemState) {
    if #complete state.api == {
    case .Null;
        nl.destroySubsystem(*state.graphicsAPIState.nil);
    case .Vulkan;
        vk.destroySubsystem(*state.graphicsAPIState.vulkan);
    case .DirectX;
        dx.destroySubsystem(*state.graphicsAPIState.directX);
    case .Metal;
        mt.destroySubsystem(*state.graphicsAPIState.metal);
    }
}

updateSubsystem :: (windowState: *window.SubsystemState, state: *SubsystemState) {
    // change api if changed
    {
        newApi := getCurrentGraphicsAPI();
        if newApi != state.api {
            destroySubsystem(state);
            state.* = createSubsystem(newApi);
        }
    }

    if #complete state.api == {
    case .Null;
        nl.updateSubsystem(windowState, *state.graphicsAPIState.nil);
    case .Vulkan;
        vk.updateSubsystem(windowState, *state.graphicsAPIState.vulkan);
    case .DirectX;
        dx.updateSubsystem(windowState, *state.graphicsAPIState.directX);
    case .Metal;
        mt.updateSubsystem(windowState, *state.graphicsAPIState.metal);
    }
}

#scope_file
#import,file "state.jai";
window :: #import "window";
