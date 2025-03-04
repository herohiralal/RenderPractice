AppState :: struct {
    ssWindow: window.SubsystemState;
    ssRenderer: rhi.SubsystemState;
}

createAppState :: () -> *AppState {
    output := New(AppState);
    output.ssWindow = window.createSubsystem();
    output.ssRenderer = rhi.createSubsystem(rhi.getCurrentGraphicsAPI());
    return output;
}

destroyAppState :: (state: *AppState) {
    rhi.destroySubsystem(*state.ssRenderer);
    window.destroySubsystem(*state.ssWindow);
    free(state);
}

shouldClose :: (state: *AppState) -> bool {
    return 0 == state.ssWindow.windows.num;
}

#scope_file
#import "Basic";
rhi :: #import "rhi";
window :: #import "window";
