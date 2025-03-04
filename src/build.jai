#run {
    defer set_build_options_dc(.{do_output=false});

    w := compiler_create_workspace("[MAIN BUILD]");
    options := get_build_options(w);
    copy_commonly_propagated_fields(get_build_options(), *options);
    options.output_executable_name = "RenderPractice";
    options.output_path = "../bin";
    options.intermediate_path = "../temp";
    newImportPaths := NewArray(options.import_path.count + 1, string);
    newImportPaths[0] = "./platform/";
    for ip, i : options.import_path {
        newImportPaths[i+1] = ip;
    }
    options.import_path = newImportPaths;
    set_build_options(options, w);
    add_build_file("main.jai", w);
}

#scope_file

#import "Basic";
#import "Compiler";
