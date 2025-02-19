package rhi_vulkan

import "../debug"
import "core:fmt"
import os "core:os/os2"
import "core:strings"

compileShader :: proc(name: string) -> (vert: []byte, frag: []byte) {
    srcBacking: [1024]byte = ---
    srcBuilder := strings.builder_from_bytes(srcBacking[:])

    dstBacking: [1024]byte = ---
    dstBuilder := strings.builder_from_bytes(dstBacking[:])

    vertShdName := fmt.sbprintf(&srcBuilder, "src/shaders/%s/exec.vert", name)
    vertSpvName := fmt.sbprintf(&dstBuilder, "build/%s.vert.spv", name)
    vertCmd := [?]string{"glslc", vertShdName, "-o", vertSpvName}
    state, stdout, stderr, err := os.process_exec({command = vertCmd[:]}, context.allocator)

    logLevel := debug.LogLevel.INFO
    if state.exit_code != 0 {
        logLevel = debug.LogLevel.ERROR
    }
    debug.log("VulkanRenderer", logLevel, "Shader compilation STDOUT: %s", string(stdout))
    debug.log("VulkanRenderer", logLevel, "Shader compilation STDERR: %s", string(stderr))

    vert, err = os.read_entire_file(vertSpvName, context.allocator)

    strings.builder_reset(&srcBuilder)
    strings.builder_reset(&dstBuilder)

    fragShdName := fmt.sbprintf(&srcBuilder, "src/shaders/%s/exec.frag", name)
    fragSpvName := fmt.sbprintf(&dstBuilder, "build/%s.frag.spv", name)
    fragCmd := [?]string{"glslc", fragShdName, "-o", fragSpvName}
    state, stdout, stderr, err = os.process_exec({command = fragCmd[:]}, context.allocator)

    logLevel = debug.LogLevel.INFO
    if state.exit_code != 0 {
        logLevel = debug.LogLevel.ERROR
    }
    debug.log("VulkanRenderer", logLevel, "Shader compilation STDOUT: %s", string(stdout))
    debug.log("VulkanRenderer", logLevel, "Shader compilation STDERR: %s", string(stderr))

    frag, err = os.read_entire_file(fragSpvName, context.allocator)

    return
}
