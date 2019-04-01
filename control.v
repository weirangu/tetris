module control
	(
		input reset_n,
		input go,
		input clk,
		input left,
		input right,
		input rotate,
		output reg [7:0] X,
		output reg [6:0] Y,
		output reg [5:0] colour,
		output reg writeEn,
		output reg [3:0] curr_state
	);
	
	localparam
		CLEAR_BOARD = 4'd0,
		CLEAR_BOARD_WAIT = 4'd1,
		GET_PIECE = 4'd2,
		GET_PIECE_WAIT = 4'd3,
		DETECT_COLLISION = 4'd4,
		DETECT_COLLISION_WAIT = 4'd5,
		WRITE_TO_RAM = 4'd6,
		SETUP_ERASE_OLD = 4'd7,
		ERASE_OLD = 4'd8,
		SETUP_DRAW_NEW = 4'd9,
		DRAW_NEW = 4'd10,
		DRAW_NEW_WAIT = 4'd11,
		DRAW_RAM = 4'd12,
		ROTATE_PIECE = 4'd13,
		WAIT = 4'd14;
		
	localparam speed = 25'b0101111101011110000100000; // .5Hz

	reg [3:0] /*curr_state,*/ next_state;
	
	// The following wires are wired into the RAM module
	reg [7:0] ram_addr;
	wire [5:0] ram_in, ram_out;
	wire ram_wren;
	
	ram_board board(ram_addr, clk, ram_in, ram_wren, ram_out);
	
	reg [4:0] curr_anc_X;
	reg [5:0] curr_anc_Y;
	wire [4:0] new_anc_X;
	wire [5:0] new_anc_Y;
	reg [2:0] curr_piece;
	reg [1:0] curr_rotation;
	reg [1:0] new_rotation;
	reg [2:0] piece_rng; // RNG for pieces

	reg [4:0] X_to_Draw;
	reg [5:0] Y_to_Draw;
	
	/* 0 is FALLING PIECE
	*/
	reg [4:0] module_select; // Determines which module we're currently using
	wire [4:0] module_complete; // 1 on the clock cycle where the module finishes computation (and this is when the results can be used)
	
	// 0 is detect collision
	// 1 is for draw piece
	// 2 is for rate divider
	// 3 is for adding to ram
	
	/* MODULES */
	wire collision;
	wire [7:0] collision_ram_addr;
	collision f(
		.enable(module_select[0]), 
		.X_anchor(curr_anc_X),
		.Y_anchor(curr_anc_Y), 
		.block(curr_piece),
		.curr_rotation(curr_rotation),
		.left(left),
		.right(right),
		.clk(clk), 
		.ram_Q(ram_out), 
		.X_out(new_anc_X), 
		.Y_out(new_anc_Y), 
		.collision(collision), 
		.ram_addr(collision_ram_addr), 
		.complete(module_complete[0])
	);
	
	reg draw_clear;
	wire [7:0] draw_x;
	wire [6:0] draw_y;
	wire [5:0] draw_colour;
	draw_tetromino draw (
		.enable(module_select[1]),
		.block(curr_piece),
		.rotation(curr_rotation),
		.X_in(X_to_Draw), 
		.Y_in(Y_to_Draw),
		.clear(draw_clear),
		.clk(clk), 
		.X_vga(draw_x), 
		.Y_vga(draw_y), 
		.colour_out(draw_colour),
		.complete(module_complete[1])
	);
	
	rate_divider rd(
		.enable(module_select[2]),
		.rate(speed),
		.clk(clk),
		.rd(module_complete[2])
	);

	wire [7:0] atr_ram_addr;
	add_to_ram atr(
		.enable(module_select[3]),
		.x_anc(new_anc_X),
		.y_anc(new_anc_Y),
		.block(curr_piece),
		.rotation(curr_rotation),
		.clk(clk),
		.ram_addr(atr_ram_addr),
		.wren(ram_wren),
		.data(ram_in),
		.complete(module_complete[3])
	);
	
	wire [7:0] draw_ram_addr;
	wire [7:0] draw_r_x;
	wire [6:0] draw_r_y;
	wire [5:0] draw_r_colour;
	draw_ram draw_r(
		.enable(module_select[4]),
		.clk(clk),
		.ram_Q(ram_out),
		.X(draw_r_x),
		.Y(draw_r_y),
		.colour(draw_r_colour),
		.ram_addr(draw_ram_addr),
		.complete(module_complete[4])
	);

	always @(*)
   	begin: state_table
		case (curr_state)
			CLEAR_BOARD: next_state = go ? CLEAR_BOARD_WAIT : CLEAR_BOARD;
			CLEAR_BOARD_WAIT: next_state = go ? CLEAR_BOARD_WAIT: GET_PIECE;
			GET_PIECE: next_state = GET_PIECE_WAIT; 
			GET_PIECE_WAIT : next_state = DETECT_COLLISION;
			DETECT_COLLISION: begin
				if (rotate) 
					next_state = ROTATE_PIECE;
				else if (module_complete[0]) 
					next_state = DETECT_COLLISION_WAIT;
				else
					next_state = DETECT_COLLISION;
			end
			DETECT_COLLISION_WAIT: next_state = collision ? WRITE_TO_RAM : SETUP_ERASE_OLD;
			ROTATE_PIECE: next_state = DETECT_COLLISION;
			WRITE_TO_RAM: next_state = module_complete[3] ? DRAW_RAM : WRITE_TO_RAM;
			DRAW_RAM: next_state = module_complete[4] ? GET_PIECE : DRAW_RAM;
			SETUP_ERASE_OLD: next_state = ERASE_OLD;
			ERASE_OLD: next_state = module_complete[1] ? SETUP_DRAW_NEW : ERASE_OLD;
			SETUP_DRAW_NEW: next_state = DRAW_NEW;
			DRAW_NEW: next_state = module_complete[1] ? DRAW_NEW_WAIT : DRAW_NEW;
			DRAW_NEW_WAIT: next_state = module_complete[2] ? DETECT_COLLISION : DRAW_NEW_WAIT;
			default: next_state = GET_PIECE;
		endcase
   end // state_table

	always @(*) 
	begin: enable_signals
		// Setting default values for all these signals
		X_to_Draw = 3'b000;
		Y_to_Draw = 3'b000;
		module_select = 4'b0000;
		writeEn = 1'b0;
		ram_addr = 8'b00000000;
		draw_clear = 1'b1;
		X = draw_x;
		Y = draw_y;
		colour = draw_colour;
		case (curr_state)
			CLEAR_BOARD: begin
				// TODO
			end
			GET_PIECE: begin
			end
			DETECT_COLLISION: begin
				ram_addr = collision_ram_addr;
				module_select = 5'b00001;
			end
			DETECT_COLLISION_WAIT: begin
				module_select = 5'b00001;
			end
			ROTATE_PIECE: begin
			end
			WRITE_TO_RAM: begin
				ram_addr = atr_ram_addr;
				module_select = 5'b01000;
			end
			DRAW_RAM: begin
				ram_addr = draw_ram_addr; 
				module_select = 5'b10000;
				X = draw_r_x;
				Y = draw_r_y;
				colour = draw_r_colour;
				writeEn = 1'b1;
			end
			SETUP_ERASE_OLD: begin
				X_to_Draw = curr_anc_X;
				Y_to_Draw = curr_anc_Y;
				module_select = 5'b00010; 
			end
			ERASE_OLD: begin
				X_to_Draw = curr_anc_X;
				Y_to_Draw = curr_anc_Y;
				X = draw_x;
				Y = draw_y;
				writeEn = 1'b1;
				module_select = 5'b00010;
			end
			SETUP_DRAW_NEW: begin
				X_to_Draw = new_anc_X;
				Y_to_Draw = new_anc_Y;
				module_select = 5'b00010;
			end
			DRAW_NEW: begin
				X_to_Draw = new_anc_X;
				Y_to_Draw = new_anc_Y;
				draw_clear = 1'b0;
				module_select = 5'b00010;
				X = draw_x;
				Y = draw_y;
				writeEn = 1'b1;
			end
			DRAW_NEW_WAIT: begin
				module_select = 5'b00100;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (~reset_n) begin 
			curr_state <= CLEAR_BOARD;
			curr_anc_X <= 4'd4;
			curr_anc_Y <= 1'd0;
			piece_rng <= 3'b000;
		end
		else begin
			curr_state <= next_state;
			if (piece_rng < 3'b111) piece_rng <= piece_rng + 1'b1;
			else piece_rng <= 3'b000;
			
			
			if (curr_state == ROTATE_PIECE) begin
				new_rotation <= curr_rotation + 1'b1;
			end
			
			if (curr_state == SETUP_DRAW_NEW) begin
				curr_rotation <= new_rotation;
			end
			
			if (curr_state == DRAW_NEW_WAIT) begin
				curr_anc_X <= new_anc_X;
				curr_anc_Y <= new_anc_Y;
			end
			
			if (curr_state == GET_PIECE) begin
				// Reset X and Y back to the top
				curr_piece <= piece_rng;
				curr_rotation <= 2'b00;
				curr_anc_X <= 4'd4;
				curr_anc_Y <= 1'd0;
			end
		end
	end
endmodule
