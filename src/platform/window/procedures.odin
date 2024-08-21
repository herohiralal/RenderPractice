package window

import "../collections"
import "../debug"
import "core:strings"
import "vendor:sdl2"

createSubsystem :: proc() -> SubsystemState {
    output: SubsystemState
    output.valid = (0 == sdl2.Init(sdl2.INIT_VIDEO))
    output.requirements = WindowRequirementBuffer{}
    collections.tryAdd(&output.requirements.buffer, WindowRequirement{title = "Hello World!", width = 800, height = 600})
    output.events = WindowEventBuffer{}
    output.windows = WindowStateBuffer{}

    // event buffers
    output.createdWindows = WindowIndexBuffer{}
    output.windowsToBeClosed = WindowIndexBuffer{}

    if !output.valid do log_sdl_error()
    return output
}

destroySubsystem :: proc(state: ^SubsystemState) {
    if state.valid {
        sdl2.Quit()
    }
    state.valid = false
    collections.clear(&state.events.buffer)
}

createNewWindows :: proc(state: ^SubsystemState) {
    originalCount := collections.getCount(&state.windows.buffer)

    for i: u64 = 0; i < collections.getCount(&state.requirements.buffer); i += 1 {

        if collections.getCount(&state.windows.buffer) >= collections.getCapacity(&state.windows.buffer) {
            debug.log("Window Subsystem", debug.LogLevel.ERROR, "Window limit reached")
            break
        }

        requirement := collections.access(&state.requirements.buffer, i)
        title, err := strings.clone_to_cstring(requirement.title)
        if err != nil {
            debug.log("Window Subsystem", debug.LogLevel.ERROR, "Failed to clone title")
            continue
        }
        defer delete(title)

        sdlWindowPtr := sdl2.CreateWindow(
            title,
            sdl2.WINDOWPOS_UNDEFINED,
            sdl2.WINDOWPOS_UNDEFINED,
            requirement.width,
            requirement.height,
            sdl2.WINDOW_SHOWN | sdl2.WINDOW_VULKAN | sdl2.WINDOW_ALLOW_HIGHDPI,
        )

        if sdlWindowPtr == nil {
            log_sdl_error()
            continue
        }

        state.handleIterator += 1
        newWindow := WindowState {
            handle = state.handleIterator,
            valid  = true,
            idx    = u32(collections.getCount(&state.windows.buffer)),
            ptr    = sdlWindowPtr,
        }

        collections.tryAdd(&state.windows.buffer, newWindow)

    }

    collections.clear(&state.requirements.buffer) // all the requirements have been processed

    // add the created windows to the createdWindows buffer
    collections.clear(&state.createdWindows.buffer)
    for i: u64 = originalCount; i < collections.getCount(&state.windows.buffer); i += 1 {
        window := collections.access(&state.windows.buffer, i)
        collections.tryAdd(&state.createdWindows.buffer, window.idx)
    }
}

pollEvents :: proc(state: ^SubsystemState) {

    windowCount := collections.getCount(&state.windows.buffer)
    windowMap := make(map[u32]^WindowState, windowCount)
    defer delete(windowMap)

    for i: u64 = 0; i < collections.getCount(&state.windows.buffer); i += 1 {
        window := collections.access(&state.windows.buffer, i)
        windowMap[sdl2.GetWindowID((^sdl2.Window)(window.ptr))] = window
    }

    collections.clear(&state.events.buffer)
    evt: sdl2.Event = ---
    for sdl2.PollEvent(&evt) {
        if evt.type == sdl2.EventType.QUIT {
            count := u32(collections.getCount(&state.windows.buffer))
            for i: u32 = 0; i < count; i += 1 {
                if !collections.tryAdd(&state.windowsToBeClosed.buffer, i) {
                    debug.log("Window Subsystem", debug.LogLevel.ERROR, "Failed to add window close event.")
                }
            }
        } else if evt.type == sdl2.EventType.WINDOWEVENT {
            windowPtr := sdl2.GetWindowFromID(evt.window.windowID)
            if evt.window.event == sdl2.WindowEventID.CLOSE {
                if window, ok := windowMap[evt.window.windowID]; ok {
                    if !collections.tryAdd(&state.windowsToBeClosed.buffer, window.idx) {
                        debug.log("Window Subsystem", debug.LogLevel.ERROR, "Failed to add window close event.")
                    }
                }
            }
        } else if evt.type == sdl2.EventType.KEYDOWN {
            windowPtr := sdl2.GetWindowFromID(evt.key.windowID)
            if evt.key.keysym.sym == sdl2.Keycode.ESCAPE {
                if window, ok := windowMap[evt.window.windowID]; ok {
                    if !collections.tryAdd(&state.windowsToBeClosed.buffer, window.idx) {
                        debug.log("Window Subsystem", debug.LogLevel.ERROR, "Failed to add window close event.")
                    }
                }
            } else {
                // ignore for now
            }
        } else {
            // ignore
        }
    }

}

destroyClosedWindows :: proc(state: ^SubsystemState) {
    for i: u64 = 0; i < collections.getCount(&state.windowsToBeClosed.buffer); i += 1 {
        windowIdx := collections.access(&state.windowsToBeClosed.buffer, i)^
        windowState := collections.access(&state.windows.buffer, u64(windowIdx))
        sdl2.DestroyWindow((^sdl2.Window)(windowState.ptr))
        windowState.valid = false
        windowState.ptr = nil
    }

    collections.clear(&state.windowsToBeClosed.buffer)

    // window remap
    windowCount := collections.getCount(&state.windows.buffer)
    windowMap := make(map[u32]u32, windowCount)
    defer delete(windowMap)

    // remove invalid windows
    for i := u64(0); i < collections.getCount(&state.windows.buffer); i += 1 {
        windowState := collections.access(&state.windows.buffer, i)
        if !windowState.valid {
            collections.tryEraseSwapBack(&state.windows.buffer, i)
            i -= 1
            continue
        }

        windowMap[windowState.idx] = u32(i)
    }

    // update the window indices
    for i := u64(0); i < collections.getCount(&state.windows.buffer); i += 1 {
        windowState := collections.access(&state.windows.buffer, i)
        windowState.idx = windowMap[windowState.idx]
    }

    for i := u64(0); i < collections.getCount(&state.createdWindows.buffer); i += 1 {
        windowIdx := collections.access(&state.createdWindows.buffer, i)^
        collections.access(&state.windows.buffer, u64(windowIdx)).idx = windowMap[windowIdx]
    }
}

@(private = "file")
log_sdl_error :: proc() {
    error := sdl2.GetErrorString()
    debug.log("Window Subsystem", debug.LogLevel.ERROR, sdl2.GetErrorString())
}
