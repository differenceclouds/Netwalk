#+feature dynamic-literals
package Netwalk

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Window :: struct {
	name:          cstring,
	width:         i32,
	height:        i32,
	fps:           i32,
	control_flags: rl.ConfigFlags,
}

TW :: 48
TH :: 48

Cardinal :: enum {
	N,
	E,
	S,
	W,
}
Connection :: bit_set[Cardinal]


Rect :: rl.Rectangle
Coord :: [2]i32
Vec2 :: [2]f32

TileType :: enum {
	Pipe,
	Server,
	Terminal,
}

Rotation :: enum {
	Left,
	Right,
}

GameDifficulty :: enum {
	Beginner,
	Intermediate,
	Expert,
}

GameSize :: [GameDifficulty]Coord {
	.Beginner     = {7, 7},
	.Intermediate = {9, 9},
	.Expert       = {9, 9},
}

GameIsPadded :: [GameDifficulty]bool {
	.Beginner     = true,
	.Intermediate = true,
	.Expert       = false,
}

Game :: struct {
	width:                              i32,
	height:                             i32,
	tiles:                              []TileData,
	camera:                             rl.Camera2D,
	game_won:                           bool,
	all_terminals_used:                 bool,
	hide_win_message:                   bool,

	//following only used for move counter
	last_rotated_tile:                  i32,
	initial_state_of_last_rotated_tile: Connection,
	initial_moves:                      i32,
	moves:                              i32,
	target_moves:                       i32,

	win_timer:                          f32,
	win_message_complete:               bool,
}

TileData :: struct {
	tile_type:  TileType,
	connection: Connection,
	networked:  bool,
	fixed:      bool,
}

TileCoords := [TileType]Coord {
	.Pipe     = {0, 0},
	.Server   = {1, 0},
	.Terminal = {2, 0},
}

ConnectionTilemapCoords := map[Connection]Coord {
	{.N} = {0, 1},
	{.E} = {1, 1},
	{.S} = {2, 1},
	{.W} = {3, 1},
	{.N, .S} = {0, 2},
	{.W, .E} = {1, 2},
	{.N, .E} = {0, 3},
	{.E, .S} = {1, 3},
	{.S, .W} = {2, 3},
	{.W, .N} = {3, 3},
	{.N, .E, .W} = {0, 4},
	{.N, .E, .S} = {1, 4},
	{.E, .S, .W} = {2, 4},
	{.N, .S, .W} = {3, 4},
	{.N, .E, .S, .W} = {0, 5},
}

ConnectionCardinality := map[Connection]Cardinal {
	{.N} = .N,
	{.E} = .E,
	{.S} = .S,
	{.W} = .W,
	{.N, .S} = .N,
	{.W, .E} = .E,
	{.N, .E} = .N,
	{.E, .S} = .E,
	{.S, .W} = .S,
	{.W, .N} = .W,
	{.N, .E, .S} = .N,
	{.E, .S, .W} = .E,
	{.N, .S, .W} = .S,
	{.N, .E, .W} = .W,
	{.N, .E, .S, .W} = nil,
}

make_network :: proc(game: ^Game) {
	server_tiles := make([dynamic]i32)
	visited_tiles := make([dynamic]i32)
	defer delete(server_tiles)
	defer delete(visited_tiles)

	for &tile, i in game.tiles {
		if tile.tile_type == .Server {
			append(&server_tiles, i32(i))
			tile.networked = true
		} else {
			tile.networked = false
		}
	}

	for server_idx in server_tiles {
		check_connections(server_idx, game, &visited_tiles)
	}
}

check_terminals :: proc(game:Game) -> bool {
	for tile in game.tiles {
		if tile.tile_type == .Terminal && !tile.networked do return false
	}
	return true
}



check_connections :: proc(current_idx: i32, game: ^Game, visited_tiles: ^[dynamic]i32) {
	append(visited_tiles, current_idx)
	current_coord: Coord = {current_idx % game.width, current_idx / game.width}
	for dir in game.tiles[current_idx].connection {
		new_coord, check_dir := get_adjacent_coord(dir, current_coord, {game.width, game.height})

		new_idx := new_coord.y * game.width + new_coord.x
		visited: bool
		for v in visited_tiles {
			if new_idx == v do visited = true
		}
		if !visited && check_dir in game.tiles[new_idx].connection {
			game.tiles[new_idx].networked = true
			check_connections(new_idx, game, visited_tiles)
		}
	}
}

