package window

import "../collections"

EventType :: enum u8 {
    Close,
}

Event :: struct #raw_union {
    type:  EventType,
    close: struct {
        type:     EventType,
        windowId: u32,
    },
}

EventBuffer :: struct {
    buffer: collections.FixedSizeBuffer(Event, 64),
}

Requirement :: struct {
    title:  string,
    width:  i32,
    height: i32,
}

RequirementBuffer :: struct {
    buffer: collections.FixedSizeBuffer(Requirement, 16),
}

State :: struct {
    valid: b8,
    ptr:   rawptr,
}

StateBuffer :: struct {
    buffer: collections.FixedSizeBuffer(State, 16),
}

SubsystemState :: struct {
    valid:   b8,
    success: b8,
    events:  EventBuffer,
    windows: StateBuffer,
}
