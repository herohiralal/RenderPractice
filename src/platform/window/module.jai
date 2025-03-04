SubsystemState :: state.SubsystemState;
createSubsystem :: procs.createSubsystem;
destroySubsystem :: procs.destroySubsystem;
createNewWindows :: procs.createNewWindows;
pollWindowEvents :: procs.pollWindowEvents;
destroyClosedWindows :: procs.destroyClosedWindows;

#scope_file
state :: #import,file "state.jai";
procs :: #import,file "procedures.jai";
