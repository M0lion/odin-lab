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
