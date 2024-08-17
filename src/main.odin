package main

import "core:fmt"
import "vendor:sdl2"

import "platform/collections"
import "platform/debug"
import "platform/window"

main :: proc() {
    appState := createAppState()
    defer destroyAppState(appState)

    for {
        window.updateSubsystem(&appState.windowSubsystem)

        if shouldClose(appState) {
            break
        }
    }
}
