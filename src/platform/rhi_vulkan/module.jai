SubsystemState :: state.SubsystemState;
createSubsystem :: procs.createSubsystem;
destroySubsystem :: procs.destroySubsystem;
updateSubsystem :: procs.updateSubsystem;

#scope_file
state :: #import,file "state.jai";
procs :: #import,file "procedures.jai";
winLt :: #import,file "window_lifetime.jai";
errs :: #import,file "errors.jai";
shdc :: #import,file "shader_compiler.jai";
