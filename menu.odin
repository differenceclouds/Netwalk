package main

import "core:fmt"
import rl "vendor:raylib"
import "core:math/rand"


load_menu_resources :: proc(gui_state: ^GuiState) {
	rl.GuiLoadStyle("rgui_styles/style_jungle.rgs")
}

GuiState :: struct {
	help: bool,
	menu_expanded: bool,
}

UNIT :: 20


draw_menu :: proc(game: ^Game, window: ^Window, gui_state: ^GuiState) {
	x: f32 = UNIT
	y: f32 = f32(game.height * TILE_SIZE * i32(game.camera.zoom))

	rl.GuiLabel({x, y, 150, UNIT}, fmt.ctprint("Moves:", game.moves, " Target:", game.target_moves))

	x += 150

	if game.camera.zoom == 1 {
		x = UNIT
		y += UNIT + 2
	}

	rl.GuiLabel({x, y, 75, UNIT}, "New Game:")
	x += 75

	new_game_pressed: bool

	if rl.GuiButton({x, y, 100, UNIT}, "Beginner") {
		make_game(game, GameSize[.Beginner], TEST_PUZZLE_BEGINNER_SOLVED)
		scramble_puzzle(game)
		new_game_pressed = true
	}
	x += 100 + 2
	if rl.GuiButton({x, y, 100, UNIT}, "Intermediate") {
		make_game(game, GameSize[.Intermediate], test_intermediate_maze_1)
		scramble_puzzle(game)
		new_game_pressed = true
	}
	x += 100 + 2
	if rl.GuiButton({x, y, 100, UNIT}, "Expert") {
		make_game(game, GameSize[.Expert], TEST_PUZZLE_EXPERT_SOLVED)
		scramble_puzzle(game)
		new_game_pressed = true
	}
	x += 100 + UNIT

	if game.camera.zoom == 1 {
		x = UNIT
		y += UNIT + 2
	}

	rl.GuiLabel({x, y, 50, UNIT}, "Scale:")
	x += 75

	if rl.GuiButton({x, y, UNIT, UNIT}, "#116#") {
		do_zoom(game, window, .zoom_out)
	}
	x += UNIT + 2
	if rl.GuiButton({x, y, UNIT, UNIT}, "#117#") {
		do_zoom(game, window, .zoom_in)
	}

	if new_game_pressed {
		set_window(window, game^)
		make_network(game)
	}
}