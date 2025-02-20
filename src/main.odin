package main

import "core:fmt"
import "core:mem"
import "core:sync"
import "vendor:sdl2"

import "platform/collections"
import "platform/debug"
import "platform/rhi"
import "platform/window"

main :: proc() {
    memTracker: MemTrackingState
    context.allocator = initMemTracker(&memTracker)
    defer context.allocator = destroyMemTracker(&memTracker)

    appState := createAppState()
    free_all(context.temp_allocator)
    defer {
        destroyAppState(appState)
        free_all(context.temp_allocator)
    }

    for {
        defer free_all(context.temp_allocator)

        window.createNewWindows(&appState.ssWindow)
        window.pollEvents(&appState.ssWindow)

        rhi.updateSubsystem(&appState.ssWindow, &appState.ssRenderer)
        window.destroyClosedWindows(&appState.ssWindow)

        if shouldClose(appState) {
            break
        }
    }
}
