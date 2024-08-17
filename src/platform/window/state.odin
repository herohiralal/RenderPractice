package window

import "../collections"

SubsystemState :: struct {
    valid:        b8,
    success:      b8,
    requirements: WindowRequirementBuffer,
    events:       WindowEventBuffer,
    windows:      WindowStateBuffer,
}

WindowRequirementBuffer :: struct {
    buffer: collections.FixedSizeBuffer(WindowRequirement, 16),
}

WindowEventBuffer :: struct {
    buffer: collections.FixedSizeBuffer(WindowEvent, 64),
}

WindowStateBuffer :: struct {
    buffer: collections.FixedSizeBuffer(WindowState, 16),
}

WindowRequirement :: struct {
    title:  string,
    width:  i32,
    height: i32,
}

WindowEvent :: struct #raw_union {
    type:  WindowEventType,
    close: struct {
        type:      WindowEventType,
        windowIdx: u32,
    },
}

WindowState :: struct {
    valid: b8,
    idx:   u32,
    ptr:   rawptr,
}

WindowEventType :: enum u8 {
    Close,
}
