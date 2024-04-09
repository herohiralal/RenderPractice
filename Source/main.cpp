#include <iostream>

#include "SDL.h"

auto main(int argc, char** argv) -> int
{
    if (0 != SDL_Init(SDL_InitFlags::SDL_INIT_VIDEO))
    {
        std::cerr << "Error: " << SDL_GetError() << std::endl;
        return EXIT_FAILURE;
    }

    std::cout << "Hello, World!" << std::endl;
    SDL_Quit();
    return EXIT_SUCCESS;
}
