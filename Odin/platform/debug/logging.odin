package debug

import "core:fmt"
import "core:strings"
import "core:time"

LogLevel :: enum {
    INFO,
    WARNING,
    ERROR,
}

log_cat_lvl_msg :: proc(category: string, level: LogLevel, message: string) {

    // color - uses defer statement, don't put in a scope
    fgColor: i32
    switch level {
        case LogLevel.INFO:
            fgColor = 39 // Default color
        case LogLevel.WARNING:
            fgColor = 33 // Yellow
        case LogLevel.ERROR:
            fgColor = 31 // Red
    }

    fmt.printf("\033[%dm", fgColor)
    defer fmt.printf("\033[39m")

    // timestamp
    {
        timeNow := time.now()
        year, month, day := time.date(timeNow)
        hour, min, sec := time.clock_from_time(timeNow)
        fmt.printf("[%04d-%02d-%02d %02d:%02d:%02d] ", year, i32(month), day, hour, min, sec)
    }

    // log level
    {
        levelStr: string

        switch level {
            case LogLevel.INFO:
                levelStr = "LOG"
            case LogLevel.WARNING:
                levelStr = "WRN"
            case LogLevel.ERROR:
                levelStr = "ERR"
        }
        fmt.printf("[%s] ", levelStr)
    }

    // category
    {
        categoryMaxLength :: 12

        switch len(category) {
            case 0 ..< categoryMaxLength:
                fmt.printf("[%s] ", category)

                for i := len(category); i < categoryMaxLength; i += 1 {
                    fmt.printf(" ")
                }

            case categoryMaxLength:
                fmt.printf("[%s] ", category)

            case:
                truncatedCategory := strings.string_from_ptr(raw_data(category), min(len(category), categoryMaxLength))

                fmt.printf("[%s] ", truncatedCategory)
        }
    }

    fmt.printfln("%s", message)
}

log_cat_msg :: proc(category: string, message: string) {
    log_cat_lvl_msg(category, LogLevel.INFO, message)
}

log_lvl_msg :: proc(level: LogLevel, message: string) {
    log_cat_lvl_msg("Default", level, message)
}

log_msg :: proc(message: string) {
    log_cat_lvl_msg("Default", LogLevel.INFO, message)
}

log :: proc {
    log_cat_lvl_msg,
    log_cat_msg,
    log_lvl_msg,
    log_msg,
}
