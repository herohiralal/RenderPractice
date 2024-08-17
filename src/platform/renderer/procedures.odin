package renderer

createSubsystem :: proc() -> SubsystemState {
    return SubsystemState{}
}

destroySubsystem :: proc(state: ^SubsystemState) {}

updateSubsystem :: proc(state: ^SubsystemState) {}