check_win :: proc(game: Game) -> bool {
	number_of_connections: i32
	target_connections: i32

	//skip blank tiles
	for tile in game.tiles {
		if tile.connection != {} do target_connections += 1
	}

	for tile in game.tiles {
		if tile.networked do number_of_connections += 1
	}

	if number_of_connections == target_connections {
		return true
	}

	return false
}


fill_puzzle :: proc(game: ^Game, data: []PipeData) {
	tile_data_map := TileDataMap
	assert(len(game.tiles) == len(data))
	for pipe_data, i in data {
		tile_data := tile_data_map[pipe_data]
		game.tiles[i].connection = tile_data.connection
		game.tiles[i].tile_type = tile_data.tile
	}
}


scramble_tile :: proc(connection: Connection) -> (Connection, i32) {
	init_connection := connection
	init_cardinality := ConnectionCardinality[connection]

	new_connection: Connection

	steps := i32(rand.float32() * 4)
	for pipe in init_connection {
		new_connection += {cycle_enum(pipe, int(steps))}
	}
	new_cardinality := ConnectionCardinality[new_connection]
	difference := (i32(new_cardinality) - i32(init_cardinality)) %% 4
	if difference == 3 do difference = 1 //three CW = one CCW, vice versa. probably some way to do this with negatives and absolute value but whatever

	return new_connection, difference
}

// must start with completed puzzle
scramble_puzzle :: proc(game: ^Game) {
	moves_total: i32
	for &tile in game.tiles {
		if tile.connection == {} do continue
		moves: i32
		tile.connection, moves = scramble_tile(tile.connection)
		moves_total += moves
	}
	game.target_moves = moves_total
}

rotate_tile :: proc(game: ^Game, coord: Coord, step: int) {
	idx := coord.y * game.width + coord.x
	prev_connection := game.tiles[idx].connection

	if prev_connection == {} || prev_connection == {.N, .E, .S, .W} do return

	new_connection: Connection
	for pipe in prev_connection {
		new_connection += {cycle_enum(pipe, step)}
	}
	game.tiles[idx].connection = new_connection


	//handle move counter
	init_cardinality := ConnectionCardinality[game.initial_state_of_last_rotated_tile]
	new_cardinality := ConnectionCardinality[new_connection]
	prev_last_rotated_tile := game.last_rotated_tile
	game.last_rotated_tile = idx

	difference: i32
	if prev_last_rotated_tile != game.last_rotated_tile {
		game.initial_state_of_last_rotated_tile = prev_connection
		difference = 1
		game.initial_moves = game.moves
	} else {
		difference = (i32(new_cardinality) - i32(init_cardinality)) %% 4
		if difference == 3 do difference = 1 //ugly but whatever
	}
	game.moves = game.initial_moves + difference
}


cycle_enum :: proc(value: $T, step: int) -> T {
	return T((int(value) + step) %% len(T))
}

Attempt_Average_Counter: i32
Attempts_Sum: i32
Allow_Fourways: bool
Game_Started: bool


// make_hash :: proc(tiles: []TileDataMin) -> []byte {
// 	for tile in tiles {
// 		tile.
// 	}
// }

make_game :: proc(game: ^Game, size: Coord, puzzle: []PipeData = {}, pad := false) {
	width := size.x
	height := size.y
	prev_zoom := game.camera.zoom

	free_all(context.temp_allocator)

	game^ = {
		width = i32(width),
		height = i32(height),
		tiles = make_slice([]TileData, width * height, context.temp_allocator),
		camera = rl.Camera2D{zoom = 2, offset = {0, Menu_Height}},
		last_rotated_tile = -1,
	}
	if prev_zoom != 0 {
		game^.camera.zoom = prev_zoom
	}

	if len(puzzle) == 0 {
		puzzle_data: []TileDataMin


		if Allow_Fourways {
			puzzle_data = generate_puzzle(size, pad)
		} else {
			Attempt_Average_Counter += 1
			MAX_ATTEMPTS :: 150
			for i in 1 ..= MAX_ATTEMPTS {
				puzzle_data = generate_puzzle(size, pad)
				if !check_four_ways(puzzle_data, 0) {
					Attempts_Sum += i32(i)
					if ODIN_DEBUG do fmt.println("attempts:", i, "average:", f32(Attempts_Sum) / f32(Attempt_Average_Counter))
					break
				}
				if ODIN_DEBUG do if i == MAX_ATTEMPTS do fmt.println("attempts:", i, "(maximum)")
			}
		}


		assert(len(game.tiles) == len(puzzle_data))
		for tile_data, i in puzzle_data {
			game.tiles[i].connection = tile_data.connection
			game.tiles[i].tile_type = tile_data.tile
		}
	} else {
		assert(len(game.tiles) == len(puzzle))
		tile_data_map := TileDataMap
		for pipe_data, i in puzzle {
			tile_data := tile_data_map[pipe_data]
			game.tiles[i].connection = tile_data.connection
			game.tiles[i].tile_type = tile_data.tile
		}
	}
}

