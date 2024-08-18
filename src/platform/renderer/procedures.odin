package renderer

import "vendor:sdl2"

createSubsystem :: proc() -> SubsystemState {
    return SubsystemState{}
}

destroySubsystem :: proc(state: ^SubsystemState) {}

updateSubsystem :: proc(state: ^SubsystemState) {}
