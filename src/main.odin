package main

import "core:log"
import "vendor:sdl3"
import "vendor:sdl3/ttf"

main :: proc() {
	context.logger = log.create_console_logger()

	if !sdl3.Init({.VIDEO}) {
		log.error("Failed to init sdl: ", sdl3.GetError())
		return
	}

	if !ttf.Init() {
		log.error("Failed to init sdl3_ttf: ", sdl3.GetError())
		return
	}

	window := sdl3.CreateWindow("Odin window", 800, 600, {})
	renderer := sdl3.CreateRenderer(window, nil)

	font := ttf.OpenFont("/usr/share/fonts/TTF/HackNerdFontMono-Regular.ttf", 24)
	if font == nil {
		log.error("Failed to load font: ", sdl3.GetError())
		return
	}
	textEngine := ttf.CreateRendererTextEngine(renderer)

	text := ttf.CreateText(textEngine, font, "Hello", 0)
	ttf.SetTextColor(text, 255, 255, 0, 255)

	running := true
	event: sdl3.Event

	viewport := sdl3.Rect {
		x = 0,
		y = 0,
		w = 800,
		h = 600,
	}

	for running {
		for sdl3.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				running = false
			case .KEY_DOWN:
				switch event.key.key {
				case sdl3.K_W:
					viewport.y -= 5
				case sdl3.K_S:
					viewport.y += 5
				}
			}
		}

		sdl3.SetRenderViewport(renderer, &viewport)
		sdl3.SetRenderDrawColor(renderer, 255, 0, 255, 255)
		sdl3.RenderClear(renderer)
		sdl3.SetRenderDrawColor(renderer, 255, 255, 255, 255)
		sdl3.RenderFillRect(renderer, &sdl3.FRect{w = 50, h = 50, x = 50, y = 50})
		ttf.DrawRendererText(text, 50, 500)
		sdl3.RenderPresent(renderer)
	}
}
