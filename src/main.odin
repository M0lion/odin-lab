package main

import "core:log"
import "core:math"
import "core:math/rand"
import "core:os"
import "core:time"
import e "engine"

count :: 30

main :: proc() {
	context.logger = log.create_console_logger()

	if !run() {
		log.error("App crashed")
		os.exit(1)
	}
}

Vector2 :: [2]f32

run :: proc() -> bool {
	window := e.CreateWindow("Test", 1000, 1000) or_return
	w := &window
	physics := e.CreatePhysics()
	p := &physics

	scale := 5 / w.size.x

	arenaSize := w.size * scale

	e.CreateBoundingBox(p, [4]f32{0, 0, arenaSize.x, arenaSize.y})

	running := true

	font := e.CreateFont(w, "assets/HackNerdFontMono-Regular.ttf", 50) or_return
	text := e.CreateText(&font, "MEWB") or_return

	white: [4]f32 = 1
	black: [4]f32 = 0
	black.a = 1
	e.SetTextColor(&text, black)
	textSurface := e.CreateSurfaceFromText(&font, "MEWB", black, white)
	textTexture := e.GetTextureFromSurface(w, textSurface)
	textSize := text.size * scale
	log.info("Text: ", text.size, textSize)

	boxes := [count]e.Body{}
	boxBound := arenaSize - textSize
	for &box in boxes {
		box = e.CreateRectangle(
			p,
			[2]f32{rand.float32(), rand.float32()} * boxBound / 10,
			textSize,
			0,
		)
	}

	lastUpdate := time.now()

	counter := 0

	start := time.now()

	e.SetWindowViewport(w, [4]f32{0, 0, arenaSize.x, arenaSize.y})
	for !w.shouldQuit {
		e.UpdateWindow(w)

		for box in boxes {
			pos := e.GetBodyPos(box) - (textSize / 2)
			angle := e.GetBodyAngle(box) * math.DEG_PER_RAD
			e.DrawTexture(&window, textTexture, &pos, scale, angle)
		}

		e.PresentWindow(w)

		time.sleep((time.Second / 60))

		counter += 1
		e.StepPhysics(p)
	}

	log.info(time.since(start))

	return true
}
