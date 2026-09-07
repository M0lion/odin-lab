package main

import "base:intrinsics"
import "core:log"
import "core:math/rand"

MazeTile :: enum {
	Wall,
	Floor,
}

Direction :: enum {
	North,
	East,
	South,
	West,
}

directionToVec :: proc(direction: Direction) -> [2]int {
	switch direction {
	case .North:
		return [2]int{0, 1}
	case .East:
		return [2]int{1, 0}
	case .South:
		return [2]int{0, -1}
	case .West:
		return [2]int{-1, 0}
	}

	panic("Unknown location")
}

Directions :: bit_set[Direction]

MazeIndex :: struct {
	x, y: int,
}

getTile :: proc(maze: ^[$W][$H]MazeTile, pos: [2]int) -> (^MazeTile, bool) {
	if pos.x < 0 || pos.x >= W || pos.y < 0 || pos.y >= H do return {}, false

	return &maze[pos.x][pos.y], true
}

createMaze :: proc(maze: ^[$W][$H]MazeTile) {
	next := [dynamic][2]int{}

	append(&next, [2]int{1, 1})

	for len(next) > 0 {
		current := next[len(next) - 1]
		log.debug("Current: ", current)
		availableDirections := Directions{.North, .East, .South, .West}

		for direction in availableDirections {
			dVec := directionToVec(direction)
			log.debug("Dir: ", direction, dVec)
			tile, found := getTile(maze, current + dVec * 2)
			log.debug(tile, found)
			if !found || tile^ == .Floor {
				availableDirections -= {direction}
				continue
			}
		}

		log.debug("Available directions: ", availableDirections)

		dir, ok := rand.choice_bit_set(availableDirections)
		if !ok {
			log.debug("removing ", len(next) - 1)
			ordered_remove(&next, len(next) - 1)
			log.debug("Removed")
			if len(&next) == 0 do break
			continue
		}
		log.debug("Cohsen dir: ", dir)

		dVec := directionToVec(dir)
		if tile, ok := getTile(maze, current + dVec); ok {
			tile^ = .Floor
		}
		if tile, ok := getTile(maze, current + dVec * 2); ok {
			tile^ = .Floor
		}
		append(&next, current + dVec * 2)
	}
}
