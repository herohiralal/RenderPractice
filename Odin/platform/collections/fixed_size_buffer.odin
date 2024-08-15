package collections

FixedSizeBuffer :: struct($T: typeid, $SIZE: u64) {
    count:  u64,
    buffer: [SIZE]T,
}

get_capacity :: proc(buffer: ^$T/FixedSizeBuffer) -> u64 {
    return T.SIZE
}

get_count :: proc(buffer: ^$T/FixedSizeBuffer) -> u64 {
    return buffer.count
}

set_count :: proc(buffer: ^$T/FixedSizeBuffer, value: u64) {
    buffer.count = value
}

clear :: proc(buffer: ^$T/FixedSizeBuffer) {
    buffer.count = 0
}

access :: proc(buffer: ^$T/FixedSizeBuffer($T2, $N), index: u64) -> ^T2 {
    return &buffer.buffer[index]
}

try_insert_at :: proc(buffer: ^$T/FixedSizeBuffer, index: u64, value: $T2) -> bool {
    if buffer.count + 1 > T.SIZE || index < 0 || index > buffer.count {
        return false
    }

    for i := buffer.count; i >= index + 1; i -= 1 {
        buffer.buffer[i] = buffer.buffer[i - 1]
    }

    buffer.buffer[index] = value
    buffer.count += 1
    return true
}

try_remove_at :: proc(buffer: ^$T/FixedSizeBuffer, index: u64, num: u64) -> bool {
    if index < 0 || index > buffer.count || index + num > buffer.count {
        return false
    }

    for i := index; i < buffer.count - num; i += 1 {
        buffer.buffer[i] = buffer.buffer[i + num]
    }

    buffer.count -= num
    return true
}

try_erase_swap_back :: proc(buffer: ^$T/FixedSizeBuffer, index: u64) -> bool {
    if index < 0 || index >= buffer.count {
        return false
    }

    buffer.count -= 1
    buffer.buffer[index] = buffer.buffer[buffer.count]
    return true
}

try_add :: proc(buffer: ^$T/FixedSizeBuffer, value: $T2) -> bool {
    return try_insert_at(buffer, buffer.count, value)
}
