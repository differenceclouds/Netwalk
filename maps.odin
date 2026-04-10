package Netwalk

//only for saved map data, probably won't use for generation. 
PipeData :: enum {
	BLANK, 

	PStrN,
	PStrE,

	PCorN,
	PCorE,
	PCorS,
	PCorW,

	PTriN,
	PTriE,
	PTriS,
	PTriW,

	STerN,
	STerE,
	STerS,
	STerW,

	SStrN,
	SStrE,

	SCorN,
	SCorE,
	SCorS,
	SCorW,

	STriN,
	STriE,
	STriS,
	STriW,

	TermN,
	TermE,
	TermS,
	TermW,
}


TileDataMin :: struct {
	tile: TileType,
	connection: Connection,
}

TileDataMap :: [PipeData]TileDataMin {
	.BLANK = { .Pipe, {} },
	.PStrN = { .Pipe, { .N, .S } },
	.PStrE = { .Pipe, { .W, .E } },

	.PCorN = { .Pipe, { .N, .E } },
	.PCorE = { .Pipe, { .E, .S } },
	.PCorS = { .Pipe, { .S, .W } },
	.PCorW = { .Pipe, { .W, .N } },

	.PTriN = { .Pipe, { .N, .E, .S } },
	.PTriE = { .Pipe, { .E, .S, .W } },
	.PTriS = { .Pipe, { .S, .W, .N } },
	.PTriW = { .Pipe, { .W, .N, .E } },

	.STerN = { .Server, { .N }},
	.STerE = { .Server, { .E }},
	.STerS = { .Server, { .S }},
	.STerW = { .Server, { .W }},

	.SStrN = { .Server, { .N, .S } },
	.SStrE = { .Server, { .W, .E } },

	.SCorN = { .Server, { .N, .E } },
	.SCorE = { .Server, { .E, .S } },
	.SCorS = { .Server, { .S, .W } },
	.SCorW = { .Server, { .W, .N } },

	.STriN = { .Server, { .N, .E, .S } },
	.STriE = { .Server, { .E, .S, .W } },
	.STriS = { .Server, { .S, .W, .N } },
	.STriW = { .Server, { .W, .N, .E } },

	.TermN = { .Terminal, { .N } },
	.TermE = { .Terminal, { .E } },
	.TermS = { .Terminal, { .S } },
	.TermW = { .Terminal, { .W } },
}



TEST_PUZZLE_BEGINNER :: []PipeData {
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK,
	.BLANK, .TermW, .PTriN, .PCorS, .TermS, .TermW, .BLANK,
	.BLANK, .PCorN, .STriW, .TermE, .PStrN, .PStrN, .BLANK,
	.BLANK, .PStrE, .PTriE, .PStrN, .PTriE, .PTriN, .BLANK,
	.BLANK, .PStrN, .PCorN, .PStrE, .TermE, .PStrE, .BLANK,
	.BLANK, .PCorE, .PStrE, .TermW, .TermN, .PCorN, .BLANK,
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK,
}

TEST_PUZZLE_INTERMEDIATE :: []PipeData {
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK,
	.BLANK, .TermN, .PTriW, .TermS, .TermE, .PTriW, .PTriN, .TermS, .BLANK,
	.BLANK,	.TermS, .PCorE, .PStrN, .PCorS, .PStrN, .PStrN, .TermS, .BLANK,
	.BLANK, .PCorW, .PTriS, .PStrE, .PTriW, .TermW, .PStrN, .PStrE, .BLANK,
	.BLANK, .PCorW, .PCorN, .PCorE, .STriN, .PStrE, .PTriN, .PStrN, .BLANK,
	.BLANK, .PStrE, .TermW, .PCorN, .TermS, .PCorN, .PCorS, .PTriE, .BLANK,
	.BLANK, .PTriE, .TermN, .TermS, .PStrE, .PTriS, .PStrN, .PTriE, .BLANK,
	.BLANK, .PCorE, .TermN, .TermS, .PStrE, .PStrE, .PStrE, .PCorE, .BLANK,
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK,
}

TEST_PUZZLE_EXPERT :: []PipeData {
	.PCorN, .TermS, .PStrE, .TermN, .PTriS, .PTriS, .PStrN, .TermN, .TermE,
	.PTriN, .TermN, .PTriN, .TermE, .PTriE, .PCorN, .PStrE, .TermW, .TermW,
	.PTriN, .PTriS, .PTriN, .TermS, .PCorS, .TermS, .TermN, .TermW, .PStrE,
	.PStrE, .PCorE, .PCorW, .PTriN, .TermW, .TermS, .PTriE, .TermS, .PStrN,
	.PTriE, .TermN, .TermE, .PCorW, .PCorW, .PStrE, .PTriN, .TermN, .PStrE,
	.PStrN, .PCorE, .PCorS, .PCorE, .PTriS, .PTriS, .PTriN, .PTriS, .PCorE,
	.PStrN, .PStrE, .PTriN, .SCorN, .PStrE, .TermS, .PCorE, .PCorN, .TermW,
	.PTriN, .PTriS, .PStrE, .TermE, .PCorS, .TermE, .PCorS, .TermN, .PTriN,
	.TermS, .PCorN, .PTriS, .PTriS, .PTriN, .PStrE, .PStrN, .TermE, .PStrE,
}

