

    shaderStageCreateInfos := [?]vk.PipelineShaderStageCreateInfo {
        {sType = .PIPELINE_SHADER_STAGE_CREATE_INFO, pName = "main", module = vertShader, stage = {.VERTEX}},
        {sType = .PIPELINE_SHADER_STAGE_CREATE_INFO, pName = "main", module = fragShader, stage = {.FRAGMENT}},
    }

    dynamicStates := [?]vk.DynamicState{.VIEWPORT, .SCISSOR}
    dynamicStateCreateInfo := vk.PipelineDynamicStateCreateInfo {
        sType             = .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        pNext             = nil,
        flags             = {},
        dynamicStateCount = len(dynamicStates),
        pDynamicStates    = raw_data(&dynamicStates),
    }

    vertexInputInfo := vk.PipelineVertexInputStateCreateInfo {
        sType                           = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        pNext                           = nil,
        flags                           = {},
        vertexBindingDescriptionCount   = 0,
        pVertexBindingDescriptions      = nil,
        vertexAttributeDescriptionCount = 0,
        pVertexAttributeDescriptions    = nil,
    }

    inputAssembly := vk.PipelineInputAssemblyStateCreateInfo {
        sType                  = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        pNext                  = nil,
        flags                  = {},
        topology               = .TRIANGLE_LIST,
        primitiveRestartEnable = false,
    }

    viewportState := vk.PipelineViewportStateCreateInfo {
        sType         = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        pNext         = nil,
        flags         = {},
        viewportCount = 1,
        pViewports    = &vk.Viewport{x = 0, y = 0, width = 8, height = 8, minDepth = 0, maxDepth = 1},
        scissorCount  = 1,
        pScissors     = &vk.Rect2D{offset = {x = 0, y = 0}, extent = {width = 8, height = 8}},
    }

    rasterizer := vk.PipelineRasterizationStateCreateInfo {
        sType                   = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        pNext                   = nil,
        flags                   = {},
        depthClampEnable        = false,
        rasterizerDiscardEnable = false,
        polygonMode             = .FILL,
        lineWidth               = 1.0,
        cullMode                = {.BACK},
        frontFace               = .CLOCKWISE,
        depthBiasEnable         = false,
        depthBiasConstantFactor = 0.0,
        depthBiasClamp          = 0.0,
        depthBiasSlopeFactor    = 0.0,
    }

    multisampling := vk.PipelineMultisampleStateCreateInfo {
        sType                 = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        pNext                 = nil,
        flags                 = {},
        rasterizationSamples  = {._1},
        sampleShadingEnable   = false,
        minSampleShading      = 1.0,
        pSampleMask           = nil,
        alphaToCoverageEnable = false,
        alphaToOneEnable      = false,
    }

    // depthStencil := vk.PipelineDepthStencilStateCreateInfo {
    //     sType                 = .PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
    //     pNext                 = nil,
    //     flags                 = {},
    //     depthTestEnable       = true,
    //     depthWriteEnable      = true,
    //     depthCompareOp        = .LESS,
    //     depthBoundsTestEnable = false,
    //     stencilTestEnable     = false,
    //     front                 = {},
    //     back                  = {},
    //     minDepthBounds        = 0.0,
    //     maxDepthBounds        = 1.0,
    // }

    colorBlending := vk.PipelineColorBlendStateCreateInfo {
        sType           = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        pNext           = nil,
        flags           = {},
        logicOpEnable   = false,
        logicOp         = .COPY,
        attachmentCount = 1,
        pAttachments    = &vk.PipelineColorBlendAttachmentState {
            colorWriteMask = {.R, .G, .B, .A},
            blendEnable = false,
            srcColorBlendFactor = .ONE,
            dstColorBlendFactor = .ZERO,
            colorBlendOp = .ADD,
            srcAlphaBlendFactor = .ONE,
            dstAlphaBlendFactor = .ZERO,
            alphaBlendOp = .ADD,
        },
        blendConstants  = {0, 0, 0, 0},
    }

    renderPassCreateInfo := vk.RenderPassCreateInfo {
        sType           = .RENDER_PASS_CREATE_INFO,
        pNext           = nil,
        flags           = {},
        attachmentCount = 1,
        pAttachments    = &vk.AttachmentDescription {
            format = .B8G8R8A8_UNORM,
            samples = {._1},
            loadOp = .CLEAR,
            storeOp = .STORE,
            stencilLoadOp = .DONT_CARE,
            stencilStoreOp = .DONT_CARE,
            initialLayout = .UNDEFINED,
            finalLayout = .PRESENT_SRC_KHR,
        },
        subpassCount    = 1,
        pSubpasses      = &vk.SubpassDescription {
            pipelineBindPoint = .GRAPHICS,
            colorAttachmentCount = 1,
            pColorAttachments = &vk.AttachmentReference{attachment = 0, layout = .COLOR_ATTACHMENT_OPTIMAL},
            pResolveAttachments = nil,
            pDepthStencilAttachment = nil,
            preserveAttachmentCount = 0,
            pPreserveAttachments = nil,
        },
        dependencyCount = 1,
        pDependencies   = &vk.SubpassDependency {
            srcSubpass = vk.SUBPASS_EXTERNAL,
            dstSubpass = 0,
            srcStageMask = {.COLOR_ATTACHMENT_OUTPUT},
            dstStageMask = {.COLOR_ATTACHMENT_OUTPUT},
            srcAccessMask = {},
            dstAccessMask = {.COLOR_ATTACHMENT_READ, .COLOR_ATTACHMENT_WRITE},
            dependencyFlags = {},
        },
    }

    gfxPipelineCreateInfo := vk.GraphicsPipelineCreateInfo {
        sType               = .GRAPHICS_PIPELINE_CREATE_INFO,
        pNext               = nil,
        flags               = {},
        stageCount          = len(shaderStageCreateInfos),
        pStages             = raw_data(&shaderStageCreateInfos),
        pVertexInputState   = &vertexInputInfo,
        pInputAssemblyState = &inputAssembly,
        pTessellationState  = nil,
        pViewportState      = &viewportState,
        pRasterizationState = &rasterizer,
        pMultisampleState   = &multisampling,
        pDepthStencilState  = nil,
        pColorBlendState    = &colorBlending,
        pDynamicState       = &dynamicStateCreateInfo,
        layout              = pipelineLayout,
        renderPass          = 0,
        subpass             = 0,
        basePipelineHandle  = 0,
        basePipelineIndex   = -1,
    }