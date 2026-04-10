package Netwalk

import "core:fmt"
import rl "vendor:raylib"


load_menu_resources :: proc(gui_state: ^GuiState) {
	rl.GuiLoadStyle("rgui_styles/style_terminal.rgs")
}

GuiState :: struct {
	help: bool,
	menu_expanded: bool,
}

UNIT :: 20
BUTTON_WIDTH :: 80
PAD :: 2


Menu_Height:f32= UNIT + 4

draw_menu :: proc(game: ^Game, window: ^Window, gui_state: ^GuiState) {
	x: f32 = UNIT
	// y: f32 = f32(game.height) * TH * game.camera.zoom
	y: f32 = PAD

	rl.GuiLabel({x, y, 150, UNIT}, fmt.ctprint("Moves:", game.moves, " Target:", game.target_moves))

	x += 150

	if game.camera.zoom < 2 {
		x = UNIT
		y += UNIT + PAD
	}


	rl.GuiLabel({x, y, 75, UNIT}, "New Game:")
	x += 75

	new_game_pressed: bool


	if rl.GuiButton({x, y, BUTTON_WIDTH, UNIT}, "Beginner") {
		make_game(game, GameSize[.Beginner], {}, GamePadded[.Beginner])
		scramble_puzzle(game)
		new_game_pressed = true
	}
	x += BUTTON_WIDTH + PAD
	if rl.GuiButton({x, y, BUTTON_WIDTH, UNIT}, "Intermediate") {
		make_game(game, GameSize[.Intermediate], {}, GamePadded[.Intermediate])
		scramble_puzzle(game)
		new_game_pressed = true
	}
	x += BUTTON_WIDTH + PAD
	if rl.GuiButton({x, y, BUTTON_WIDTH, UNIT}, "Expert") {
		make_game(game, GameSize[.Expert], {}, GamePadded[.Expert])
		scramble_puzzle(game)
		new_game_pressed = true
	}
	x += BUTTON_WIDTH + UNIT

	if game.camera.zoom < 2 {
		x = UNIT
		y += UNIT + PAD
	}

	rl.GuiLabel({x, y, 50, UNIT}, "Scale:")
	x += game.camera.zoom < 2 ? 75 : 50

	if rl.GuiButton({x, y, UNIT, UNIT}, "#116#") {
		do_zoom(game, window, .zoom_out)
	}
	x += UNIT + PAD
	if rl.GuiButton({x, y, UNIT, UNIT}, "#117#") {
		do_zoom(game, window, .zoom_in)
	}

	if new_game_pressed {
		set_window(window, game)
		make_network(game)
	}
}