set_window :: proc(window: ^Window, game: ^Game) {
	set_window_size(window, game)
	rl.SetWindowSize(window.width, window.height)
	rl.SetWindowState(window.control_flags)
	rl.SetWindowTitle(window.name)
}

set_window_size :: proc(window: ^Window, game: ^Game) {
	zoom := max(game.camera.zoom, 1)
	if zoom < 2 {
		Menu_Height = UNIT * 3 + PAD * 4
	} else {
		Menu_Height = UNIT + PAD * 2
	}
	game^.camera.offset.y = (Menu_Height)
	window^ = Window {
		name          = "NETWALK",
		width         = i32(f32(TW * game.width) * zoom + 1),
		height        = i32(f32(TH * game.height) * zoom + 1) + i32(Menu_Height),
		fps           = 30,
		control_flags = rl.ConfigFlags{ },
	}
}

ZoomAction :: enum {
	zoom_reset,
	zoom_in,
	zoom_out,
}

do_zoom :: proc(game: ^Game, window: ^Window, action: ZoomAction) {
	switch action {
	case .zoom_reset:
		game.camera.zoom = 2
	case .zoom_in:
		game.camera.zoom = min(game.camera.zoom + 0.5, 3)
	case .zoom_out:
		game.camera.zoom = max(game.camera.zoom - 0.5, 1)
	}
	set_window(window, game)
}

//use with #load
texture_from_memory :: proc(data: []byte) -> rl.Texture2D {
	img := rl.LoadImageFromMemory(".png", raw_data(data), i32(len(data)))
	defer rl.UnloadImage(img)
	return rl.LoadTextureFromImage(img)
}
//use with #load
image_from_memory :: proc(data: []byte) -> rl.Image {
	return rl.LoadImageFromMemory(".png", raw_data(data), i32(len(data)))
}

