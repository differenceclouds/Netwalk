#+feature dynamic-literals
package main

import "core:fmt"
import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

Window :: struct { 
	name:          cstring,
	width:         i32, 
	height:        i32,
	fps:           i32,
	control_flags: rl.ConfigFlags,
}

TILE_SIZE :: 48

Cardinal :: enum {
	N,E,S,W
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

// BEGINNER_SIZE :: 7
// INTERMEDIATE_SIZE :: 9
// EXPERT_SIZE :: 9

GameDifficulty :: enum {
	Beginner,
	Intermediate,
	Expert,
}

GameSize :: [GameDifficulty][2]i32 {
	.Beginner = {7, 7},
	.Intermediate = {9, 9},
	.Expert = {9, 9}
}

Game :: struct {
	width: i32,
	height: i32,
	tiles: []TileData,
	camera: rl.Camera2D,
	game_won: bool,

	//following only used for move counter
	last_rotated_tile: i32,
	initial_state_of_last_rotated_tile: Connection,
	initial_moves: i32,
	moves: i32,
	target_moves: i32
}

TileData :: struct {
	tile_type: TileType,
	connection: Connection,
	networked: bool,
	fixed: bool
}

TileCoords := [TileType]Coord {
	.Pipe = {0,0},
	.Server = {1, 0},
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



check_connections :: proc(current_idx: i32, game: ^Game, visited_tiles: ^[dynamic]i32) {
	append(visited_tiles, current_idx)
	current_coord : Coord = {
		current_idx % game.width,
		current_idx / game.width
	}
	for dir in game.tiles[current_idx].connection {
		new_coord := current_coord
		check_dir: Cardinal
		switch dir {
			case .N: {
				new_coord.y = (new_coord.y - 1) %% game.height
				check_dir = .S
			}
			case .E: {
				new_coord.x = (new_coord.x + 1) %% game.width
				check_dir = .W
			}
			case .S: {
				new_coord.y = (new_coord.y + 1) %% game.height
				check_dir = .N
			}
			case .W: {
				new_coord.x = (new_coord.x - 1) %% game.width
				check_dir = .E
			}

		}
		new_idx := new_coord.y * game.width + new_coord.x
		visited : bool
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
	if difference == 3 do difference = 1

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

	if prev_connection == {} do return

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

make_game :: proc(game: ^Game, size: Coord, puzzle: []PipeData) {
	width  := size.x
	height := size.y
	prev_zoom := game.camera.zoom
	game^ = {
		width = i32(width),
		height = i32(height),
		tiles = make_slice([]TileData, width * height, context.temp_allocator),
		camera = rl.Camera2D{zoom = 2},
		last_rotated_tile = -1,
	}
	if prev_zoom != 0 {
		game^.camera.zoom = prev_zoom
	}
	tile_data_map := TileDataMap
	assert(len(game.tiles) == len(puzzle))
	for pipe_data, i in puzzle {
		tile_data := tile_data_map[pipe_data]
		game.tiles[i].connection = tile_data.connection
		game.tiles[i].tile_type = tile_data.tile
	}
}

set_window :: proc(window: ^Window, game: Game) {
	zoom := i32(max(game.camera.zoom, 1))
	window^ = Window {
		name = "NETWALK",
		width = TILE_SIZE * game.width * zoom + 1,
		height = TILE_SIZE * game.height * zoom + 1 + UNIT,
		fps = 30,
		control_flags = rl.ConfigFlags{ /*.WINDOW_RESIZABLE*/ } 
	}
	if zoom == 1 {
		window^.height += (UNIT + 2)*2
	}
	// rl.InitWindow(window.width, window.height, window.name)
	rl.SetWindowSize(window.width, window.height)
	rl.SetWindowState( window.control_flags )
	rl.SetWindowTitle(window.name)
}

ZoomAction :: enum {
	zoom_reset,
	zoom_in,
	zoom_out,
}

do_zoom :: proc(game: ^Game, window: ^Window, action: ZoomAction) {
	switch action {
		case .zoom_reset: 	game.camera.zoom = 2
		case .zoom_in: 		game.camera.zoom = 2
		case .zoom_out: 	game.camera.zoom = 1
	}
	set_window(window, game^)
}

main :: proc() {
	game: Game
	window: Window
	gui_state: GuiState

	make_game(&game, GameSize[.Expert], TEST_PUZZLE_EXPERT_SOLVED)
	scramble_puzzle(&game)

	rl.ChangeDirectory(rl.GetApplicationDirectory())
	rl.InitWindow(window.width, window.height, window.name)
	// rl.SetWindowState( window.control_flags )
	set_window(&window, game)
	rl.SetTargetFPS(window.fps)

	tilemap_texture := rl.LoadTexture("tilemap_48.png")
	nice_texture := rl.LoadTexture("win.png")
	perfect_texture := rl.LoadTexture("perfect.png")
	load_menu_resources(&gui_state)

	make_network(&game)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(game.camera)

		mouse_position := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera)
		mouse_coord_float := mouse_position / TILE_SIZE
		mouse_coord : Coord = {i32(math.floor(mouse_coord_float.x)), i32(math.floor(mouse_coord_float.y))} //floor only needed for mouse values less than zero
		cursor_on_screen := rl.IsCursorOnScreen()
		cursor_in_puzzle := mouse_coord.x >= 0 && mouse_coord.x < game.width && mouse_coord.y >= 0 && mouse_coord.y < game.height
		
		if !game.game_won && cursor_in_puzzle {
			color := rl.Color{0, 255, 255, 255}
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

			if move_made && check_win(game) {
				game.game_won = true
			}

			rl.DrawRectangle(mouse_coord.x * TILE_SIZE, mouse_coord.y * TILE_SIZE, TILE_SIZE, TILE_SIZE, color)
		}

		for y:i32 = 1; y <= game.height; y+=1 {
			rl.DrawLine(0, y * TILE_SIZE, game.width * TILE_SIZE, y * TILE_SIZE, rl.DARKGRAY)
		}
		for x:i32 = 1; x < game.width; x+=1 {
			rl.DrawLine(x * TILE_SIZE, 0, x  * TILE_SIZE, game.height * TILE_SIZE, rl.DARKGRAY)
		}

		for y:i32 = 0; y < game.height; y+=1 {
			for x:i32 = 0; x < game.width; x += 1 {
				idx := y * game.width + x

				tile_type := game.tiles[idx].tile_type
				connection := game.tiles[idx].connection
				is_networked := game.tiles[idx].networked

				pipe_coord := ConnectionTilemapCoords[connection]
				tile_coord := TileCoords[tile_type]

				if is_networked {
					pipe_coord.x += 4
					#partial switch tile_type {
						case .Terminal: tile_coord.x += 1
					}
				}

				pipe_rect := Rect{f32(pipe_coord.x) * TILE_SIZE, f32(pipe_coord.y) * TILE_SIZE, TILE_SIZE, TILE_SIZE}
				tile_rect := Rect{f32(tile_coord.x) * TILE_SIZE, f32(tile_coord.y) * TILE_SIZE, TILE_SIZE, TILE_SIZE}

				// rl.DrawRectangleLines(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.DARKGRAY)

				if game.tiles[idx].fixed {
					rl.DrawRectangle(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE, {64, 64, 128, 128})
				}

				rl.DrawTextureRec(tilemap_texture, pipe_rect, {f32(x) * TILE_SIZE, f32(y) * TILE_SIZE}, rl.WHITE)
				rl.DrawTextureRec(tilemap_texture, tile_rect, {f32(x) * TILE_SIZE, f32(y) * TILE_SIZE}, rl.WHITE)

				if game.game_won {
					x: i32 = (game.width * TILE_SIZE / 2) - nice_texture.width/2
					y: i32 = (game.height * TILE_SIZE / 2) - nice_texture.height/2
					if game.moves == game.target_moves {
						y -= perfect_texture.height / 2
						rl.DrawTexture(perfect_texture, x, y + nice_texture.height + 8, rl.WHITE)
					}
					rl.DrawTexture(nice_texture, x, y, rl.WHITE)

				}
			}
		}



		// rl.DrawFPS(0, 0)
		rl.EndMode2D()
		draw_menu(&game, &window, &gui_state)

		rl.EndDrawing()
			
	}
}