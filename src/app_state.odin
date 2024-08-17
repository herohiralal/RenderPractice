package main

import "platform/collections"
import "platform/renderer"
import "platform/window"

AppState :: struct {
    ssWindow:   window.SubsystemState,
    ssRenderer: renderer.SubsystemState,
}

createAppState :: proc() -> ^AppState {
    output := new(AppState)
    output^ = AppState{}

    output.ssWindow = window.createSubsystem()
    output.ssRenderer = renderer.createSubsystem()

    return output
}

destroyAppState :: proc(state: ^AppState) {     // LIFO

    renderer.destroySubsystem(&state.ssRenderer)
    window.destroySubsystem(&state.ssWindow)

    free(state)
}

shouldClose :: proc(state: ^AppState) -> bool {
    return 0 == collections.getCount(&state.ssWindow.windows.buffer)
}
