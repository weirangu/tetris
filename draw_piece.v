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

module draw_tetromino
	(
		input enable,
		input [2:0] block,
		input [4:0] X_in,
		input [5:0] Y_in,
		input clear, // Determines whether we're clearing or not
		input clk,
		output reg [7:0] X_vga,
		output reg [6:0] Y_vga,
		output [5:0] colour_out,
		output reg complete
	);
	
	// The following convert board coordinates into screen coordinates
	wire [7:0] X_anchor;
	wire [6:0] Y_anchor;
	assign X_anchor = 8'b10000000 + (X_in * 3'b100);
	assign Y_anchor = 7'b00000100 + (Y_in * 3'b100);
	
	wire [7:0] coord_x, coord_y;
	wire [5:0] blk_colour;
	lut b(block, 2'b00, coord_x, coord_y, blk_colour);
	assign colour_out = clear ? 6'b000000 : blk_colour;
	
	reg [6:0] counter;
	
	always @(posedge clk) begin
		if (~enable) begin 
			counter <= 7'b0000000;
			complete <= 1'b0;
		end
		else begin
			case (counter[5:4])
				2'b00: begin
					X_vga <= counter[1:0] + X_anchor + (coord_x[1:0] * 3'b100);
					Y_vga <= counter[3:2] + Y_anchor + (coord_y[1:0] * 3'b100);
				end
				2'b01: begin
					X_vga <= counter[1:0] + X_anchor + (coord_x[3:2] * 3'b100);
					Y_vga <= counter[3:2] + Y_anchor + (coord_y[3:2] * 3'b100);
				end
				2'b10: begin
					X_vga <= counter[1:0] + X_anchor + (coord_x[5:4] * 3'b100);
					Y_vga <= counter[3:2] + Y_anchor + (coord_y[5:4] * 3'b100);
				end
				2'b11: begin
					X_vga <= counter[1:0] + X_anchor + (coord_x[7:6] * 3'b100);
					Y_vga <= counter[3:2] + Y_anchor + (coord_y[7:6] * 3'b100);
				end
			endcase
			counter <= counter + 1'b1;
		end
		if (counter == 7'b1000000) begin
			complete <= 1'b1;
			counter <= 7'b0000000;
		end
		else complete <= 1'b0;
	end
endmodule
