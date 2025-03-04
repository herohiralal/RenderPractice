#import "Basic";
#import "SDL";
#if OS == .WINDOWS || OS == .LINUX || OS == .ANDROID {
    #import "Vulkan";
}

main :: () {
    appState := createAppState();
    defer destroyAppState(appState);

    while true {
        createNewWindows(*appState.ssWindow);
        pollWindowEvents(*appState.ssWindow);

        updateRhiSubsystem(*appState.ssWindow, *appState.ssRenderer);
        destroyClosedWindows(*appState.ssWindow);

        if shouldClose(appState) {
            break;
        }
    }
}