main :: proc() {
	game: Game
	window: Window
	gui_state: GuiState

	make_game(&game, GameSize[.Expert], {}, GameIsPadded[.Expert])
	// scramble_puzzle(&game)
	set_window_size(&window, &game)
	rl.ChangeDirectory(rl.GetApplicationDirectory())
	rl.ChangeDirectory("assets")
	rl.InitWindow(window.width, window.height, window.name)
	set_window(&window, &game)
	rl.SetTargetFPS(window.fps)

	tilemap_texture := texture_from_memory(#load("./assets/tilemap3.png"))
	nice_texture    := texture_from_memory(#load("./assets/win.png"))
	perfect_texture := texture_from_memory(#load("./assets/perfect.png"))
	carpet_texture  := texture_from_memory(#load("./assets/carpet.png"))


	// tilemap_texture := rl.LoadTexture("tilemap3.png")
	// nice_texture    := rl.LoadTexture("win.png")
	// perfect_texture := rl.LoadTexture("perfect.png")
	// carpet_texture  := rl.LoadTexture("carpet.png")
	
	when ODIN_OS == .Windows {
		icon_image := image_from_memory(#load("./assets/Icon.png"))
		rl.SetWindowIcon(icon_image)
		rl.UnloadImage(icon_image)
	}
	if !load_menu_resources(&gui_state) do panic("no style!!!!!!")

	make_network(&game)

	for !rl.WindowShouldClose() {

		if rl.IsKeyPressed(.EQUAL) do do_zoom(&game, &window, .zoom_in)
		if rl.IsKeyPressed(.MINUS) do do_zoom(&game, &window, .zoom_out)
		if game.game_won {
			game.win_timer += rl.GetFrameTime()
			if game.win_timer >= 1 && rl.IsMouseButtonPressed(.LEFT) do game.hide_win_message = true
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(game.camera)
		rl.DrawTextureRec(carpet_texture, {0, 0, f32(window.width), f32(window.height)}, 0, rl.WHITE)

		mouse_position := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera)
		mouse_coord_float := mouse_position / {TW, TH}
		mouse_coord: Coord = {
			i32(math.floor(mouse_coord_float.x)),
			i32(math.floor(mouse_coord_float.y)),
		}
		cursor_in_puzzle :=
			mouse_coord.x >= 0 &&
			mouse_coord.x < game.width &&
			mouse_coord.y >= 0 &&
			mouse_coord.y < game.height

		gui_busy := gui_state.help || gui_state.all_terminals_message


		if (!game.game_won || !Game_Started) && cursor_in_puzzle && !gui_busy{
			idx := mouse_coord.y * game.width + mouse_coord.x
			if rl.IsMouseButtonPressed(.MIDDLE) || rl.IsKeyPressed(.SPACE) {
				game.tiles[idx].fixed = !game.tiles[idx].fixed
			}

			move_made: bool

			if rl.IsMouseButtonPressed(.LEFT) && !game.tiles[idx].fixed {
				rotate_tile(&game, mouse_coord, -1)
				make_network(&game)
				move_made = true
			} else if rl.IsMouseButtonPressed(.RIGHT) && !game.tiles[idx].fixed {
				rotate_tile(&game, mouse_coord, 1)
				make_network(&game)
				move_made = true
			}

			if move_made && Game_Started {
				if check_win(game) {
					game.game_won = true
					rl.SetTargetFPS(0)
				} else if check_terminals(game) && !game.all_terminals_used{
					game.all_terminals_used = true
					gui_state.all_terminals_message = true
				}
			}

			rl.DrawRectangle(mouse_coord.x * TW, mouse_coord.y * TH, TW, TH, {0, 0, 255, 64})
		}
		if !game.game_won {
			for y: f32 = 0; y <= f32(game.height); y += 1 {
				rl.DrawLineEx({0, y * TH} + 0.5, {f32(game.width * TW), y * TH} + 0.5, 1, {128, 128, 128, 48})
			}
			for x: f32 = 1; x < f32(game.width); x += 1 {
				rl.DrawLineEx({x * TW, 0} + 0.5, {x * TW, f32(game.height * TH)} + 0.5, 1, {128, 128, 128, 48})
			}
		}

		for y: i32 = 0; y < game.height; y += 1 {
			for x: i32 = 0; x < game.width; x += 1 {
				idx := y * game.width + x

				tile_type := game.tiles[idx].tile_type
				connection := game.tiles[idx].connection
				is_networked := game.tiles[idx].networked

				pipe_coord := ConnectionTilemapCoords[connection]
				tile_coord := TileCoords[tile_type]

				if is_networked {
					pipe_coord.x += 4
					#partial switch tile_type {
					case .Terminal:
						tile_coord.x += game.game_won ? 2 : 1

					}
				}

				pipe_rect := Rect{f32(pipe_coord.x) * TW, f32(pipe_coord.y) * TH, TW, TH}
				tile_rect := Rect{f32(tile_coord.x) * TW, f32(tile_coord.y) * TH, TW, TH}

				position: Vec2 = {f32(x) * TW, f32(y) * TH}
				if !game.game_won && game.tiles[idx].fixed {
					rl.DrawRectangle(x * TW, y * TH, TW, TH, {64, 64, 128, 128})

				}
				rl.DrawTextureRec(tilemap_texture, pipe_rect, position, rl.WHITE)
				rl.DrawTextureRec(tilemap_texture, tile_rect, position, rl.WHITE)
				// if game.tiles[idx].fixed || game.game_won {
				// 	zip_tie_coord := ConnectionTilemapCoords[connection] + {8,0}
				// 	zip_tie_rect := Rect{f32(zip_tie_coord.x) * TW, f32(zip_tie_coord.y) * TH, TW, TH}
				// 	rl.DrawTextureRec(tilemap_texture, zip_tie_rect, position, rl.WHITE)
				// }
			}
		}

		if game.all_terminals_used {

		}

		if game.game_won && !game.hide_win_message {

			win_offset := max(500 - game.win_timer * 300, 0)

			x: i32 = i32(f32(game.width) * TW / 2.0 - f32(nice_texture.width) / 2.0 + win_offset)
			y: i32 = (game.height * TH / 2) - nice_texture.height / 2
			if game.moves <= game.target_moves {
				y -= perfect_texture.height / 2
				rl.DrawTexture(perfect_texture, x, y + nice_texture.height + 8, rl.WHITE)
			}
			rl.DrawTexture(nice_texture, x, y, rl.WHITE)
			if !game.win_message_complete && win_offset == 0 {
				game.win_message_complete = true
				rl.SetTargetFPS(30)
			}
		}

		// rl.DrawFPS(0, 0)
		rl.EndMode2D()
		draw_menu(&game, &window, &gui_state)

		rl.EndDrawing()

	}
}
