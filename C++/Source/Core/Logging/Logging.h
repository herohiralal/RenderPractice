#pragma once

#include <cstdint>

#define LOG_CATEGORY(categoryName)                         \
    class Log##categoryName                                \
    {                                                      \
    public:                                                \
        static constexpr const char* Name = #categoryName; \
    };

enum class LogLevel : std::uint8_t
{
    Info,
    Warning,
    Error
};

class Debug
{
public:
    template <typename TCategory>
    static void Log(const char* message);

    template <typename TCategory>
    static void Log(const LogLevel level, const char* message);

    static void Log(const char* message);
    static void Log(const LogLevel level, const char* message);

private:
    static void Log(const char* category, const LogLevel level, const char* message);
};

template <typename TCategory>
inline void Debug::Log(const char* message)
{
    Log<TCategory>(LogLevel::Info, message);
}

template <typename TCategory>
inline void Debug::Log(const LogLevel level, const char* message)
{
    Log(TCategory::Name, level, message);
}
