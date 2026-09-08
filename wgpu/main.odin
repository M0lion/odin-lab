package main

import "base:builtin"
import "base:runtime"
import "core:c"
import "core:log"
import "core:math"
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
MAP_WIDTH :: 150
MAP_HEIGHT :: 150
GameState :: struct {
	playerPos: [2]int,
	level:     [MAP_WIDTH][MAP_HEIGHT]MazeTile,
	camera:    g.Camera,
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

updateCamera :: proc(gs: ^GameState, screen: [2]f32) {
	pos := [2]f32{f32(gs.playerPos.x), f32(gs.playerPos.y)}

	mapSizeInScreen := g.worldToScreenVec(&gs.camera, screen, [2]f32{MAP_WIDTH, MAP_HEIGHT})
	screenInWorld := g.screenToWorldVec(&gs.camera, screen, screen)

	min := screenInWorld / 2
	max := screenInWorld - min

	log.debug("Camera update", gs.camera.position)
	log.debug("Player", pos)
	log.debug("screen", screen)
	log.debug("Min", min)
	log.debug("Max", max)
	log.debug("screen in world", screenInWorld)
	log.debug("world in screen", mapSizeInScreen)


	if screen.x > mapSizeInScreen.x {
		pos.x = MAP_WIDTH / 2
		log.debug("middle x")
	} else {
		pos.x = math.clamp(pos.x, min.x, max.x)
	}
	if screen.y > mapSizeInScreen.y {
		pos.y = MAP_HEIGHT / 2
		log.debug("middle y")
	} else {
		pos.y = math.clamp(pos.y, min.y, max.y)
	}

	log.debug("Camera pos", pos)

	gs.camera.position = pos
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

	gameState.camera = g.CreateCamera(gc, [2]f32{0, 0}, 20)

	start := time.tick_now()
	tickCooldown: f32 = 0
	dt: f32
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		if action, ok := Input.?; ok {
			Input = nil
			if updateGameState(&gameState, action) {
				tickCooldown = TICK_COOLDOWN
				updateCamera(
					&gameState,
					[2]f32 {
						f32(gc.surfaceConfiguration.width),
						f32(gc.surfaceConfiguration.height),
					},
				)
			}
		}

		// camera.rotation = animation.timer(dt / 4) * math.PI * 2
		g.UpdateCamera(&gameState.camera, gc)
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

				g.DrawRectangle(
					gc,
					&[4]f32{f32(x) - 0.5, f32(y) - 0.5, 1, 1},
					&color,
					&gameState.camera,
				)
			}
		}

		// Draw player
		g.DrawRectangle(
			gc,
			&[4]f32{f32(gameState.playerPos.x) - 0.4, f32(gameState.playerPos.y) - 0.4, 0.8, 0.8},
			&[4]f32{0, 0, 0, 1},
			&gameState.camera,
		)

		dt = f32(time.duration_seconds(time.tick_since(start)))
		tickCooldown = math.max(0, tickCooldown - dt)
		start = time.tick_now()
	}
}
