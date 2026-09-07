package main

import "base:runtime"
import "core:c"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:time"
import g "graphics"
import "vendor:glfw"

Action :: union {
	Direction,
}

KeyBindings: map[int]Action
Input: Maybe(Action) = nil

defaultContext: runtime.Context

TICK_COOLDOWN :: 0.5
MAP_WIDTH :: 15
MAP_HEIGHT :: 15
GameState :: struct {
	playerPos: [2]int,
	level:     [MAP_WIDTH][MAP_HEIGHT]MazeTile,
}

keyCallback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: c.int) {
	context = defaultContext
	log.debug("Key", key, scancode, action, mods)
	if action == 0 do return
	boundAction, ok := KeyBindings[int(key)]
	if !ok do return
	if Input == nil do Input = boundAction
}

initKeybindings :: proc() {
	KeyBindings[glfw.KEY_W] = .North
	KeyBindings[glfw.KEY_D] = .East
	KeyBindings[glfw.KEY_S] = .South
	KeyBindings[glfw.KEY_A] = .West
	KeyBindings[glfw.KEY_UP] = .North
	KeyBindings[glfw.KEY_RIGHT] = .East
	KeyBindings[glfw.KEY_DOWN] = .South
	KeyBindings[glfw.KEY_LEFT] = .West
}

updateGameState :: proc(gameState: ^GameState, action: Action) -> bool {
	log.debug("Action", action)
	switch a in action {
	case Direction:
		targetPos := gameState.playerPos + directionToVec(a)
		targetTile := getTile(&gameState.level, targetPos) or_return
		if targetTile^ == .Floor {
			gameState.playerPos = targetPos
			return true
		}
	}
	return false
}

main :: proc() {
	context.logger = log.create_console_logger(lowest = .Debug)
	defaultContext = context
	initKeybindings()
	glfw.Init()
	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	window := glfw.CreateWindow(500, 500, "WGPU", nil, nil)

	gc := g.CreateGraphicsContext(window)
	defer g.DestroyGraphicsContext(gc)

	gameState := GameState {
		playerPos = [2]int{1, 1},
	}

	createMaze(&gameState.level)

	glfw.SetKeyCallback(window, keyCallback)

	camera := g.CreateCamera(gc, [2]f32{7.5, 7.5}, 20)

	start := time.tick_now()
	tickCooldown: f32 = 0
	dt: f32
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		if action, ok := Input.?; ok {
			Input = nil
			if updateGameState(&gameState, action) {
				tickCooldown = TICK_COOLDOWN
			}
		}

		// camera.rotation = animation.timer(dt / 4) * math.PI * 2
		g.UpdateCamera(&camera, gc)
		g.BeginRenderPass(gc, window) or_continue
		defer g.EndRenderPass(gc)

		// Draw map
		for row, x in gameState.level {
			for tile, y in row {
				color: [4]f32
				switch tile {
				case .Floor:
					color = [4]f32{1, 1, 1, 1}
				case .Wall:
					color = [4]f32{0, 0, 0, 1}
				}

				g.DrawRectangle(gc, &[4]f32{f32(x) - 0.5, f32(y) - 0.5, 1, 1}, &color, &camera)
			}
		}

		// Draw player
		g.DrawRectangle(
			gc,
			&[4]f32{f32(gameState.playerPos.x) - 0.4, f32(gameState.playerPos.y) - 0.4, 0.8, 0.8},
			&[4]f32{0, 0, 0, 1},
			&camera,
		)

		dt = f32(time.duration_seconds(time.tick_since(start)))
		tickCooldown = math.max(0, tickCooldown - dt)
		start = time.tick_now()
	}
}
