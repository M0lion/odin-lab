package labyrinth

import e "../engine"

run :: proc() -> bool {
	window := e.CreateWindow("Labyrinth", 500, 500) or_return
	w := &window

	e.SetWindowViewport(w, [4]f32{0, 0, 4, 4})

	tiles := [4][4]Tile {
		[4]Tile{.Floor, .Floor, .Wall, .Floor},
		[4]Tile{.Floor, .Floor, .Wall, .Floor},
		[4]Tile{.Floor, .Wall, .Wall, .Floor},
		[4]Tile{.Floor, .Floor, .Floor, .Floor},
	}

	for !w.shouldQuit {
		e.UpdateWindow(w)

		DrawTiles(w, tiles, [2]f32{0, 0})

		e.PresentWindow(w)
	}

	return true
}
