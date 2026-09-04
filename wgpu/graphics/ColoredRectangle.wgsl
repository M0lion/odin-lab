struct Rect {
	rect: vec4<f32>,
};
// @group(0) @binding(0) var<uniform> rect: Rect;

var<immediate> rect: Rect;

const QUAD = array<vec2f, 4>(
	vec2f(0,  0.0),  // Botton left
	vec2f(1,  0.0),  // Bottom right
	vec2f(0, 1),  // Top left
	vec2f(1, 1),   // Top right
);

@vertex
fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4<f32> {
	let xy = QUAD[in_vertex_index] + rect.rect.xy;
	return vec4<f32>(xy, 0.0, 1.0);
}

@fragment
fn fs_main() -> @location(0) vec4<f32> {
	return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}