TEST_PUZZLE_BEGINNER_SOLVED :: []PipeData {
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, 
	.BLANK, .TermE, .PTriE, .PCorS, .TermS, .TermS, .BLANK, 
	.BLANK, .PCorE, .STriS, .TermN, .PStrN, .PStrN, .BLANK, 
	.BLANK, .PStrN, .PTriN, .PStrE, .PTriW, .PTriS, .BLANK, 
	.BLANK, .PStrN, .PCorN, .PStrE, .TermW, .PStrN, .BLANK, 
	.BLANK, .PCorN, .PStrE, .TermW, .TermE, .PCorW, .BLANK, 
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, 
}

TEST_PUZZLE_INTERMEDIATE_SOLVED :: []PipeData {
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, 
	.BLANK, .TermE, .PTriE, .TermW, .TermE, .PTriE, .PTriE, .TermW, .BLANK, 
	.BLANK, .TermS, .PCorN, .PStrE, .PCorS, .PStrN, .PStrN, .TermS, .BLANK, 
	.BLANK, .PCorN, .PTriE, .PStrE, .PTriS, .TermN, .PStrN, .PStrN, .BLANK, 
	.BLANK, .PCorE, .PCorW, .PCorE, .STriW, .PStrE, .PTriS, .PStrN, .BLANK, 
	.BLANK, .PStrN, .TermE, .PCorW, .TermE, .PCorS, .PCorN, .PTriS, .BLANK, 
	.BLANK, .PTriN, .TermW, .TermE, .PStrE, .PTriW, .PStrE, .PTriS, .BLANK, 
	.BLANK, .PCorN, .TermW, .TermE, .PStrE, .PStrE, .PStrE, .PCorW, .BLANK, 
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, 
}

TEST_PUZZLE_EXPERT_SOLVED :: []PipeData {
	.PCorE, .TermW, .PStrN, .TermN, .PTriN, .PTriE, .PStrE, .TermW, .TermN,
	.PTriS, .TermE, .PTriS, .TermE, .PTriS, .PCorN, .PStrE, .TermW, .TermE,
	.PTriW, .PTriE, .PTriS, .TermS, .PCorN, .TermW, .TermS, .TermE, .PStrE,
	.PStrE, .PCorW, .PCorN, .PTriS, .TermS, .TermE, .PTriS, .TermE, .PStrE,
	.PTriE, .TermW, .TermE, .PCorW, .PCorN, .PStrE, .PTriS, .TermE, .PStrE,
	.PStrN, .PCorE, .PCorS, .PCorE, .PTriE, .PTriE, .PTriW, .PTriE, .PCorS,
	.PStrN, .PStrN, .PTriN, .SCorW, .PStrN, .TermN, .PCorE, .PCorW, .TermN,
	.PTriW, .PTriS, .PStrN, .TermE, .PCorW, .TermE, .PCorW, .TermE, .PTriE,
	.TermE, .PCorW, .PTriN, .PTriE, .PTriE, .PStrE, .PStrE, .TermW, .PStrN,
}

test_intermediate_maze_1 :: []PipeData {
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, 
	.BLANK, .TermE, .PStrE, .PStrE, .PStrE, .PStrE, .PTriE, .TermW, .BLANK, 
	.BLANK, .PCorE, .PStrE, .PStrE, .PTriE, .PStrE, .PTriW, .PCorS, .BLANK, 
	.BLANK, .PCorN, .PCorS, .TermS, .PStrN, .TermE, .PStrE, .PCorW, .BLANK, 
	.BLANK, .TermS, .PStrN, .PTriN, .PCorW, .PCorE, .PStrE, .PCorS, .BLANK, 
	.BLANK, .PStrN, .PStrN, .PCorN, .PStrE, .PCorW, .PCorE, .PCorW, .BLANK, 
	.BLANK, .PStrN, .PCorN, .PTriE, .PStrE, .TermW, .PTriN, .PCorS, .BLANK, 
	.BLANK, .PCorN, .PStrE, .PCorW, .TermE, .PStrE, .PCorW, .STerN, .BLANK, 
	.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, 
}