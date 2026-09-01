package engine

import "core:log"
import "core:strings"
import "vendor:sdl3"
import "vendor:sdl3/ttf"

Font :: struct {
	sdlFont:    ^ttf.Font,
	textEngine: ^ttf.TextEngine,
}

CreateFont :: proc(window: ^Window, file: string, size: f32) -> (Font, bool) {
	file := strings.clone_to_cstring(file)
	font := ttf.OpenFont(file, size)
	if font == nil {
		log.error("Failed to open font: ", file, " With error: ", sdl3.GetError())
		return {}, false
	}

	return Font{sdlFont = font, textEngine = window.internal.textEngine}, true
}

DestroyFont :: proc(font: ^Font) {
	ttf.CloseFont(font.sdlFont)
}

Text :: struct {
	text:    string,
	size:    [2]f32,
	sdlText: ^ttf.Text,
	font:    ^Font,
}

CreateText :: proc(font: ^Font, text: string) -> (Text, bool) {
	cText := strings.clone_to_cstring(text)
	sdlText := ttf.CreateText(font.textEngine, font.sdlFont, cText, 0)
	delete(cText)

	if sdlText == nil {
		log.error("Failed to create text: ", sdl3.GetError())
		return {}, false
	}

	text := Text {
		sdlText = sdlText,
		text    = text,
	}
	w, h: i32
	if !ttf.GetTextSize(sdlText, &w, &h) {
		log.error("Failed to get text size: ", sdl3.GetError())
		return {}, false
	}
	text.size.x = f32(w)
	text.size.y = f32(h)

	return text, true
}

SetTextColor :: proc(text: ^Text, color: [4]f32) {
	ttf.SetTextColor(
		text.sdlText,
		u8(color.r * 255),
		u8(color.g * 255),
		u8(color.b * 255),
		u8(color.a * 255),
	)
}

DestroyText :: proc(text: ^Text) {
	ttf.DestroyText(text.sdlText)
}

RenderText :: proc(text: ^Text, pos: [2]f32) {
	if !ttf.DrawRendererText(text.sdlText, pos.x, pos.y) {
		log.error("Failed to draw text: ", sdl3.GetError())
	}
}

CreateSurfaceFromText :: proc(
	font: ^Font,
	text: string,
	color: [4]f32,
	background: [4]f32,
) -> ^Surface {
	text := strings.clone_to_cstring(text)
	defer delete(text)
	surface := ttf.RenderText_Shaded(
		font.sdlFont,
		text,
		0,
		{u8(color.r * 255), u8(color.g * 255), u8(color.b * 255), u8(color.a * 255)},
		{
			u8(background.r * 255),
			u8(background.g * 255),
			u8(background.b * 255),
			u8(background.a * 255),
		},
	)

	if surface == nil {
		log.error("Failed to draw text to surface: ", text, sdl3.GetError())
	}

	return surface
}
