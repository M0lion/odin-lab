package main

import "core:log"
import "vendor:sdl3"

main :: proc() {
	context.logger = log.create_console_logger()

	if !sdl3.Init({.VIDEO}) {
		log.error("Failed to init sdl")
	}

	window := sdl3.CreateWindow("Odin window", 800, 600, {})
	renderer := sdl3.CreateRenderer(window, nil)

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
			case sdl3.EventType.KEY_DOWN:
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
		sdl3.RenderPresent(renderer)
	}
}
