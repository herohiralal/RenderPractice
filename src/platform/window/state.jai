WindowSubsystemState :: struct {
    valid: bool;
    handleIterator: u64;
    requirements: FixedSizeBuffer(WindowRequirement, 16);
    numRequirements: u32;
    events: FixedSizeBuffer(WindowEvent, 64);
    windows: FixedSizeBuffer(WindowState, 16);
    createdWindows: FixedSizeBuffer(u32, 16);
    resizedWindows: FixedSizeBuffer(u32, 16);
    windowsToBeClosed: FixedSizeBuffer(u32, 16);
}

WindowRequirement :: struct {
    title: *u8;
    width, height: s32;
}

WindowState :: struct {
    handle: u64;
    valid: bool;
    idx: u32;
    ptr: *void;
}

WindowEventType :: enum u8 { }

WindowEvent :: union {
    type: WindowEventType;
    // placeholderEvt: WindowPlaceHolderEvt;
}

// WindowPlaceHolderEvt :: struct {
//     type: WindowEventType;
//     // more fields...
// }
