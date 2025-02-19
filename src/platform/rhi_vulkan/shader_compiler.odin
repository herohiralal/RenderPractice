package rhi_vulkan

import "../debug"
import "core:fmt"
import os "core:os/os2"
import "core:strings"
import "core:time"

compileShader :: proc(name: string) -> (vert: []byte, frag: []byte) {
    srcBacking: [1024]byte = ---
    srcBuilder := strings.builder_from_bytes(srcBacking[:])

    dstBacking: [1024]byte = ---
    dstBuilder := strings.builder_from_bytes(dstBacking[:])

    vertShdName := fmt.sbprintf(&srcBuilder, "src/shaders/%s/exec.vert", name)
    if os.exists(vertShdName) {
        vertSpvName := fmt.sbprintf(&dstBuilder, "build/%s.vert.spv", name)
        shouldProcess := true
        {
            vertShdInf, vShStInfErr := os.stat(vertShdName, context.temp_allocator)
            defer os.file_info_delete(vertShdInf, context.temp_allocator)

            if os.exists(vertSpvName) {
                vertSpvInf, vSpStInfErr := os.stat(vertSpvName, context.temp_allocator)
                defer os.file_info_delete(vertSpvInf, context.temp_allocator)
                if vShStInfErr == nil && vSpStInfErr == nil {
                    if vertShdInf.modification_time._nsec < vertSpvInf.modification_time._nsec {
                        shouldProcess = false
                    }
                }
            }
        }

        if shouldProcess {
            debug.log("VulkanRenderer", debug.LogLevel.INFO, "Compiling vertex shader: %s", vertShdName)
            vertCmd := [?]string{"glslc", vertShdName, "-o", vertSpvName}
            state, stdout, stderr, err := os.process_exec({command = vertCmd[:]}, context.allocator)

            logLevel := debug.LogLevel.INFO
            if state.exit_code != 0 {
                logLevel = debug.LogLevel.ERROR
            }
            if len(stdout) > 0 {
                debug.log("VulkanRenderer", logLevel, "Shader compilation STDOUT: %s", string(stdout))
            }
            if len(stderr) > 0 {
                debug.log("VulkanRenderer", logLevel, "Shader compilation STDERR: %s", string(stderr))
            }
        }

        err: os.Error = ---
        vert, err = os.read_entire_file(vertSpvName, context.allocator)
        if err != nil {
            vert = nil
            debug.log("VulkanRenderer", debug.LogLevel.ERROR, "Failed to read vertex shader file: %s", vertSpvName)
        }
    } else {
        vert = nil
        debug.log("VulkanRenderer", debug.LogLevel.ERROR, "Vertex shader file not found: %s", vertShdName)
    }

    strings.builder_reset(&srcBuilder)
    strings.builder_reset(&dstBuilder)

    fragShdName := fmt.sbprintf(&srcBuilder, "src/shaders/%s/exec.frag", name)
    if os.exists(fragShdName) {

        fragSpvName := fmt.sbprintf(&dstBuilder, "build/%s.frag.spv", name)
        shouldProcess := true
        {
            fragShdInf, fShStInfErr := os.stat(fragShdName, context.temp_allocator)
            defer os.file_info_delete(fragShdInf, context.temp_allocator)

            if os.exists(fragSpvName) {
                fragSpvInf, fSpStInfErr := os.stat(fragSpvName, context.temp_allocator)
                defer os.file_info_delete(fragSpvInf, context.temp_allocator)
                if fShStInfErr == nil && fSpStInfErr == nil {
                    if fragShdInf.modification_time._nsec < fragSpvInf.modification_time._nsec {
                        shouldProcess = false
                    }
                }
            }
        }

        if shouldProcess {
            debug.log("VulkanRenderer", debug.LogLevel.INFO, "Compiling fragment shader: %s", fragShdName)
            fragCmd := [?]string{"glslc", fragShdName, "-o", fragSpvName}
            state, stdout, stderr, err := os.process_exec({command = fragCmd[:]}, context.allocator)

            logLevel := debug.LogLevel.INFO
            if state.exit_code != 0 {
                logLevel = debug.LogLevel.ERROR
            }
            if len(stdout) > 0 {
                debug.log("VulkanRenderer", logLevel, "Shader compilation STDOUT: %s", string(stdout))
            }
            if len(stderr) > 0 {
                debug.log("VulkanRenderer", logLevel, "Shader compilation STDERR: %s", string(stderr))
            }
        }

        err: os.Error = ---
        frag, err = os.read_entire_file(fragSpvName, context.allocator)
        if err != nil {
            frag = nil
            debug.log("VulkanRenderer", debug.LogLevel.ERROR, "Failed to read fragment shader file: %s", fragSpvName)
        }
    } else {
        frag = nil
        debug.log("VulkanRenderer", debug.LogLevel.ERROR, "Fragment shader file not found: %s", fragShdName)
    }

    return
}
