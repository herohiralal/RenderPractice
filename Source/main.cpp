#include "Core/Logging/Logging.h"
#include "SDL.h"

LOG_CATEGORY(Main)
LOG_CATEGORY(SDL3)

auto main(int argc, char** argv) -> int
{
    if (0 != SDL_Init(SDL_InitFlags::SDL_INIT_VIDEO))
    {
        Debug::Log<LogMain>(LogLevel::Error, "Failed to initialize SDL2! Read next error for more info.");
        Debug::Log<LogSDL3>(LogLevel::Error, SDL_GetError());
        return EXIT_FAILURE;
    }

    Debug::Log<LogMain>("Hello, World!");
    SDL_Quit();
    return EXIT_SUCCESS;
}
