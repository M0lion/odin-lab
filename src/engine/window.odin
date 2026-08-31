package engine

import "core:log"
import "core:strings"
import "vendor:sdl3"
import "vendor:sdl3/ttf"

Window :: struct {
	internal:   WindowInternal,
	shouldQuit: bool,
	size:       [2]f32,
}

@(private)
WindowInternal :: struct {
	sdlWindow:  ^sdl3.Window,
	renderer:   ^sdl3.Renderer,
	textEngine: ^ttf.TextEngine,
}

UpdateWindow :: proc(window: ^Window) {
	event: sdl3.Event
	for sdl3.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			window.shouldQuit = true
		case .KEY_DOWN:
			switch event.key.key {
			case sdl3.K_W:
			//viewport.y -= 5
			case sdl3.K_S:
			//viewport.y += 5
			}
		}
	}

	w, h: i32
	if !sdl3.GetWindowSize(window.internal.sdlWindow, &w, &h) {
		log.error("Could not get window size: ", sdl3.GetError())
	} else {
		window.size.x = f32(w)
		window.size.y = f32(h)
	}

	renderer := window.internal.renderer
	sdl3.SetRenderDrawColor(renderer, 255, 0, 255, 255)
	sdl3.RenderClear(renderer)
	sdl3.SetRenderDrawColor(renderer, 255, 255, 255, 255)
}

PresentWindow :: proc(window: ^Window) {
	renderer := window.internal.renderer
	sdl3.RenderPresent(renderer)
}

CreateWindow :: proc(title: string, width: i32, height: i32) -> (Window, bool) {
	if !sdl3.InitSubSystem({.VIDEO}) {
		err := sdl3.GetError()
		log.error("Failed to init sdl: ", err)
		return {}, false
	}

	// Init ttf
	if !ttf.Init() {
		log.error("Failed to init ttf: ", sdl3.GetError())
		return {}, false
	}

	internal := WindowInternal{}

	// Init Window
	title := strings.clone_to_cstring(title)
	internal.sdlWindow = sdl3.CreateWindow(title, width, height, {})
	delete(title)
	if internal.sdlWindow == nil {
		err := sdl3.GetError()
		log.error("Failed to create sdl window: ", err)
		return {}, false
	}

	// Init renderer
	internal.renderer = sdl3.CreateRenderer(internal.sdlWindow, nil)
	if internal.renderer == nil {
		log.error("Failed to init renderer: ", sdl3.GetError())
		return {}, false
	}

	// Init text engine
	internal.textEngine = ttf.CreateRendererTextEngine(internal.renderer)
	if internal.textEngine == nil {
		log.error("Failed to init text engine: ", sdl3.GetError())
		return {}, false
	}

	return Window{internal, false, [2]f32{f32(width), f32(height)}}, true
}

DestroyWindow :: proc(window: ^Window) {
	sdl3.DestroyRenderer(window.internal.renderer)
	sdl3.DestroyWindow(window.internal.sdlWindow)
	ttf.Quit()
	sdl3.QuitSubSystem({.VIDEO})
}

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
