main :: () {
    appState := createAppState();
    reset_temporary_storage();

    defer {
        destroyAppState(appState);
        reset_temporary_storage();
    }

    while true {
        window.createNewWindows(*appState.ssWindow);
        window.pollWindowEvents(*appState.ssWindow);

        rhi.updateSubsystem(*appState.ssWindow, *appState.ssRenderer);
        window.destroyClosedWindows(*appState.ssWindow);

        if shouldClose(appState) {
            break;
        }

        reset_temporary_storage();
    }
}

#scope_file
#import,file "app_state.jai";
#import "Basic";
rhi :: #import "rhi";
window :: #import "window";
