package window

import "../collections"

SubsystemState :: struct {
    valid:             b8,
    handleIterator:    u64,
    requirements:      WindowRequirementBuffer,
    events:            WindowEventBuffer,
    windows:           WindowStateBuffer,
    createdWindows:    WindowIndexBuffer,
    resizedWindows:    WindowIndexBuffer,
    windowsToBeClosed: WindowIndexBuffer,
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

WindowIndexBuffer :: struct {
    buffer: collections.FixedSizeBuffer(u32, 16),
}

WindowRequirement :: struct {
    title:  string,
    width:  i32,
    height: i32,
}

WindowEvent :: struct #raw_union {
    type: WindowEventType,
    // placeholderEvt: WindowPlaceHolderEvt,
}

WindowState :: struct {
    handle: u64,
    valid:  b8,
    idx:    u32,
    ptr:    rawptr,
}

WindowEventType :: enum u8 {}
// WindowPlaceHolderEvt :: struct {
//     type: WindowEventType,
//     // more fields...
// }
