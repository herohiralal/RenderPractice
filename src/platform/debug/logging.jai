LogLevel :: enum {
    INFO;
    WARNING;
    ERROR;
}

log :: (cat: string, lvl: LogLevel, fmtStr: string, args: ..Any) {
    fgColor: s32;
    if lvl == {
    case .INFO;
        fgColor = 39;
    case .WARNING;
        fgColor = 33;
    case .ERROR;
        fgColor = 31;
    }

    print("\e[1;%m", fgColor);
    defer print("\e[0;39m");

    {
        lvlStr: string;

        if lvl == {
        case .INFO;
            lvlStr = "LOG";
        case .WARNING;
            lvlStr = "WRN";
        case .ERROR;
            lvlStr = "ERR";
        case;
            lvlStr = "???";
        }

        print("[%] ", lvlStr);
    }

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
    print("\n");
}

log :: (cat: string, fmtStr: string, args: ..Any) {
    log(cat, .INFO, fmtStr, ..args);
}

logWarning :: (cat: string, fmtStr: string, args: ..Any) {
    log(cat, .WARNING, fmtStr, ..args);
}

logError :: (cat: string, fmtStr: string, args: ..Any) {
    log(cat, .ERROR, fmtStr, ..args);
}
