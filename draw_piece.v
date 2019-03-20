module draw_piece
	(
		input enable,	// Whether this module should be enabled (on posedge this resets)
		input clk,
		input [5:0] ram_Q,	// RAM input
		output [7:0] X,
		output [6:0] Y,
		output [5:0] colour,
		output [7:0] ram_addr,
		output finished	// 1 when this is finished drawing (if we're using this as a wren signal, we should invert it)
	);
	localparam
		X_START = 0,
		Y_START = 0; // We want to draw starting from the 4th row
		
	coord_to_addr coord(X, Y, ram_addr); // Converts the X, Y coordinates we have into an address that we can use for the RAM
	assign colour = ram_Q; // We draw the colour given to us by the RAM

	reg [3:0] board_location_x;	// Which part of the board we're in (for x)
	reg [4:0] board_location_y;	// Which part of the board we're in (for y)
	reg [3:0] offset;	// Which part of the square we're using, [1:0] is the x, [3:2] is the y

	always @(posedge clk) begin
		if (offset == 3'b000) begin
			// Skip to the next block
			if (board_location_x == 9) begin
				// We want to start drawing the next row
				board_location_x <= 0;
				board_location_y <= board_location_y + 1;
			end
			else begin
				// We can continue drawing the current row
				board_location_x <= board_location_x + 1;
			end
		end
		offset <= offset + 1;
	end

	always @(posedge enable) begin
		// Reset state
		offset <= 4'b0000;
		board_location_x <= 4'b0000;
		board_location_y <= 5'b00100; // We want to start drawing (0, 4) first, because the top 4 arrays are supposed to be invisible
	end
	
	assign X = board_location_x + X_START + offset[1:0];
	assign Y = board_location_y + Y_START + offset[3:2];
	assign finished = (board_location_x == 4'b1010) && (board_location_y == 5'b10100);
endmodule
