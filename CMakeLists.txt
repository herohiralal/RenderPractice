cmake_minimum_required(VERSION 3.5)
project(RenderPractice VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)

add_subdirectory(Plugins)

add_executable(${PROJECT_NAME}

    ################### Core ###################

    # Logging
    Source/Core/Logging/Logging.cpp

    # Window
    Source/Core/Window/Window.cpp

    ################# Rendering ################

    # Common
    Source/Rendering/Graphics.cpp

    # Vulkan
    Source/Rendering/Vulkan/Vulkan.cpp

    ################### Main ###################
    Source/main.cpp
)

set_target_properties(${PROJECT_NAME} PROPERTIES CXX_EXTENSIONS OFF)

if (MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /W4 /Wall /sdl /external:anglebrackets /external:W2 /fsanitize=address)
else()
    target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -pedantic)
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE Plugins)

target_include_directories(${PROJECT_NAME} PRIVATE
    Source/
)
