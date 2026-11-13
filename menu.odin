package Netwalk

import "core:fmt"
import "core:os"
import "core:path/filepath"
import rl "vendor:raylib"
import rg "../raygui_helpers"

load_menu_resources :: proc(gui_state: ^GuiState) -> bool {
	gui_state.style_bg = rl.BLACK
	gui_state.style = .genesis

	rg.switch_style(gui_state.style)
	gui_state.help = true

	return true
}

cycle_style :: proc(gui_state: ^GuiState) {
	style := gui_state.style
	style = cycle_enum(style, 1)
	gui_state.style = style

	rg.switch_style(gui_state.style)

	if gui_state.style == .rltech {
		gui_state.style_bg = rl.LIGHTGRAY
	} else {
		gui_state.style_bg = rl.BLACK
	}
}

GuiState :: struct {
	help: bool,
	menu_expanded: bool,
	all_terminals_message: bool,
	style: rg.GuiStyle,
	style_bg: rl.Color,
}

UNIT :: 20
BUTTON_WIDTH :: 60
PAD :: 2
Menu_Height:f32

draw_menu :: proc(game: ^Game, window: ^Window, gui_state: ^GuiState) {
	x: f32 = UNIT
	// y: f32 = f32(game.height) * TH * game.camera.zoom
	y: f32 = PAD

	rl.GuiUnlock()
	rl.GuiToggle({x, y, UNIT, UNIT}, "#193#", &gui_state.help)
	x += UNIT*1.5
	new_game_pressed: bool


	rl.GuiLabel({x, y, 150, UNIT}, fmt.ctprint("Moves:", game.moves, " Target:", game.target_moves))

	x += 135

	if game.camera.zoom < 2 {
		x = UNIT
		y += UNIT + PAD
	}




	rl.GuiLabel({x, y, 75, UNIT}, "New Game:")
	x += 75



	if rl.GuiButton({x, y, BUTTON_WIDTH, UNIT}, "Beginner") {
		make_game(game, GameSize[.Beginner], {}, GameIsPadded[.Beginner])
		Game_Started = true
		scramble_puzzle(game)
		new_game_pressed = true
		gui_state.help = false
	}
	x += BUTTON_WIDTH + PAD
	if rl.GuiButton({x, y, BUTTON_WIDTH, UNIT}, "Interm.") {
		make_game(game, GameSize[.Intermediate], {}, GameIsPadded[.Intermediate])
		Game_Started = true
		scramble_puzzle(game)
		new_game_pressed = true
		gui_state.help = false
	}
	x += BUTTON_WIDTH + PAD
	if rl.GuiButton({x, y, BUTTON_WIDTH, UNIT}, "Expert") {
		make_game(game, GameSize[.Expert], {}, GameIsPadded[.Expert])
		Game_Started = true
		scramble_puzzle(game)
		new_game_pressed = true
		gui_state.help = false
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
	x += UNIT*2 + PAD

	rl.GuiCheckBox({x, y, UNIT, UNIT}, "Allow 4-way tiles", &Allow_Fourways)
	x += UNIT*7

	if new_game_pressed {
		set_window(window, game)
		make_network(game)
	}

	if gui_state.help {
		width := f32(rl.GuiGetTextWidth("There will be no unused connections, and    "))
		height :: 340
		x = f32(window.width - i32(width)) / 2.0
		y = f32(window.height - height) / 2.0
		// rl.GuiTextBox({x, y, width, height}, "heee", 10, false)
		if rl.GuiWindowBox({x, y, width, height}, "About Netadmin") != 0 {
			gui_state.help = false
		}

		style_button_text := fmt.ctprint(gui_state.style)
		style_button_width := rl.GuiGetTextWidth(style_button_text) + UNIT
		if rl.GuiButton({x + width - f32(style_button_width) - UNIT - 4, y + 2, f32(style_button_width), UNIT}, style_button_text) {
			cycle_style(gui_state)
		}

		y += 23
		rl.GuiLock()
		help_text: cstring :
`Connect all terminals to the server!
There will be no unused connections, and
no loops. (Nearly) every puzzle can be
completed in target number of moves
without guessing. (Most) puzzles have
one unique solution. Expert puzzles wrap
at each edge (toroidal). Lock Tile
feature is advised for Expert puzzles.

Controls:
Rotate Tile: left click / right click
Lock Tile: middle click | spacebar
Set game scale: - / +`
		rl.GuiTextBox({x, y, width, height - 23}, help_text, 10, false)
		rl.GuiUnlock()
	}


	if gui_state.all_terminals_message {
		width :: 280
		height :: 150
		x = f32(window.width - width) / 2.0
		y = f32(window.height - height) / 2.0
		// rl.GuiTextBox({x, y, width, height}, "heee", 10, false)
		if rl.GuiWindowBox({x, y, width, height}, "Boss") != 0 {
			gui_state.all_terminals_message = false
		}

		y += 23
		rl.GuiLock()

		text: cstring :
`HMMMMMMMMM... Very clever.
We gotta use ALL this piping though.
Keep crackin!`
		rl.GuiTextBox({x, y, width, height - 23}, text, 10, false)
		rl.GuiUnlock()
	}
}