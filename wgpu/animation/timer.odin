package animation

import "base:runtime"
import "core:log"

@(private = "file")
Timer :: struct {
	loc:  runtime.Source_Code_Location,
	time: f32,
}

timer :: proc(dt: f32, loc := #caller_location) -> f32 {
	@(static) timers: [dynamic]Timer

	for &t in timers {
		if t.loc == t.loc {
			t.time += dt
			log.info(t.time, dt)
			if t.time >= 1 {
				t.time -= 1
			}
			return t.time
		}
	}

	i, err := append(&timers, Timer{loc = loc, time = 0})

	if err != nil {
		log.error("Timer err: ", err)
		panic("Timer error")
	}

	return timers[i - 1].time
}
