main :: () {
    appState := createAppState();
    defer destroyAppState(appState);

    while true {
        window.createNewWindows(*appState.ssWindow);
        window.pollWindowEvents(*appState.ssWindow);

        rhi.updateSubsystem(*appState.ssWindow, *appState.ssRenderer);
        window.destroyClosedWindows(*appState.ssWindow);

        if shouldClose(appState) {
            break;
        }
    }
}

#scope_file
#import,file "app_state.jai";
rhi :: #import "rhi";
window :: #import "window";
