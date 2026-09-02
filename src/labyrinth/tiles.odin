package labyrinth

import e "../engine"

Tile :: enum {
	Wall,
	Floor,
}

DrawTiles :: proc(window: ^e.Window, tiles: [$W][$H]Tile, rootPos: [2]f32) {
	for row, y in tiles {
		for tile, x in row {
			rect := [4]f32{rootPos.x + f32(x), rootPos.y + f32(y), 1, 1}
			switch tile {
			case .Wall:
				e.DrawRect(window, rect, [4]f32{0, 0, 0, 1})
			case .Floor:
				e.DrawRect(window, rect, [4]f32{1, 1, 1, 1})
			}
		}
	}
}
