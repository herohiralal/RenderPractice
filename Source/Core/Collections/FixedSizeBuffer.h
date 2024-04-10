#pragma once

#include <cstdint>

template <typename T>
struct FixedSizeBufferHandle
{
    FixedSizeBufferHandle() : Count(0), Capacity(0), InternalBuffer(nullptr) {}

private:
    std::uint64_t Count;
    std::uint64_t Capacity;
    T*            InternalBuffer;

public:
    std::uint64_t GetCapacity() const { return Capacity; }

    void SetCapacity(const std::uint64_t Value) { Capacity = Value; }

    std::uint64_t GetCount() const { return Count; }

    void SetCount(const std::uint64_t Value) { Count = Value; }

    T* GetBuffer() { return InternalBuffer; }

    void SetBuffer(T* const Value) { InternalBuffer = Value; }

    const T& operator[](std::uint64_t Idx) const { return &InternalBuffer[Idx]; }

    T& operator[](std::uint64_t Idx) { return &InternalBuffer[Idx]; }

    void Clear() { Count = 0; }

    struct FIndexOption
    {
    private:
        const bool     bSuccess;
        const T* const Value;

    public:
        FIndexOption(const bool bInSuccess, const T* const InValue) : bSuccess(bInSuccess), Value(InValue) {}

        operator bool() const { return bSuccess; }

        const T& GetValue() const { return *Value; }
    };

    FIndexOption TryGetItem(const std::uint64_t Idx) const
    {
        if (Idx < 0 || Idx >= Count) return FIndexOption(false, nullptr);
        return FIndexOption(true, &InternalBuffer[Idx]);
    }

    bool TrySetItem(const std::uint64_t Idx, const T& Value)
    {
        if (Idx < 0 || Idx >= Count) return false;
        InternalBuffer[Idx] = Value;
        return true;
    }

    bool TryInsertAt(const T& Input, const std::uint64_t Idx)
    {
        if (Count + 1 > Capacity || Idx < 0 || Idx > Count) return false;
        for (std::uint64_t I = Count; I >= Idx + 1; --I) InternalBuffer[I] = InternalBuffer[I - 1];
        InternalBuffer[Idx] = Input;
        Count++;
        return true;
    }

    bool TryInsertAt(const FixedSizeBufferHandle& Input, const std::uint64_t Idx)
    {
        if (Count + Input.GetCount() > Capacity || Idx < 0 || Idx > Count) return false;
        for (std::uint64_t I = Count + Input.GetCount() - 1; I >= Idx + Input.GetCount(); --I)
            InternalBuffer[I] = InternalBuffer[I - Input.GetCount()];
        for (std::uint64_t I = 0; I < Input.GetCount(); I++) InternalBuffer[Idx + 1] = Input[I];
        Count += Input.GetCount();
        return true;
    }

    bool TryRemoveFrom(const std::uint64_t Idx, const std::uint64_t Num)
    {
        if (Idx < 0 || Idx > Count || Idx + Num > Count) return false;
        for (std::uint64_t I = Idx; I < Count - Num; ++I) InternalBuffer[I] = InternalBuffer[I + Num];
        Count -= Num;
        return true;
    }

    bool TryAdd(const T& Input) { return TryInsertAt(Input, Count); }

    bool TryEraseSwapBack(const std::uint64_t Idx)
    {
        if (Idx < 0 || Idx >= Count) return false;
        InternalBuffer[Idx] = InternalBuffer[--Count];
        return true;
    }
};

template <typename T, std::uint64_t Capacity>
struct FixedSizeBuffer
{
    constexpr FixedSizeBuffer() : Count(0) {}

private:
    std::uint64_t Count;
    T             InternalBuffer[Capacity];

public:
    std::uint64_t GetCapacity() const { return Capacity; }

    std::uint64_t GetCount() const { return Count; }

    void SetCount(std::uint64_t Value) { Count = Value; }

    T* GetBuffer() { return &InternalBuffer[0]; }

    const T& operator[](std::uint64_t Idx) const { return InternalBuffer[Idx]; }

    T& operator[](std::uint64_t Idx) { return InternalBuffer[Idx]; }

    void Clear() { Count = 0; }

    FixedSizeBufferHandle<T> ToHandle()
    {
        FixedSizeBufferHandle<T> Output;
        Output.SetCapacity(Capacity);
        Output.SetCount(Count);
        Output.SetBuffer(GetBuffer());
        return Output;
    }

    struct FIndexOption
    {
    private:
        const bool     bSuccess;
        const T* const Value;

    public:
        FIndexOption(const bool bInSuccess, const T* const InValue) : bSuccess(bInSuccess), Value(InValue) {}

        operator bool() const { return bSuccess; }

        const T& GetValue() const { return *Value; }
    };

    FIndexOption TryGetItem(const std::uint64_t Idx) const
    {
        if (Idx < 0 || Idx >= Count) return FIndexOption(false, nullptr);
        return FIndexOption(true, &InternalBuffer[Idx]);
    }

    bool TrySetItem(const std::uint64_t Idx, const T& Value)
    {
        if (Idx < 0 || Idx >= Count) return false;
        InternalBuffer[Idx] = Value;
        return true;
    }

    bool TryInsertAt(const T& Input, const std::uint64_t Idx)
    {
        if (Count + 1 > Capacity || Idx < 0 || Idx > Count) return false;
        for (std::uint64_t I = Count; I >= Idx + 1; --I) InternalBuffer[I] = InternalBuffer[I - 1];
        InternalBuffer[Idx] = Input;
        Count++;
        return true;
    }

    template <typename T2, std::uint64_t OtherCapacity>
    bool TryInsertAt(const FixedSizeBuffer<T2, OtherCapacity>& Input, const std::uint64_t Idx)
    {
        if (Count + Input.GetCount() > Capacity || Idx < 0 || Idx > Count) return false;
        for (std::uint64_t I = Count + Input.GetCount() - 1; I >= Idx + Input.GetCount(); --I)
            InternalBuffer[I] = InternalBuffer[I - Input.GetCount()];
        for (std::uint64_t I = 0; I < Input.GetCount(); I++) InternalBuffer[Idx + 1] = Input[I];
        Count += Input.GetCount();
        return true;
    }

    bool TryRemoveFrom(const std::uint64_t Idx, const std::uint64_t Num)
    {
        if (Idx < 0 || Idx > Count || Idx + Num > Count) return false;
        for (std::uint64_t I = Idx; I < Count - Num; ++I) InternalBuffer[I] = InternalBuffer[I + Num];
        Count -= Num;
        return true;
    }

    bool TryAdd(const T& Input) { return TryInsertAt(Input, Count); }

    bool TryEraseSwapBack(const std::uint64_t Idx)
    {
        if (Idx < 0 || Idx >= Count) return false;
        InternalBuffer[Idx] = InternalBuffer[--Count];
        return true;
    }
};
