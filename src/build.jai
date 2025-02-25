#import "Compiler";

#run {
    defer set_build_options_dc(.{do_output=false});

    w := compiler_create_workspace();
    options := get_build_options(w);
    copy_commonly_propagated_fields(get_build_options(), *options);
    options.output_executable_name = "RenderPractice";
    options.output_path = "../bin";
    options.intermediate_path = "../temp";
    set_build_options(options, w);

    // collections
    add_build_file("platform/collections/fixed_size_buffer.jai", w);

    // logging
    add_build_file("platform/debug/logging.jai", w);

    // window
    add_build_file("platform/window/state.jai", w);
    add_build_file("platform/window/procedures.jai", w);

    // entry point
    add_build_file("app_state.jai", w);
    add_build_file("main.jai", w);
}
