package rhi

import "../rhi_null"
import "../rhi_vulkan"
import "../window"

getCurrentGraphicsAPI :: proc() -> GraphicsAPI {
    return .Vulkan
}

createSubsystem :: proc(api: GraphicsAPI) -> SubsystemState {
    result := SubsystemState {
        api = api,
    }

    switch api {
        case .Vulkan:
            result.graphicsAPIState.vulkan = rhi_vulkan.createSubsystem()
        case .DirectX:
            result.graphicsAPIState.directX = rhi_null.createSubsystem()
    }

    return result
}

destroySubsystem :: proc(state: ^SubsystemState) {
    switch state.api {
        case .Vulkan:
            rhi_vulkan.destroySubsystem(&state.graphicsAPIState.vulkan)
        case .DirectX:
            rhi_null.destroySubsystem(&state.graphicsAPIState.directX)
    }
}

updateSubsystem :: proc(windowState: ^window.SubsystemState, state: ^SubsystemState) {
    // change api if changed
    {
        newApi := getCurrentGraphicsAPI()
        if newApi != state.api {
            destroySubsystem(state)
            state^ = createSubsystem(newApi)
        }
    }

    switch state.api {
        case .Vulkan:
            rhi_vulkan.updateSubsystem(windowState, &state.graphicsAPIState.vulkan)
        case .DirectX:
            rhi_null.updateSubsystem(windowState, &state.graphicsAPIState.directX)
    }
}
