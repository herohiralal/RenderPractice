package rhi_vulkan

import "../debug"
import "core:fmt"
import os "core:os/os2"
import "core:strings"
import "core:time"
import vk "vendor:vulkan"

compileShader :: proc(device: vk.Device, name: string) -> Shader {
    vert, frag := getShaderData(name)
    defer {
        delete(vert, context.temp_allocator)
        delete(frag, context.temp_allocator)
    }

    vertShader: vk.ShaderModule = ---
    checkResult(
        vk.CreateShaderModule(
            device,
            &vk.ShaderModuleCreateInfo {
                sType = .SHADER_MODULE_CREATE_INFO,
                pNext = nil,
                flags = {},
                codeSize = len(vert),
                pCode = (^u32)(raw_data(vert)),
            },
            nil,
            &vertShader,
        ),
        "CreateShaderModule",
    )

    fragShader: vk.ShaderModule = ---
    checkResult(
        vk.CreateShaderModule(
            device,
            &vk.ShaderModuleCreateInfo {
                sType = .SHADER_MODULE_CREATE_INFO,
                pNext = nil,
                flags = {},
                codeSize = len(frag),
                pCode = (^u32)(raw_data(frag)),
            },
            nil,
            &fragShader,
        ),
        "CreateShaderModule",
    )

    pipelineLayoutCreateInfo := vk.PipelineLayoutCreateInfo {
        sType                  = .PIPELINE_LAYOUT_CREATE_INFO,
        pNext                  = nil,
        flags                  = {},
        setLayoutCount         = 0,
        pSetLayouts            = nil,
        pushConstantRangeCount = 0,
        pPushConstantRanges    = nil,
    }

    pipelineLayout: vk.PipelineLayout = ---
    checkResult(vk.CreatePipelineLayout(device, &pipelineLayoutCreateInfo, nil, &pipelineLayout), "CreatePipelineLayout")

    return Shader{vs = u64(vertShader), fs = u64(fragShader), layout = u64(pipelineLayout)}
}

clearShader :: proc(device: vk.Device, shd: ^Shader) {
    if shd != nil {
        pipelineLayout := vk.PipelineLayout(shd.layout)
        vk.DestroyPipelineLayout(device, pipelineLayout, nil)

        vertShader := vk.ShaderModule(shd.vs)
        vk.DestroyShaderModule(device, vertShader, nil)

        fragShader := vk.ShaderModule(shd.fs)
        vk.DestroyShaderModule(device, fragShader, nil)

        shd.layout = 0
        shd.vs = 0
        shd.fs = 0
    }
}

@(private = "file")
getShaderData :: proc(name: string) -> (vert: []byte, frag: []byte) {
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
            state, stdout, stderr, err := os.process_exec({command = vertCmd[:]}, context.temp_allocator)

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
        vert, err = os.read_entire_file(vertSpvName, context.temp_allocator)
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
            state, stdout, stderr, err := os.process_exec({command = fragCmd[:]}, context.temp_allocator)

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
        frag, err = os.read_entire_file(fragSpvName, context.temp_allocator)
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
