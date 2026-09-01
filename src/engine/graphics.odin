package engine

import "core:log"
import "vendor:sdl3"

Surface :: sdl3.Surface

GetSurface :: proc(size: [2]i32) -> ^Surface {
	return sdl3.CreateSurface(size.x, size.y, .RGBA4444)
}

DestroySurface :: proc(surface: ^Surface) {
	sdl3.DestroySurface(surface)
}

Texture :: sdl3.Texture

GetTextureFromSurface :: proc(window: ^Window, surface: ^Surface) -> ^Texture {
	return sdl3.CreateTextureFromSurface(window.internal.renderer, surface)
}

DestroyTexture :: proc(texture: ^Texture) {
	sdl3.DestroyTexture(texture)
}

DrawTexture :: proc(
	window: ^Window,
	texture: ^Texture,
	position: ^[2]f32,
	scale: f32,
	angle: f32,
) {
	size: [2]f32
	sdl3.GetTextureSize(texture, &size.x, &size.y)
	size *= scale
	destRect := sdl3.FRect {
		x = position.x,
		y = position.y,
		w = size.x,
		h = size.y,
	}
	sdl3.RenderTextureRotated(
		window.internal.renderer,
		texture,
		nil,
		&destRect,
		f64(angle),
		nil,
		.NONE,
	)
}
