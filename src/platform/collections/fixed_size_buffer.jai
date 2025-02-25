FixedSizeBuffer :: struct(T: Type, N: u64) {
    buffer: [N]T;
    num: s64;
}

access :: (buffer: *FixedSizeBuffer($T, $N), index: s64) -> *T {
    return *(buffer.buffer[index]);
}

tryInsertAt :: (buffer: *FixedSizeBuffer($T, $N), index: s64, value: T) -> bool {
    if buffer.num + 1 > xx N || index < 0 || index > buffer.num {
        return false;
    }

    for #v2 < i: (index+1)..buffer.num {
        buffer.buffer[i] = buffer.buffer[i - 1];
    }

    buffer.buffer[index] = value;
    buffer.num += 1;
    return true;
}

tryRemoveAt :: (buffer: *FixedSizeBuffer($T, $N), index: s64, num: u64) -> bool {
    if index < 0 || index > buffer.num || index + num > buffer.num {
        return false;
    }

    for i: index..(buffer.num - num - 1) {
        buffer.buffer[i] = buffer.buffer[i + num];
    }

    buffer.num -= num;
    return true;
}

tryRemoveAt :: (buffer: *FixedSizeBuffer($T, $N), index: s64) -> bool {
    return tryRemoveMultipleItemsAt(buffer, index, 1);
}

tryEraseSwapBack :: (buffer: *FixedSizeBuffer($T, $N), index: s64) -> bool {
    if index < 0 || index >= buffer.num {
        return false;
    }

    buffer.num -= 1;
    buffer.buffer[index] = buffer.buffer[buffer.num];
    return true;
}

tryAdd :: (buffer: *FixedSizeBuffer($T, $N), value: T) -> bool {
    return tryInsertAt(buffer, buffer.num, value);
}

search :: (
    buffer: *FixedSizeBuffer($T, $N),
    payload: *$TPayload,
    query: (*T, *TPayload) -> bool
) -> *T, s64 {
    for i: 0..(buffer.num - 1) {
        item: *T = *(buffer.buffer[i]);
        if query(item, payload) {
            return item, i;
        }
    }

    return null, -1;
}

search :: (
    buffer: *FixedSizeBuffer($T, $N),
    query: (*T) -> bool
) -> *T, s64 {
    for i: 0..(buffer.num - 1) {
        item: *T = *(buffer.buffer[i]);
        if query(item) {
            return item, i;
        }
    }

    return null, -1;
}
