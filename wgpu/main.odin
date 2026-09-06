package main

import "animation"
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

	maze := [15][15]MazeTile{}
	createMaze(&maze)
	log.debug(maze)

	camera := g.CreateCamera(gc, [2]f32{7.5, 7.5}, 20)

	start := time.tick_now()
	dt: f32
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		camera.rotation = animation.timer(dt / 4) * math.PI * 2
		g.UpdateCamera(&camera, gc)
		g.BeginRenderPass(gc, window) or_continue
		defer g.EndRenderPass(gc)

		for row, x in maze {
			for tile, y in row {
				color: [4]f32
				switch tile {
				case .Floor:
					color = [4]f32{1, 1, 1, 1}
				case .Wall:
					color = [4]f32{0, 0, 0, 1}
				}

				g.DrawRectangle(gc, &[4]f32{f32(x), f32(y), 1, 1}, &color, &camera)
			}
		}

		dt = f32(time.duration_seconds(time.tick_since(start)))
		start = time.tick_now()
	}
}
