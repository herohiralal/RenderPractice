LogLevel :: enum {
    INFO;
    WARNING;
    ERROR;
}

log :: (cat: string, lvl: LogLevel, fmtStr: string, args: ..Any, loc := #caller_location) {
    fgColor: s32;
    if lvl == {
    case .INFO;
        fgColor = 36;
    case .WARNING;
        fgColor = 33;
    case .ERROR;
        fgColor = 31;
    }

    print("\e[%m", fgColor);

    {
        catMaxLen :: 12;

        if cat.count <= catMaxLen {
            print("[%] ", cat);

            for i: 1..(catMaxLen - cat.count) {
                print(" ");
            }
        } else {
            cat2 := cat;
            cat2.count = catMaxLen;
            print("[%] ", cat2);
        }
    }

    print(fmtStr, ..args);
    print("\e[2;3;37m    [at %:%:%]\e[0m\n", loc.fully_pathed_filename, loc.line_number, loc.character_number);
}

log :: (cat: string, fmtStr: string, args: ..Any, loc := #caller_location) {
    log(cat, .INFO, fmtStr, ..args, loc = loc);
}

logWarning :: (cat: string, fmtStr: string, args: ..Any, loc := #caller_location) {
    log(cat, .WARNING, fmtStr, ..args, loc = loc);
}

logError :: (cat: string, fmtStr: string, args: ..Any, loc := #caller_location) {
    log(cat, .ERROR, fmtStr, ..args, loc = loc);
}

#scope_file
#import "Basic";
