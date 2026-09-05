package main

import "animation"
import "core:fmt"
import "core:log"
import "core:math"
import "core:time"
import g "graphics"
import "vendor:glfw"

main :: proc() {
	context.logger = log.create_console_logger()
	log.info("Info")
	glfw.Init()
	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	window := glfw.CreateWindow(500, 500, "WGPU", nil, nil)

	gc := g.CreateGraphicsContext(window)
	defer g.DestroyGraphicsContext(gc)

	camera := g.CreateCamera(gc, [2]f32{0, 0}, 2)


	start := time.tick_now()
	dt: f32
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		g.UpdateCamera(&camera, gc)
		g.BeginRenderPass(gc, window) or_continue
		defer g.EndRenderPass(gc)

		g.DrawRectangle(gc, &[4]f32{-0.5, animation.timer(dt), 0, 1}, &[4]f32{1, 0, 1, 1}, &camera)

		dt = f32(time.duration_seconds(time.tick_since(start)))
		start = time.tick_now()
	}
}
