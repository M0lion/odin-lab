package main

import "core:log"
import "core:os"

main :: proc() {
	context.logger = log.create_console_logger()

	if !brownianMewb() {
		log.error("App crashed")
		os.exit(1)
	}
}

Vector2 :: [2]f32
