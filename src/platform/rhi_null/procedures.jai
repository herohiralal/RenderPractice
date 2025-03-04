createSubsystem :: () -> SubsystemState { return .{}; }

destroySubsystem :: (state: *SubsystemState) { }

updateSubsystem :: (windowState: *window.SubsystemState, state: *SubsystemState) { }

#scope_file
#import,file "state.jai";
window :: #import "window";
