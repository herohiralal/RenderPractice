createDirectXSubsystem :: () -> DirectXSubsystemState { return .{}; }

destroyDirectXSubsystem :: (state: *DirectXSubsystemState) { }

updateDirectXSubsystem :: (windowState: *WindowSubsystemState, state: *DirectXSubsystemState) { }