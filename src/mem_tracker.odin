package main

import "base:runtime"
import "core:mem"
import "core:sync"

import "platform/debug"

MemTrackingState :: struct {
    defaultAllocator:  mem.Allocator,
    trackingAllocator: mem.Tracking_Allocator,
}

initMemTracker :: proc(state: ^MemTrackingState, backing := context.allocator) -> runtime.Allocator {
    when ODIN_DEBUG {
        state.defaultAllocator = backing
        mem.tracking_allocator_init(&state.trackingAllocator, state.defaultAllocator, state.defaultAllocator)
        return mem.tracking_allocator(&state.trackingAllocator)
    } else {
        state.defaultAllocator = backing
        return backing
    }
}

destroyMemTracker :: proc(state: ^MemTrackingState) -> runtime.Allocator {
    when ODIN_DEBUG {
        {
            sync.mutex_lock(&state.trackingAllocator.mutex)
            defer sync.mutex_unlock(&state.trackingAllocator.mutex)

            for _, leak in state.trackingAllocator.allocation_map {
                debug.log("Mem", debug.LogLevel.ERROR, "Memory leak detected: %m bytes at %v.", leak.size, leak.location)
            }

            for badFree in state.trackingAllocator.bad_free_array {
                debug.log("Mem", debug.LogLevel.ERROR, "Bad free detected: %p at %v.", badFree.memory, badFree.location)
            }
        }

        mem.tracking_allocator_clear(&state.trackingAllocator)
        mem.tracking_allocator_destroy(&state.trackingAllocator)
    }

    return state.defaultAllocator
}
