package main

import "core:fmt"
import "vendor:sdl2"

import "platform/collections"
import "platform/debug"
import "platform/window"

AppState :: struct {
    windowSubsystem: window.SubsystemState,
}

main :: proc() {
    appState := AppState {
        windowSubsystem = window.createSubsystem(),
    }

    defer window.destroySubsystem(&appState.windowSubsystem)
    defer debug.log("Main", debug.LogLevel.INFO, "Hello, World!")

    windowRequirements: window.RequirementBuffer
    collections.try_add(&windowRequirements.buffer, window.Requirement{title = "Hello, World!", width = 800, height = 600})

    for {
        window.updateSubsystem(&windowRequirements, &appState.windowSubsystem)
        collections.clear(&windowRequirements.buffer)

        if 0 == collections.get_count(&appState.windowSubsystem.windows.buffer) {
            break
        }
    }
}
