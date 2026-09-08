package graphics

import "core:math/linalg"
import "vendor:wgpu"
Camera :: struct {
	buffer:    wgpu.Buffer,
	bindGroup: wgpu.BindGroup,
	position:  [2]f32,
	scale:     f32,
	rotation:  f32,
	scaleMode: ScaleMode,
}

ScaleMode :: enum {
	Width,
	Height,
	Auto,
}

CreateCamera :: proc(
	gc: ^GraphicsContext,
	position: [2]f32,
	scale: f32,
	rotation: f32 = 0,
	scaleMode: ScaleMode = .Auto,
) -> Camera {
	device := gc.device
	camera: Camera = {
		rotation  = rotation,
		scale     = scale,
		position  = position,
		scaleMode = scaleMode,
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
camera_2d :: proc(camera: ^Camera, screen: [2]f32) -> matrix[4, 4]f32 {
	scaleMode: ScaleMode = camera.scaleMode
	scale := camera.scale
	center := camera.position
	rotation := camera.rotation

	S: linalg.Matrix4x4f32
	if scaleMode == .Auto {
		if screen.x >= screen.y {
			scaleMode = .Height
		} else {
			scaleMode = .Width
		}
	}

	if scaleMode == .Width {
		S = linalg.matrix4_scale_f32({2 / scale, 2 * (screen.x / screen.y) / scale, 1})
	} else {
		S = linalg.matrix4_scale_f32({2 * (screen.y / screen.x) / scale, 2 / scale, 1})
	}

	T := linalg.matrix4_translate_f32({-center.x, -center.y, 0})

	R := linalg.matrix4_rotate_f32(rotation, [3]f32{0, 0, 1})
	return S * R * T
}

ndcToScreen :: proc(screen: [2]f32, p: [2]f32) -> [2]f32 {
	p := p
	p.y = -p.y
	return ((p + 1) * screen) / 2
}

screenToNdc :: proc(screen: [2]f32, p: [2]f32) -> [2]f32 {
	p := (2 * p / screen) - 1
	p.y = -p.y
	return p
}

worldToScreenPos :: proc(camera: ^Camera, screen: [2]f32, point: [2]f32) -> [2]f32 {
	point := [4]f32{point.x, point.y, 0, 1}
	point = camera_2d(camera, screen) * point
	s := (point.xy + 1) * screen / 2
	return s
}

worldToScreenVec :: proc(camera: ^Camera, screen: [2]f32, point: [2]f32) -> [2]f32 {
	point := [4]f32{point.x, point.y, 0, 0}
	point = camera_2d(camera, screen) * point
	s := point.xy * screen / 2
	return s
}

screenToWorldPos :: proc(camera: ^Camera, screen: [2]f32, point: [2]f32) -> [2]f32 {
	ndc := (2 * point / screen) - 1
	point := [4]f32{ndc.x, ndc.y, 0, 1}
	point = linalg.inverse(camera_2d(camera, screen)) * point
	return point.xy
}

screenToWorldVec :: proc(camera: ^Camera, screen: [2]f32, point: [2]f32) -> [2]f32 {
	ndc := (2 * point / screen)
	point := [4]f32{ndc.x, ndc.y, 0, 0}
	point = linalg.inverse(camera_2d(camera, screen)) * point
	return point.xy
}

UpdateCamera :: proc(camera: ^Camera, gc: ^GraphicsContext) {
	transform := camera_2d(
		camera,
		[2]f32{f32(gc.surfaceConfiguration.width), f32(gc.surfaceConfiguration.height)},
	)
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
