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
		FALL = 3'b010,
		DRAW = 3'b110;

	reg [1:0] curr_state, next_state;
	
	// The following wires are wired into the RAM module
	wire [7:0] ram_addr;
	wire [5:0] ram_in, ram_out;
	wire ram_wren;
	
	ram_board board(ram_addr, clk, ram_in, ram_wren, ram_out);
	
	always @(negedge reset_n) begin
		next_state <= CLEAR_BOARD;
	end

	always @(posedge clk) begin
		curr_state <= next_state;
	end

	always @(*) begin
		case (curr_state) begin
			// TODO: State machine
		end
	end
endmodule
