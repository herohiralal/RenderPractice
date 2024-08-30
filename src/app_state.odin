package main

import "platform/collections"
import "platform/rhi"
import "platform/window"

AppState :: struct {
    ssWindow:   window.SubsystemState,
    ssRenderer: rhi.SubsystemState,
}

createAppState :: proc() -> ^AppState {
    output := new(AppState)
    output^ = AppState{}

    output.ssWindow = window.createSubsystem()
    output.ssRenderer = rhi.createSubsystem(.Vulkan)

    return output
}

destroyAppState :: proc(state: ^AppState) {     // LIFO

    rhi.destroySubsystem(&state.ssRenderer)
    window.destroySubsystem(&state.ssWindow)

    free(state)
}

shouldClose :: proc(state: ^AppState) -> bool {
    return 0 == collections.getCount(&state.ssWindow.windows.buffer)
}
