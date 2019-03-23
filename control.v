module control
	(
		input reset_n,
		input go,
		input clk,
		output [7:0] X,
		output [6:0] Y,
		output [5:0] colour,
		output wren,
		output writeEn
	);
	
	localparam
		CLEAR_BOARD = 4'b0000,
		CLEAR_BOARD_WAIT = 4'b0001,
		GET_PIECE = 4'b0011,
		DETECT_COLLISION = 4'b0010,
		DETECT_COLLISION_WAIT = 4'b0110,
		SET_UP_RAM = 4'b1110,
		ERASE_OLD = 4'b1100,
		DRAW_NEW = 4'b1101,
		DRAW_NEW_WAIT = 4'b1111,
		WAIT = 4'b0111;

	reg [3:0] curr_state, next_state;
	
	// The following wires are wired into the RAM module
	wire [7:0] ram_addr;
	wire [5:0] ram_in, ram_out;
	reg ram_wren;
	
	ram_board board(ram_addr, clk, ram_in, ram_wren, ram_out);
	
	reg [4:0] curr_anc_X, new_anc_X;
	reg [5:0] curr_anc_Y, new_anc_Y;
	reg [2:0] curr_piece;
	reg [1:0] curr_rotation;

	reg [4:0] X_to_Draw;
	reg [5:0] Y_to_Draw;
	
	/* 0 is FALLING PIECE
	*/
	reg [1:0] module_select; // Determines which module we're currently using
	reg [1:0] module_complete; // 1 on the clock cycle where the module finishes computation (and this is when the results can be used)
								// 0 is detect collision
								// 1 is for draw piece
	
	/* MODULES */
	reg collision;
	falling_piece f(module_select[0], curr_anc_X, curr_anc_Y, curr_piece, reset_n, clk, ram_out, new_anc_X, new_anc_Y, collision, ram_addr, module_complete[0]);
	draw_tetromino draw (
		.enable(module_select[1]),
		.block(curr_piece),
		.X_anchor(X_to_Draw), 
		.Y_anchor(Y_to_Draw), 
		.reset(resetn), 
		.clk(clk), 
		.X_vga(X), 
		.Y_vga(Y), 
		.colour(colour),
		.writeEn(writeEn)
	);

	always @(posedge clk) begin
		curr_state <= next_state;
	end

	always@(*)
   begin: state_table
           case (curr_state)
               CLEAR_BOARD: next_state = go ? CLEAR_BOARD_WAIT : CLEAR_BOARD;
               CLEAR_BOARD_WAIT: next_state = go ? CLEAR_BOARD_WAIT: GET_PIECE;
               GET_PIECE: next_state = DETECT_COLLISION; 
               DETECT_COLLISION: next_state = module_complete[0] ? DETECT_COLLISION_WAIT : DETECT_COLLISION; 
               DETECT_COLLISION_WAIT: next_state = collision ? SET_UP_RAM : ERASE_OLD;
               ERASE_OLD: next_state = module_complete[1] ? DRAW_NEW : ERASE_OLD; 
               DRAW_NEW: next_state = module_complete[1] ? DRAW_NEW_WAIT : DRAW_NEW;
					DRAW_NEW_WAIT: next_state = DETECT_COLLISION;
           default:     next_state = CLEAR_BOARD;
       endcase
   end // state_table

	always @(*) begin
		// Setting default values for all these signals
		module_select = 0;
		module_complete = 0;
		collision = 0;
		ram_wren = 0;
		case (curr_state)
			GET_PIECE: begin
				curr_piece <= 4'b000;
				curr_rotation <= 2'b00;
				next_state <= DETECT_COLLISION;
			end
			DETECT_COLLISION: begin
				module_select <= 2'b01;
			end
			DETECT_COLLISION_WAIT: begin
				module_select <= 2'b01;
			end
			ERASE_OLD: begin
				X_to_Draw <= curr_anc_X;
				Y_to_Draw <= curr_anc_Y;
				module_select = 2'b10;
			end
			DRAW_NEW: begin
				X_to_Draw <= new_anc_X;
				Y_to_Draw <= new_anc_Y;
				module_select = 2'b10;
			end
			DRAW_NEW_WAIT: begin
				curr_anc_X <= new_anc_X;
				curr_anc_Y <= new_anc_Y;
			end
		endcase
	end
endmodule
