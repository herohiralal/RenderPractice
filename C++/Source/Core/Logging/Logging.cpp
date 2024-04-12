#include "Logging.h"

#include <iostream>

LOG_CATEGORY(Default)

void Debug::Log(const char* message) { Log<LogDefault>(LogLevel::Info, message); }

void Debug::Log(const LogLevel level, const char* message) { Log<LogDefault>(level, message); }

void Debug::Log(const char* category, const LogLevel level, const char* message)
{
    char* levelStr;
    switch (level)
    {
        case LogLevel::Info:    levelStr = "LOG"; break;
        case LogLevel::Warning: levelStr = "WRN"; break;
        case LogLevel::Error:   levelStr = "ERR"; break;
        default:                levelStr = "___"; break;
    }

    int fgColor;
    switch (level)
    {
        case LogLevel::Info:    fgColor = 39; break;  // Default
        case LogLevel::Warning: fgColor = 33; break;  // Yellow
        case LogLevel::Error:   fgColor = 31; break;  // Red
        default:                fgColor = 39; break;                 // Default
    }

    std::cerr << "\033[" << fgColor << "m" << "[" << levelStr << "] " << "[" << category << "] " << message << std::endl
              << "\033[39m";
}
