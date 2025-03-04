getCurrentGraphicsAPI :: () -> GraphicsAPI {
    return .Vulkan;
}

createSubsystem :: (api: GraphicsAPI) -> SubsystemState {
    result := SubsystemState.{
        api = api,
    };

    if api == {
    case .Vulkan;
        #if ENABLE_VULKAN {
            result.graphicsAPIState.vulkan = vk.createSubsystem();
        }
    case .DirectX;
        #if ENABLE_DIRECTX {
            result.graphicsAPIState.directX = dx.createSubsystem();
        }
    }

    return result;
}

destroySubsystem :: (state: *SubsystemState) {
    if state.api == {
    case .Vulkan;
        #if ENABLE_VULKAN {
            vk.destroySubsystem(*state.graphicsAPIState.vulkan);
        }
    case .DirectX;
        #if ENABLE_DIRECTX {
            dx.destroySubsystem(*state.graphicsAPIState.directX);
        }
    }
}

updateSubsystem :: (windowState: *window.SubsystemState, state: *SubsystemState) {
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
        #if ENABLE_VULKAN {
            vk.updateSubsystem(windowState, *state.graphicsAPIState.vulkan);
        }
    case .DirectX;
        #if ENABLE_DIRECTX {
            dx.updateSubsystem(windowState, *state.graphicsAPIState.directX);
        }
    }
}
