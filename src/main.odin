package main

import "core:fmt"
import "core:log"
import "vendor:sdl3"

main :: proc() {
	fmt.println("Hello")
	context.logger = log.create_console_logger()

	a := Test {
		x = 5,
		y = 2,
	}

	TestProc(a)

	fmt.println("asd")

	if !sdl3.Init({.VIDEO}) {
		log.error("Failed to init sdl")
	}

	window := sdl3.CreateWindow("Odin window", 800, 600, {})
	renderer := sdl3.CreateRenderer(window, nil)

	running := true
	event: sdl3.Event

	for running {
		for sdl3.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				running = false
			}
		}

		sdl3.SetRenderDrawColor(renderer, 1, 0, 1, 1)
		sdl3.RenderClear(renderer)
		sdl3.RenderPresent(renderer)
	}
}

Test :: struct {
	x, y: int,
}

TestProc :: proc(test: Test) {
	log.info(test)
}
