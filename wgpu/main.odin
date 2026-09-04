package main

import "core:fmt"
import "core:log"
import "core:time"
import g "graphics"
import "vendor:glfw"
import "vendor:wgpu"

main :: proc() {
	context.logger = log.create_console_logger()
	log.info("Info")
	glfw.Init()
	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	window := glfw.CreateWindow(500, 500, "WGPU", nil, nil)

	gc := g.CreateGraphicsContext(window)
	defer g.DestroyGraphicsContext(gc)

	start := time.tick_now()
	dt: f32
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		g.BeginRenderPass(gc, window) or_continue
		defer g.EndRenderPass(gc)

		g.DrawRectangle(gc, &[4]f32{-0.5, 0, 1, 1}, &[4]f32{1, 0, 1, 1})

		dt = f32(time.duration_seconds(time.tick_since(start)))
	}
}
