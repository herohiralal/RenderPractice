AppState :: struct {
    ssWindow: WindowSubsystemState;
    ssRenderer: RhiSubsystemState;
}

createAppState :: () -> *AppState {
    output := New(AppState);
    output.ssWindow = createWindowSubsystem();
    output.ssRenderer = createRhiSubsystem(getCurrentGraphicsAPI());
    return output;
}

destroyAppState :: (state: *AppState) {
    destroyRhiSubsystem(*state.ssRenderer);
    destroyWindowSubsystem(*state.ssWindow);
    free(state);
}

shouldClose :: (state: *AppState) -> bool {
    return 0 == state.ssWindow.windows.num;
}