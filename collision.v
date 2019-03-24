module collision
	(
		input enable,
		input [4:0] X_anchor,
		input [5:0] Y_anchor,
		input [3:0] block,
		input clk,
		input [5:0] ram_Q,
		output [4:0] X_out,
		output [5:0] Y_out,
		output reg collision,
		output reg [7:0] ram_addr,
		output reg complete
	);
	
	reg [1:0] counter; // A counter for the clock, for us to check the 4 blocks of a tetromino
	wire [5:0] colour;
	wire [7:0] coord_x, coord_y; // The offsets of the block
	lut b(block, 2'b00, coord_x, coord_y, colour);
	
	always @(posedge clk) begin
		complete = 1'b0;
		if (~enable) begin
			counter = 2'b00;
			collision = Y_out > 5'd23 ? 1'b1 : 1'b0;
			ram_addr = ((Y_anchor + coord_y[1:0] + 1'b1) * 4'b1010) + X_anchor + coord_x[1:0];
		end
		else begin
			case (counter)
				2'b00: begin
					collision = collision & (|ram_Q);
					ram_addr = ((Y_anchor + coord_y[3:2] + 1'b1) * 4'b1010) + X_anchor + coord_x[3:2];
				end
				2'b01: begin
					collision = collision & (|ram_Q);
					ram_addr = ((Y_anchor + coord_y[5:4] + 1'b1) * 4'b1010) + X_anchor + coord_x[5:4];
				end
				2'b10: begin
					collision = collision & (|ram_Q);
					ram_addr = ((Y_anchor + coord_y[7:6] + 1'b1) * 4'b1010) + X_anchor + coord_x[7:6];
				end
				2'b11: begin
					collision = collision & (|ram_Q);
					complete = 1'b1;
				end
			endcase
		end
		counter = counter + 1'b1;
	end
	
	assign Y_out = Y_anchor + 1'b1;
	assign X_out = X_anchor;
endmodule