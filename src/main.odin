package main

import "core:fmt"
import "vendor:sdl2"

import "platform/collections"
import "platform/debug"
import "platform/rhi"
import "platform/window"

main :: proc() {
    appState := createAppState()
    defer destroyAppState(appState)

    for {
        window.createNewWindows(&appState.ssWindow)
        window.pollEvents(&appState.ssWindow)

        rhi.updateSubsystem(&appState.ssWindow, &appState.ssRenderer)
        window.destroyClosedWindows(&appState.ssWindow)

        if shouldClose(appState) {
            break
        }
    }
}
