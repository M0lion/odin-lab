package main

import "core:fmt"
import "core:log"
import "core:time"
import g "graphics"
import "vendor:glfw"
import "vendor:wgpu"

main :: proc() {
	context.logger = log.create_console_logger()
	glfw.Init()
	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	window := glfw.CreateWindow(500, 500, "WGPU", nil, nil)

	gc := g.CreateGraphicsContext(window)
	defer g.DestroyGraphicsContext(gc)

	start := time.tick_now()
	dt: f32
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		surfaceTexture := wgpu.SurfaceGetCurrentTexture(gc.surface)
		switch surfaceTexture.status {
		case .SuccessOptimal, .SuccessSuboptimal:
		// All good, could handle suboptimal here.
		case .Timeout, .Outdated, .Lost:
			// Skip this frame, and re-configure surface.
			if surfaceTexture.texture != nil {
				wgpu.TextureRelease(surfaceTexture.texture)
			}
			width, height := glfw.GetFramebufferSize(window)
			gc.surfaceConfiguration.width = u32(width)
			gc.surfaceConfiguration.height = u32(height)
			wgpu.SurfaceConfigure(gc.surface, &gc.surfaceConfiguration)
			return
		case .Occluded:
			// Window is occluded (e.g. minimized), skip this frame.
			return
		case .Error:
			// Fatal error
			fmt.panicf("[triangle] get_current_texture status=%v", surfaceTexture.status)
		}
		defer wgpu.TextureRelease(surfaceTexture.texture)

		frame := wgpu.TextureCreateView(surfaceTexture.texture, nil)
		defer wgpu.TextureViewRelease(frame)

		commandEncoder := wgpu.DeviceCreateCommandEncoder(gc.device, nil)
		defer wgpu.CommandEncoderRelease(commandEncoder)

		renderPassEncoder := wgpu.CommandEncoderBeginRenderPass(
			commandEncoder,
			&{
				colorAttachmentCount = 1,
				colorAttachments = &wgpu.RenderPassColorAttachment {
					view = frame,
					loadOp = .Clear,
					storeOp = .Store,
					depthSlice = wgpu.DEPTH_SLICE_UNDEFINED,
					clearValue = {0, 1, 0, 1},
				},
			},
		)

		wgpu.RenderPassEncoderSetPipeline(renderPassEncoder, gc.pipeline)
		wgpu.RenderPassEncoderDraw(renderPassEncoder, 3, 1, 0, 0)

		wgpu.RenderPassEncoderEnd(renderPassEncoder)
		wgpu.RenderPassEncoderRelease(renderPassEncoder)

		commandBuffer := wgpu.CommandEncoderFinish(commandEncoder, nil)
		defer wgpu.CommandBufferRelease(commandBuffer)

		wgpu.QueueSubmit(gc.queue, {commandBuffer})
		wgpu.SurfacePresent(gc.surface)

		dt = f32(time.duration_seconds(time.tick_since(start)))
	}
}
