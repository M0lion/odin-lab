@group(0) @binding(0) var<uniform> camera: mat4x4f;

struct Rect {
	transform: mat4x4f,
	color: vec4f,
}

var<immediate> rect: Rect;

const QUAD = array<vec4f, 4>(
	vec4f(0, 0, 0, 1),  // Botton left
	vec4f(1, 0, 0, 1),  // Bottom right
	vec4f(0, 1, 0, 1),  // Top left
	vec4f(1, 1, 0, 1),   // Top right
);

@vertex
fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4<f32> {
	let pos = QUAD[in_vertex_index];
	return camera * rect.transform * pos;
}

@fragment
fn fs_main() -> @location(0) vec4<f32> {
	return rect.color;
}
