package rhi_null

import "../window"

createSubsystem :: proc() -> SubsystemState {
    return SubsystemState{}
}

destroySubsystem :: proc(state: ^SubsystemState) {}

updateSubsystem :: proc(windowState: ^window.SubsystemState, state: ^SubsystemState) {}
