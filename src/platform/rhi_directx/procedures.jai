createSubsystem :: () -> SubsystemState { return .{}; }

destroySubsystem :: (state: *SubsystemState) { }

updateSubsystem :: (windowState: *window.SubsystemState, state: *SubsystemState) { }
