module control
	(
		input reset_n,
		input go,
		input clk,
		input left,
		input right,
		output [7:0] X,
		output [6:0] Y,
		output [5:0] colour,
		output reg writeEn
	);
	
	localparam
		CLEAR_BOARD = 4'b0000,
		CLEAR_BOARD_WAIT = 4'b0001,
		GET_PIECE = 4'b0011,
		DETECT_COLLISION = 4'b0010,
		DETECT_COLLISION_WAIT = 4'b0110,
		SET_UP_RAM = 4'b1110,
		ERASE_OLD = 4'b1100,
		DRAW_NEW = 4'b1110,
		DRAW_NEW_WAIT = 4'b1111,
		WAIT = 4'b1011;
		
	localparam speed = 25'b1011111010111100001000000; // .5Hz

	reg [3:0] curr_state, next_state;
	
	// The following wires are wired into the RAM module
	wire [7:0] ram_addr;
	wire [5:0] ram_in, ram_out;
	reg ram_wren;
	
	ram_board board(ram_addr, clk, ram_in, ram_wren, ram_out);
	
	reg [4:0] curr_anc_X;
	reg [5:0] curr_anc_Y;
	wire [4:0] new_anc_X;
	wire [4:0] new_anc_Y;
	reg [2:0] curr_piece;
	reg [1:0] curr_rotation;

	reg [4:0] X_to_Draw;
	reg [5:0] Y_to_Draw;
	
	/* 0 is FALLING PIECE
	*/
	reg [2:0] module_select; // Determines which module we're currently using
	wire [2:0] module_complete; // 1 on the clock cycle where the module finishes computation (and this is when the results can be used)
	
	// 0 is detect collision
	// 1 is for draw piece
	// 2 is for rate divider
	
	/* MODULES */
	wire collision;
	collision f(
		.enable(module_select[0]), 
		.X_anchor(curr_anc_X),
		.Y_anchor(curr_anc_Y), 
		.block(curr_piece),
		.left(left),
		.right(right), 
		.clk(clk), 
		.ram_Q(ram_out), 
		.X_out(new_anc_X), 
		.Y_out(new_anc_Y), 
		.collision(collision), 
		.ram_addr(ram_addr), 
		.complete(module_complete[0])
	);
	
	reg draw_clear;
	draw_tetromino draw (
		.enable(module_select[1]),
		.block(curr_piece),
		.X_in(X_to_Draw), 
		.Y_in(Y_to_Draw),
		.clear(draw_clear),
		.clk(clk), 
		.X_vga(X), 
		.Y_vga(Y), 
		.colour_out(colour),
		.complete(module_complete[1])
	);
	
	rate_divider rd(
		.enable(module_select[2]),
		.rate(speed),
		.clk(clk),
		.rd(module_complete[2])
	);

	always @(*)
   begin: state_table
           case (curr_state)
               CLEAR_BOARD: next_state = go ? CLEAR_BOARD_WAIT : CLEAR_BOARD;
               CLEAR_BOARD_WAIT: next_state = go ? CLEAR_BOARD_WAIT: GET_PIECE;
               GET_PIECE: next_state = DETECT_COLLISION; 
               DETECT_COLLISION: next_state = module_complete[0] ? DETECT_COLLISION_WAIT : DETECT_COLLISION; 
               DETECT_COLLISION_WAIT: next_state = collision ? SET_UP_RAM : ERASE_OLD;
               ERASE_OLD: next_state = module_complete[1] ? DRAW_NEW : ERASE_OLD;
               DRAW_NEW: next_state = module_complete[1] ? DRAW_NEW_WAIT : DRAW_NEW;
					DRAW_NEW_WAIT: next_state = module_complete[2] ? DETECT_COLLISION : DRAW_NEW_WAIT;
					default: next_state = GET_PIECE;
       endcase
   end // state_table

	always @(*) 
	begin: enable_signals
		// Setting default values for all these signals
		ram_wren = 3'b000;
		X_to_Draw = 3'b000;
		Y_to_Draw = 3'b000;
		module_select = 3'b000;
		draw_clear = 1'b0;
		writeEn = 1'b0;
		case (curr_state)
			CLEAR_BOARD: begin
				// TODO
			end
			GET_PIECE: begin
				curr_piece = piece_rng;
				curr_rotation = 2'b00;
			end
			DETECT_COLLISION: begin
				module_select = 3'b001;
			end
			DETECT_COLLISION_WAIT: begin
				module_select = 3'b001;
			end
			ERASE_OLD: begin
				X_to_Draw = curr_anc_X;
				Y_to_Draw = curr_anc_Y;
				draw_clear = 1'b1;
				writeEn = 1'b1;
				module_select = 3'b010;
			end
			DRAW_NEW: begin
				X_to_Draw = new_anc_X;
				Y_to_Draw = new_anc_Y;
				writeEn = 1'b1;
				module_select = 3'b010;
			end
			DRAW_NEW_WAIT: begin
				module_select = 3'b100;
			end
		endcase
	end
	
	// RNG for pieces
	reg [2:0] piece_rng;
	
	always @(posedge clk) begin
		if (~reset_n) begin 
			curr_state <= CLEAR_BOARD;
			curr_anc_X <= 4'b0000;
			curr_anc_Y <= 5'b00000;
			piece_rng <= 3'b000;
		end
		else begin
			curr_state <= next_state;
			if (piece_rng < 3'b111) piece_rng <= piece_rng + 1'b1;
			else piece_rng <= 3'b000;
			if (curr_state == DRAW_NEW_WAIT) begin
				curr_anc_X <= new_anc_X;
				curr_anc_Y <= new_anc_Y;
			end
		end
	end
endmodule
