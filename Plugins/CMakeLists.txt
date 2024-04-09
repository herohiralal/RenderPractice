add_library(Plugins INTERFACE)

add_subdirectory(Vulkan-Headers)

# Static SDL Lib
set(SDL_SHARED OFF)
set(SDL_STATIC ON)

# Minimal SDL Usage
set(SDL_AUDIO OFF)
set(SDL_VIDEO ON)
set(SDL_RENDER OFF)
set(SDL_CAMERA OFF)
set(SDL_JOYSTICK OFF)
set(SDL_HAPTIC OFF)
set(SDL_HIDAPI OFF)
set(SDL_POWER OFF)
set(SDL_SENSOR OFF)
set(SDL_DIALOG OFF)

add_subdirectory(SDL)

target_link_libraries(Plugins INTERFACE Vulkan::Headers SDL3::SDL3)