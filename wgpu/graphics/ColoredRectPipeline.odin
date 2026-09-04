#+private
package graphics

import "core:log"
import "vendor:wgpu"

shader :: #load("./ColoredRectangle.wgsl", string)

ColoredRectanglePipeline :: struct {
	shader:         wgpu.ShaderModule,
	pipelineLayout: wgpu.PipelineLayout,
	pipeline:       wgpu.RenderPipeline,
}

RectPC :: struct {
	pos: [4]f32,
}

DrawColoredRectangle :: proc(gc: ^GraphicsContext, rect: ^FRect, color: ^Color) {
	rp, ok := gc.activeRenderPass.?
	if !ok {
		log.error("Tried to draw rectangle with no active render pass")
		return
	}
	wgpu.RenderPassEncoderSetPipeline(rp.renderPassEncoder, gc.coloredRectanglePipeline.pipeline)
	wgpu.RenderPassEncoderSetImmediates(
		rp.renderPassEncoder,
		0, // offset
		&RectPC{[4]f32{rect.x, rect.y, 0, 0}}, // data
		size_of(RectPC), // size
	)
	wgpu.RenderPassEncoderDraw(rp.renderPassEncoder, 4, 1, 0, 0)
}

CreateColoredRectanglePipeline :: proc(gc: ^GraphicsContext) -> ColoredRectanglePipeline {
	pipe := ColoredRectanglePipeline{}

	pipe.shader = CreateShader(gc.device, string(shader))

	layout := wgpu.PipelineLayoutDescriptor {
		immediateSize = size_of(RectPC),
	}
	pipe.pipelineLayout = wgpu.DeviceCreatePipelineLayout(gc.device, &layout)
	pipe.pipeline = wgpu.DeviceCreateRenderPipeline(
		gc.device,
		&{
			layout = pipe.pipelineLayout,
			vertex = {module = pipe.shader, entryPoint = "vs_main"},
			fragment = &{
				module      = pipe.shader,
				entryPoint  = "fs_main",
				targetCount = 1,
				targets     = &wgpu.ColorTargetState {
					format    = gc.surfaceConfiguration.format, // TODO: Figure out if needs to be the same
					writeMask = wgpu.ColorWriteMaskFlags_All,
				},
			},
			primitive = {topology = .TriangleStrip},
			multisample = {count = 1, mask = 0xFFFFFFFF},
		},
	)

	return pipe
}

DestroyColoredRectanglePipeline :: proc(pipe: ^ColoredRectanglePipeline) {
	wgpu.RenderPipelineRelease(pipe.pipeline)
	wgpu.PipelineLayoutRelease(pipe.pipelineLayout)
	DestroyShader(pipe.shader)
}
