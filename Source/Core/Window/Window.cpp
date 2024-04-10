#include "Window.h"

#include "SDL.h"

class Window
{
public:
    static WindowState Open(const char* title, int w, int h);
    static void        Close(WindowState& window);
};

class WindowInternals
{
public:
    static void LogSDLError()
    {
        Debug::Log<LogWindow>(LogLevel::Info, "SDL failure. Please read the next error for more details.");
        Debug::Log<LogWindow>(LogLevel::Error, SDL_GetError());
    }

    static void PushEvent(WindowEventBuffer& buffer, const WindowEvent& event)
    {
        if (!buffer.TryAdd(event)) { Debug::Log<LogWindow>(LogLevel::Warning, "Window event buffer is full."); }
    }
};

WindowSubsystemState WindowSubsystem::Create()
{
    WindowSubsystemState output;
    output.valid        = (0 == SDL_Init(SDL_INIT_VIDEO));
    output.success      = output.valid;
    output.windowEvents = WindowEventBuffer();
    if (!output.success) { WindowInternals::LogSDLError(); }
    return output;
}

void WindowSubsystem::Destroy(WindowSubsystemState& windowSubsystem)
{
    if (windowSubsystem.success) { SDL_Quit(); }

    windowSubsystem.valid   = false;
    windowSubsystem.success = false;
    windowSubsystem.windowEvents.Clear();
}

void WindowSubsystem::Update(const WindowRequirementBuffer& requirements, WindowSubsystemState& windowSubsystem)
{
    // create any new windows required
    {
        for (int i = 0; i < requirements.GetCount(); ++i)
        {
            if (windowSubsystem.windows.GetCount() >= windowSubsystem.windows.GetCapacity())
            {
                Debug::Log<LogWindow>(LogLevel::Warning, "Window buffer is full.");
                break;
            }

            const WindowRequirement& requirement = requirements[i];
            WindowState              window      = Window::Open(requirement.title, requirement.w, requirement.h);
            if (window.valid) { windowSubsystem.windows.TryAdd(window); }
        }
    }

    // poll events
    {
        windowSubsystem.windowEvents.Clear();

        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
                case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
                {
                    WindowEvent windowEvent;
                    windowEvent.type           = WindowEventType::Close;
                    windowEvent.close.windowId = event.window.windowID;
                    WindowInternals::PushEvent(windowSubsystem.windowEvents, windowEvent);
                    break;
                }
            }
        }
    }

    // close any windows that are not required
    {
        for (std::int64_t i = windowSubsystem.windows.GetCount() - 1; i >= 0; --i)
        {
            WindowState&        window   = windowSubsystem.windows[i];
            const std::uint32_t windowId = SDL_GetWindowID((SDL_Window*)window.ptr);

            bool close = false;
            for (int i = 0; i < windowSubsystem.windowEvents.GetCount(); ++i)
            {
                const WindowEvent& event = windowSubsystem.windowEvents[i];
                if (WindowEventType::Close == event.type && event.close.windowId == windowId) { close = true; }
            }

            if (close)
            {
                Window::Close(window);

                if (!windowSubsystem.windows.TryRemoveFrom(i, 1))
                {
                    Debug::Log<LogWindow>(LogLevel::Warning, "Could not remove from window buffer.");
                }
            }
        }
    }
}

WindowState Window::Open(const char* title, int w, int h)
{
    WindowState output;
    output.ptr   = SDL_CreateWindow(title, w, h, SDL_WINDOW_MAXIMIZED);
    output.valid = nullptr != output.ptr;
    if (!output.valid) { WindowInternals::LogSDLError(); }
    return output;
}

void Window::Close(WindowState& window)
{
    if (window.ptr) { SDL_DestroyWindow((SDL_Window*)window.ptr); }
    window.valid = false;
    window.ptr   = nullptr;
}
