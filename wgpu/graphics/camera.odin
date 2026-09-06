package graphics

import "core:math/linalg"
import "vendor:wgpu"
Camera :: struct {
	buffer:    wgpu.Buffer,
	bindGroup: wgpu.BindGroup,
	position:  [2]f32,
	width:     f32,
	rotation:  f32,
}

CreateCamera :: proc(
	gc: ^GraphicsContext,
	position: [2]f32,
	width: f32,
	rotation: f32 = 0,
) -> Camera {
	device := gc.device
	camera: Camera = {
		rotation = rotation,
		width    = width,
		position = position,
	}
	camera.buffer = wgpu.DeviceCreateBuffer(
		device,
		&wgpu.BufferDescriptor {
			label = "camera",
			usage = {.Uniform, .CopyDst},
			size  = size_of(matrix[4, 4]f32), // 64 bytes, already a multiple of 16
		},
	)
	camera.bindGroup = wgpu.DeviceCreateBindGroup(
		device,
		&{
			layout = GetCameraBindGroupLayout(gc),
			entryCount = 1,
			entries = raw_data(
				[]wgpu.BindGroupEntry {
					{
						binding = 0,
						buffer = camera.buffer,
						offset = 0,
						size = size_of(matrix[4, 4]f32),
					},
				},
			),
		},
	)

	return camera
}

@(private = "file")
camera_2d :: proc(wdith: f32, aspect: f32, center: [2]f32) -> matrix[4, 4]f32 {
	S := linalg.matrix4_scale_f32({2 / wdith, 2 * aspect / wdith, 1})
	T := linalg.matrix4_translate_f32({-center.x, -center.y, 0})
	return S * T
}

UpdateCamera :: proc(camera: ^Camera, gc: ^GraphicsContext) {
	transform := camera_2d(camera.width, f32(gc.width) / f32(gc.height), camera.position)
	transform *= linalg.matrix4_rotate_f32(camera.rotation, [3]f32{0, 0, 1})
	wgpu.QueueWriteBuffer(gc.queue, camera.buffer, 0, &transform, size_of(transform))
}

UseCamera :: proc(rp: wgpu.RenderPassEncoder, camera: ^Camera) {
	wgpu.RenderPassEncoderSetBindGroup(rp, 0, camera.bindGroup)
}

@(private)
GetCameraBindGroupLayout :: proc(gc: ^GraphicsContext) -> wgpu.BindGroupLayout {
	@(static) bgl: wgpu.BindGroupLayout

	if bgl == nil {
		device := gc.device
		bgld := wgpu.BindGroupLayoutDescriptor {
			label      = "camera bgld",
			entryCount = 1,
			entries    = raw_data(
				[]wgpu.BindGroupLayoutEntry {
					{
						binding = 0,
						visibility = {.Vertex}, // matches @group(0) @binding(0), used in the vertex stage
						buffer = {type = .Uniform, minBindingSize = size_of(matrix[4, 4]f32)},
					},
				},
			),
		}
		bgl = wgpu.DeviceCreateBindGroupLayout(device, &bgld)
	}
	return bgl
}
