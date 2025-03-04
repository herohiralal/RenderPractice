createWindowSubsystem :: () -> WindowSubsystemState {
    output: WindowSubsystemState;
    output.valid = (0 == SDL_Init(.SDL_INIT_VIDEO));
    output.requirements.buffer[0] = .{
        title = "Hello World!\0",
        width = 800,
        height = 600
    };
    output.requirements.num = 1;
    output.events = .{};
    output.windows = .{};
    output.createdWindows = .{};
    output.resizedWindows = .{};
    output.windowsToBeClosed = .{};
    if !output.valid {
        logSDLError();
    }
    return output;
}

destroyWindowSubsystem :: (state: *WindowSubsystemState) {
    if state.valid {
        SDL_Quit();
    }
    state.valid = false;
    state.requirements.num = 0;
    state.events = .{};
    state.windows = .{};
    state.createdWindows = .{};
    state.resizedWindows = .{};
    state.windowsToBeClosed = .{};
}

createNewWindows :: (state: *WindowSubsystemState) {
    originalCount := state.windows.num;

    for i: 0..(state.requirements.num - 1) {
        if state.windows.num >= state.windows.buffer.count {
            logError("Window Subsystem", "Window limit reached");
            break;
        }

        requirement := state.requirements.buffer[i];

        sdlWindowPtr := SDL_CreateWindow(
            requirement.title,
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            requirement.width,
            requirement.height,
            .SDL_WINDOW_SHOWN | .SDL_WINDOW_VULKAN | .SDL_WINDOW_ALLOW_HIGHDPI
        );

        if sdlWindowPtr == null {
            logSDLError();
            continue;
        }

        state.handleIterator += 1;
        newWindow := WindowState.{
            handle = state.handleIterator,
            valid = true,
            idx = cast(u32) state.windows.num,
            ptr = sdlWindowPtr
        };

        tryAdd(*state.windows, newWindow);
    }

    state.requirements.num = 0;

    // add the created windows to the createdWindows buffer
    state.createdWindows = .{};
    for i: (originalCount)..(state.windows.num - 1) {
        window := access(*state.windows, i);
        tryAdd(*state.createdWindows, window.idx);
    }
}

pollWindowEvents :: (state: *WindowSubsystemState) {
    WindowStateMapKVP :: struct {
        id: u32;
        window: *WindowState;
    }

    windowMap: FixedSizeBuffer(WindowStateMapKVP, state.windows.buffer.count);

    for i: 0..(state.windows.num - 1) {
        window := access(*state.windows, i);
        windowID := SDL_GetWindowID(window.ptr);
        tryAdd(*windowMap, .{ id = windowID, window = window });
    }

    state.events = .{};
    evt: SDL_Event = ---;
    while SDL_PollEvent(*evt) {
        if evt.type == .SDL_QUIT {
            count := state.windows.num;
            for i: 0..(count - 1) {
                if !tryAdd(*state.windowsToBeClosed, xx i) {
                    logError("Window Subsystem", "Failed to add window to windowsToBeClosed buffer");
                }
            }
        } else if evt.type == .SDL_WINDOWEVENT {
            if evt.window.event == .SDL_WINDOWEVENT_CLOSE {
                windowStateMapKVP, _ := search(*windowMap, *evt.window.windowID, (wsm, id) => (<<id) == wsm.id);
                if windowStateMapKVP {
                    if !tryAdd(*state.windowsToBeClosed, windowStateMapKVP.window.idx) {
                        logError("Window Subsystem", "Failed to add window to windowsToBeClosed buffer");
                    }
                }
            } else if evt.window.event == .SDL_WINDOWEVENT_RESIZED {
                windowStateMapKVP, _ := search(*windowMap, *evt.window.windowID, (wsm, id) => (<<id) == wsm.id);
                if windowStateMapKVP {
                    if !tryAdd(*state.resizedWindows, windowStateMapKVP.window.idx) {
                        logError("Window Subsystem", "Failed to add window to resizedWindows buffer");
                    }
                }
            }
        } else if evt.type == .SDL_KEYUP {
            if evt.key.keysym.sym == .SDLK_ESCAPE {
                windowStateMapKVP, _ := search(*windowMap, *evt.window.windowID, (wsm, id) => (<<id) == wsm.id);
                if windowStateMapKVP {
                    if !tryAdd(*state.windowsToBeClosed, windowStateMapKVP.window.idx) {
                        logError("Window Subsystem", "Failed to add window to windowsToBeClosed buffer");
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

destroyClosedWindows :: (state: *WindowSubsystemState) {
    for i: 0..(state.windowsToBeClosed.num - 1) {
        windowIdx := <<access(*state.windowsToBeClosed, i);
        window := access(*state.windows, windowIdx);
        SDL_DestroyWindow(window.ptr);
        window.valid = false;
        window.ptr = null;
    }

    state.windowsToBeClosed = .{};

    WindowRemapMapKVP :: struct {
        src, dst: u32;
    }

    windowMap: FixedSizeBuffer(WindowRemapMapKVP, state.windows.buffer.count);

    // remove invalid windows
    for i: 0..(state.windows.num - 1) {
        if state.windows.num == 0 {
            break;
        }

        window := access(*state.windows, i);
        if !window.valid {
            tryEraseSwapBack(*state.windows, i);
            i -= 1;
            continue;
        }

        tryAdd(*windowMap, .{ src = window.idx, dst = xx i });
    }

    // udpate the window indices
    for i: 0..(state.windows.num - 1) {
        window := access(*state.windows, i);
        kvp, _ := search(*windowMap, *window.idx, (wmmPtr, idxPtr) => (<<idxPtr) == wmmPtr.src);
        window.idx = kvp.dst;
    }

    for i: 0..(state.createdWindows.num - 1) {
        windowIdx := <<access(*state.createdWindows, i);
        kvp, _ := search(*windowMap, *windowIdx, (wmmPtr, idxPtr) => (<<idxPtr) == wmmPtr.src);
        access(*state.windows, windowIdx).idx = kvp.dst;
    }
}

#scope_file

logSDLError :: () {
    strLen :: (s: *u8) -> s32 {
        count: s32 = 0;
        while <<s {
            count += 1;
            s += 1;
        }

        return count;
    }

    errData := SDL_GetError();
    errCount := strLen(errData);
    err := string.{ data = errData, count = errCount };
    if err != "" {
        logError("Window Subsystem", "SDL Error: %.\n", err);
    }
}
