package collections

FixedSizeBuffer :: struct($T: typeid, $SIZE: u64) {
    count:  u64,
    buffer: [SIZE]T,
}

getCapacity :: proc(buffer: ^$T/FixedSizeBuffer) -> u64 {
    return T.SIZE
}

getCount :: proc(buffer: ^$T/FixedSizeBuffer) -> u64 {
    return buffer.count
}

setCount :: proc(buffer: ^$T/FixedSizeBuffer, value: u64) {
    buffer.count = value
}

clear :: proc(buffer: ^$T/FixedSizeBuffer) {
    buffer.count = 0
}

access :: proc(buffer: ^$T/FixedSizeBuffer($T2, $N), index: u64) -> ^T2 {
    return &buffer.buffer[index]
}

tryInsertAt :: proc(buffer: ^$T/FixedSizeBuffer, index: u64, value: $T2) -> bool {
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

tryRemoveAt :: proc(buffer: ^$T/FixedSizeBuffer, index: u64, num: u64) -> bool {
    if index < 0 || index > buffer.count || index + num > buffer.count {
        return false
    }

    for i := index; i < buffer.count - num; i += 1 {
        buffer.buffer[i] = buffer.buffer[i + num]
    }

    buffer.count -= num
    return true
}

tryEraseSwapBack :: proc(buffer: ^$T/FixedSizeBuffer, index: u64) -> bool {
    if index < 0 || index >= buffer.count {
        return false
    }

    buffer.count -= 1
    buffer.buffer[index] = buffer.buffer[buffer.count]
    return true
}

tryAdd :: proc(buffer: ^$T/FixedSizeBuffer, value: $T2) -> bool {
    return tryInsertAt(buffer, buffer.count, value)
}
