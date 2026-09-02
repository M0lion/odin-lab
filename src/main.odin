package main

import "core:flags"
import "core:log"
import "core:os"
import "labyrinth"

Vector2 :: [2]f32

Programs :: enum {
	labyrinth,
	brownian,
}

Options :: struct {
	program: Programs `args:"name=Program"usage:"Program to run"`,
}

main :: proc() {
	context.logger = log.create_console_logger()
	opts: Options
	flags.parse_or_exit(&opts, os.args, .Odin)

	switch opts.program {
	case .labyrinth:
		if !labyrinth.run() {
			log.error("App crashed")
			os.exit(1)
		}
	case .brownian:
		if !brownianMewb() {
			log.error("App crashed")
			os.exit(1)
		}
	}
}
