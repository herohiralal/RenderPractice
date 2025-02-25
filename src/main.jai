#import "Basic";
#import "SDL";

main :: () {
    appState := createAppState();
    defer destroyAppState(appState);

    while true {
        createNewWindows(*appState.ssWindow);
        pollWindowEvents(*appState.ssWindow);

        destroyClosedWindows(*appState.ssWindow);

        if shouldClose(appState) {
            break;
        }
    }
}
