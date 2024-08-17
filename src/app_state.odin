package main

import "platform/collections"
import "platform/window"

AppState :: struct {
    windowSubsystem: window.SubsystemState,
}

createAppState :: proc() -> ^AppState {
    output := new(AppState)
    output^ = AppState{}

    output.windowSubsystem = window.createSubsystem()

    return output
}

destroyAppState :: proc(state: ^AppState) {     // LIFO

    window.destroySubsystem(&state.windowSubsystem)

    free(state)
}

shouldClose :: proc(state: ^AppState) -> bool {
    return 0 == collections.get_count(&state.windowSubsystem.windows.buffer)
}
