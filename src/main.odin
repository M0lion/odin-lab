package main

import "core:log"
import "core:os"
import "core:time"
import e "engine"

main :: proc() {
	context.logger = log.create_console_logger()

	if !run() {
		log.error("App crashed")
		os.exit(1)
	}
}

run :: proc() -> bool {
	window := e.CreateWindow("Test", 600, 500) or_return
	w := &window

	running := true

	font := e.CreateFont(w, "assets/HackNerdFontMono-Regular.ttf", 50) or_return
	text := e.CreateText(&font, "MEWB") or_return

	pos := [2]f32{30, 30}

	dir := [2]f32{5, 5}

	lastUpdate := time.now()

	white: [4]f32 = 1
	black: [4]f32 = 0
	black.a = 1

	counter := 0

	start := time.now()
	for !w.shouldQuit {
		e.UpdateWindow(w)

		pos += dir
		if pos.x + text.size.x > w.size.x || pos.x < 0 do dir.x *= -1
		if pos.y + text.size.y > w.size.y || pos.y < 0 do dir.y *= -1

		if counter % 30 > 14 {
			e.SetTextColor(&text, white)
		} else {
			e.SetTextColor(&text, black)
		}
		e.RenderText(&text, pos)


		e.PresentWindow(w)

		time.sleep((time.Second / 60))

		counter += 1
	}

	log.info(time.since(start))

	return true
}
