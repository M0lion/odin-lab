#+private
package graphics

import "core:log"
import "core:math"
import "core:math/linalg"
import "vendor:wgpu"

shader :: #load("./ColoredRectangle.wgsl", string)

ColoredRectanglePipeline :: struct {
	shader:         wgpu.ShaderModule,
	pipelineLayout: wgpu.PipelineLayout,
	pipeline:       wgpu.RenderPipeline,
}

RectPC :: struct {
	transform: matrix[4, 4]f32,
	color:     [4]f32,
}

DrawColoredRectangle :: proc(gc: ^GraphicsContext, rect: ^FRect, color: ^Color, camera: ^Camera) {
	rp, ok := gc.activeRenderPass.?
	if !ok {
		log.error("Tried to draw rectangle with no active render pass")
		return
	}
	transform := linalg.matrix4_translate_f32([3]f32{rect.x, rect.y, 0})
	rectData := RectPC {
		transform = transform,
		color     = color^,
	}
	UseCamera(rp.renderPassEncoder, camera)
	wgpu.RenderPassEncoderSetPipeline(rp.renderPassEncoder, gc.coloredRectanglePipeline.pipeline)
	wgpu.RenderPassEncoderSetImmediates(
		rp.renderPassEncoder,
		0, // offset
		&rectData, // data
		size_of(RectPC), // size
	)
	wgpu.RenderPassEncoderDraw(rp.renderPassEncoder, 4, 1, 0, 0)
}

CreateColoredRectanglePipeline :: proc(gc: ^GraphicsContext) -> ColoredRectanglePipeline {
	pipe := ColoredRectanglePipeline{}

	pipe.shader = CreateShader(gc.device, string(shader))

	cameraBGL := GetCameraBindGroupLayout(gc)
	layout := wgpu.PipelineLayoutDescriptor {
		immediateSize        = size_of(RectPC),
		bindGroupLayoutCount = 1,
		bindGroupLayouts     = &cameraBGL,
	}
	pipe.pipelineLayout = wgpu.DeviceCreatePipelineLayout(gc.device, &layout)
	pipe.pipeline = wgpu.DeviceCreateRenderPipeline(
		gc.device,
		&{
			label = "ColoredRectanglePipeline",
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
			multisample = {count = 4, mask = 0xFFFFFFFF, alphaToCoverageEnabled = false},
		},
	)

	return pipe
}

DestroyColoredRectanglePipeline :: proc(pipe: ^ColoredRectanglePipeline) {
	wgpu.RenderPipelineRelease(pipe.pipeline)
	wgpu.PipelineLayoutRelease(pipe.pipelineLayout)
	DestroyShader(pipe.shader)
}
