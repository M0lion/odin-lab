package animation

import "base:runtime"
import "core:log"
import "core:math"

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

@(private = "file")
Cycle :: struct {
	loc:       runtime.Source_Code_Location,
	time:      f32,
	direction: f32,
}

cycle :: proc(dt: f32, loc := #caller_location) -> f32 {
	@(static) timers: [dynamic]Cycle

	for &t in timers {
		if t.loc == t.loc {
			t.time += dt * t.direction
			if t.time >= 1 && t.direction > 0 {
				t.direction = -1
			} else if t.time <= 0 && t.direction < 0 {
				t.direction = 1
			}
			t.time = math.clamp(t.time, 0, 1)
			return t.time
		}
	}

	i, err := append(&timers, Cycle{loc = loc, time = 0, direction = 1})

	if err != nil {
		log.error("Timer err: ", err)
		panic("Timer error")
	}

	return timers[i - 1].time
}
