#pragma once

#include "Core/Collections/FixedSizeBuffer.h"
#include "Core/Logging/Logging.h"

LOG_CATEGORY(Window)

enum class WindowEventType : std::uint8_t
{
    Close,
};

union WindowEvent
{
    WindowEventType type;

    struct
    {
        WindowEventType type;
        std::uint32_t   windowId;
    } close;
};

typedef FixedSizeBuffer<WindowEvent, 64> WindowEventBuffer;

struct WindowRequirement
{
    const char* title;
    int         w;
    int         h;
};

typedef FixedSizeBuffer<WindowRequirement, 16> WindowRequirementBuffer;

struct WindowState
{
public:
    bool  valid;
    void* ptr;
};

typedef FixedSizeBuffer<WindowState, 16> WindowBuffer;

struct WindowSubsystemState
{
public:
    bool              valid;
    bool              success;
    WindowEventBuffer windowEvents;
    WindowBuffer      windows;
};

class WindowSubsystem
{
public:
    static WindowSubsystemState Create();
    static void                 Destroy(WindowSubsystemState& windowSubsystem);
    static void                 Update(const WindowRequirementBuffer& requirements, WindowSubsystemState& windowSubsystem);
};
