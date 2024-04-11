#include "Core/Collections/FixedSizeBuffer.h"
#include "Core/Logging/Logging.h"
#include "Core/Window/Window.h"

struct AppState
{
    WindowSubsystemState windowSubsystem;
};

LOG_CATEGORY(Main)

int main(int argc, char** argv)
{
    AppState appState;
    appState.windowSubsystem = WindowSubsystem::Create();

    WindowRequirementBuffer windowRequirements;
    {
        windowRequirements.TryAdd({"Hello, World!", 800, 600});
    }

    while (true)
    {
        WindowSubsystem::Update(windowRequirements, appState.windowSubsystem);
        windowRequirements.Clear();

        if (0 == appState.windowSubsystem.windows.GetCount()) { break; }  // all windows closed
    }

    Debug::Log<LogMain>("Hello, World!");

    WindowSubsystem::Destroy(appState.windowSubsystem);
    return 0;
}
