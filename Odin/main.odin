package main

import "core:fmt"
import "vendor:sdl2"

main :: proc() {
	sdl2.Init(sdl2.INIT_VIDEO)
	defer sdl2.Quit()

	window := sdl2.CreateWindow(
		"Hello, World!",
		sdl2.WINDOWPOS_UNDEFINED,
		sdl2.WINDOWPOS_UNDEFINED,
		800,
		600,
		sdl2.WINDOW_SHOWN,
	)
	defer sdl2.DestroyWindow(window)

	for quit := false; !quit; {
		for e: sdl2.Event; sdl2.PollEvent(&e); {
			#partial switch e.type {
			case .QUIT:
				quit = true
			case .KEYDOWN:
				if e.key.keysym.sym == .ESCAPE {
					quit = true
				}
			}
		}
	}
}
