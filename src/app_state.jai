AppState :: struct {
    ssWindow: WindowSubsystemState;
}

createAppState :: () -> *AppState {
    output := New(AppState);
    output.ssWindow = createWindowSubsystem();
    return output;
}

destroyAppState :: (state: *AppState) {
    destroyWindowSubsystem(*state.ssWindow);
    free(state);
}

shouldClose :: (state: *AppState) -> bool {
    return 0 == state.ssWindow.windows.num;
}