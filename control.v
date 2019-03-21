module control
	(
		input reset_n,
		input go,
		input clk,
		output [7:0] X,
		output [6:0] Y,
		output [5:0] colour,
		output wren
	);
	
	localparam
		CLEAR_BOARD = 3'b000,
		CLEAR_BOARD_WAIT = 3'b001,
		GET_PIECE = 3'b011,
		DETECT_COLLISION = 3'b010,
		ERASE_OLD = 3'b110,
		DRAW_NEW = 3'b111,
		WAIT = 3'b101;

	reg [1:0] curr_state, next_state;
	
	// The following wires are wired into the RAM module
	wire [7:0] ram_addr;
	wire [5:0] ram_in, ram_out;
	wire ram_wren;
	
	ram_board board(ram_addr, clk, ram_in, ram_wren, ram_out);
	
	wire [4:0] curr_anc_X, new_anc_X;
	wire [5:0] curr_anc_Y, new_anc_Y;
	wire [2:0] curr_piece;
	wire [1:0] curr_rotation;
	
	/* 0 is FALLING PIECE
	*/
	wire [1:0] module_select; // Determines which module we're currently using
	wire [1:0] module_complete; // 1 on the clock cycle where the module finishes computation (and this is when the results can be used)
	
	/* MODULES */
	wire collision;
	falling_piece f(module_select[0], curr_anc_X, curr_anc_Y, curr_piece, reset_n, clk, ram_out, new_anc_X, new_anc_Y, collision, ram_addr, module_complete[0]);
	
	always @(negedge reset_n) begin
		next_state <= GET_PIECE;
	end

	always @(posedge clk) begin
		curr_state <= next_state;
	end

	always @(*) begin
		case (curr_state) begin
			GET_PIECE: begin
				curr_piece <= 4'b000;
				curr_rotation <= 2'b00;
				
				next_state <= DETECT_COllISION;
			end
			DETECT_COLLISION: begin
				module_select <= 2'b01;
				ram_wren <= 1'b0;
				
				// We need to wait until completion
				next_state <= module_complete[0] ? ERASE_OLD : DETECT_COLLISION;
			end
		end
	end
endmodule
