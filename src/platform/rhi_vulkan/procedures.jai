vk :: #import "Vulkan";

createVulkanSubsystem :: () -> VulkanSubsystemState { return .{}; }

destroyVulkanSubsystem :: (state: *VulkanSubsystemState) { }

updateVulkanSubsystem :: (windowState: *WindowSubsystemState, state: *VulkanSubsystemState) { }