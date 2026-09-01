package main

import "core:log"
import "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:time"
import e "engine"

count :: 10

main :: proc() {
	context.logger = log.create_console_logger()

	if !run() {
		log.error("App crashed")
		os.exit(1)
	}
}

Vector2 :: [2]f32

run :: proc() -> bool {
	window := e.CreateWindow("Test", 600, 500) or_return
	w := &window
	physics := e.CreatePhysics()
	p := &physics

	e.CreateBoundingBox(p, [4]f32{0, 0, 600, 500})

	running := true

	font := e.CreateFont(w, "assets/HackNerdFontMono-Regular.ttf", 50) or_return
	text := e.CreateText(&font, "MEWB") or_return

	boxes := [count]e.Body{}
	for &box in boxes {
		box = e.CreateRectangle(p, [2]f32{rand.float32(), rand.float32()} * 300, text.size, 0)
	}

	positions := [count]Vector2{}
	for &pos in positions {
		pos = [2]f32{rand.float32(), rand.float32()} * 300
	}

	directions := [count]Vector2{}
	for &dir in directions {
		dir = linalg.normalize([2]f32{rand.float32(), rand.float32()})
	}

	lastUpdate := time.now()

	white: [4]f32 = 1
	black: [4]f32 = 0
	black.a = 1

	counter := 0

	start := time.now()
	for !w.shouldQuit {
		e.UpdateWindow(w)

		if counter % 30 > 14 {
			e.SetTextColor(&text, white)
		} else {
			e.SetTextColor(&text, black)
		}

		for &pos, i in positions {
			dir := &directions[i]
			pos += dir^
			if pos.x + text.size.x > w.size.x || pos.x < 0 do dir.x *= -1
			if pos.y + text.size.y > w.size.y || pos.y < 0 do dir.y *= -1
			//e.RenderText(&text, pos)
		}

		for box in boxes {
			pos := e.GetBodyPos(box)
			e.RenderText(&text, pos)
		}

		e.PresentWindow(w)

		time.sleep((time.Second / 60))

		counter += 1
		e.StepPhysics(p)
	}

	log.info(time.since(start))

	return true
}
