package Netwalk

import "core:fmt"
import "core:math/rand"



check_four_ways :: proc(tiles: []TileDataMin, threshold: i32) -> bool {
	count: i32
	for tile in tiles {
		if card(tile.connection) == 4 do count += 1
		if count > threshold do return true
	}
	return false
}

generate_puzzle :: proc(size: Coord, pad: bool) -> []TileDataMin {
	tiles := make([]TileDataMin, size.x*size.y, context.temp_allocator)

	//maximal connective
	for &tile in tiles {
		tile = {.Pipe, {.N, .E, .S, .W}}
	}

	//add pad margin
	if pad do for y:i32=0; y<size.y; y+=1 do for x:i32=0; x<size.x; x+=1 {
		coord := Coord{x, y}
		idx := y*size.x + x
		if x == 0 			do tiles[idx].connection = {}
		if x == size.x - 1 	do tiles[idx].connection = {}
		if y == 0 			do tiles[idx].connection = {}
		if y == size.y - 1 	do tiles[idx].connection = {}

		if x == 1 			do tiles[idx].connection -= {.W}
		if x == size.x - 2 	do tiles[idx].connection -= {.E}
		if y == 1 			do tiles[idx].connection -= {.N}
		if y == size.y - 2 	do tiles[idx].connection -= {.S}
	}

	inner := size - (pad ? 2 : 0)
	offset := pad ? Coord{1, 1} : 0

	start_cell := rand.int31_max(inner.x * inner.y)
	start_coord := Coord{start_cell % inner.x, start_cell / inner.x} + offset
	start_cell = start_coord.y * size.x + start_coord.x

	tiles[start_cell].tile = .Server

	shuffle_mult :: 4

	shuffled_pipes := make([]i32, size.x * size.y * shuffle_mult)
	for i: i32 = 0; i < i32(len(shuffled_pipes)); i += 1 {
		shuffled_pipes[i] = i
	}
	rand.shuffle(shuffled_pipes)

	test_tiles:= make_slice([]TileDataMin, len(tiles))
	defer delete(test_tiles)

	for pipe_idx in shuffled_pipes {
		tile_idx := pipe_idx / shuffle_mult
		cardinal := Cardinal(pipe_idx % shuffle_mult)

		// if card(tiles[tile_idx].connection) < 4 do continue //check that breaks it in kinda interesting way
		if cardinal not_in tiles[tile_idx].connection do continue

		copy_slice(test_tiles, tiles) 

		destination_idx, destination_wall := get_adjacent_idx(cardinal, tile_idx, size)
		
		test_tiles[tile_idx].connection -= {cardinal}
		test_tiles[destination_idx].connection -= {destination_wall}
		
		visited_tiles: [dynamic]i32
		defer delete(visited_tiles)

		if find_connection(tile_idx, destination_idx, test_tiles, size, &visited_tiles) {
			copy_slice(tiles, test_tiles) 
		}
	}


	for &tile in tiles {
		if tile.tile != .Server && card(tile.connection) == 1 {
			tile.tile = .Terminal
		}
	}

	return tiles
}


find_connection :: proc(current_idx: i32, destination_idx: i32, tiles: []TileDataMin, size: Coord, visited_tiles: ^[dynamic]i32) -> bool {
	append(visited_tiles, current_idx)
	check_pipes: for pipe in tiles[current_idx].connection {
		adjacent_idx, adjacent_wall := get_adjacent_idx(pipe, current_idx, size)
		for v_idx in visited_tiles {
			if adjacent_idx == v_idx do continue check_pipes
		}
		if adjacent_idx == destination_idx {
			return true
		} else if find_connection(adjacent_idx, destination_idx, tiles, size, visited_tiles) {
			return true
		}
	}
	return false
}

get_adjacent_idx :: proc(dir: Cardinal, idx: i32, size: Coord) -> (i32, Cardinal) {
	coord := Coord {idx % size.x, idx / size.y}
	adj_coord, adj_card := get_adjacent_coord(dir, coord, size)
	adj_idx := adj_coord.y * size.x + adj_coord.x
	return adj_idx, adj_card
}

get_adjacent_coord :: proc(dir: Cardinal, coord: Coord, size: Coord) -> (Coord, Cardinal) {
	coord := coord
	adjacent_cardinal: Cardinal
	switch dir {
		case .N: {
			coord.y = (coord.y - 1) %% size.y
			adjacent_cardinal = .S
		}
		case .E: {
			coord.x = (coord.x + 1) %% size.x
			adjacent_cardinal = .W
		}
		case .S: {
			coord.y = (coord.y + 1) %% size.y
			adjacent_cardinal = .N
		}
		case .W: {
			coord.x = (coord.x - 1) %% size.x
			adjacent_cardinal = .E
		}
	}
	return coord, adjacent_cardinal
}