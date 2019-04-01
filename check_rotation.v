module check_rotation
	(
		input enable,
		input [4:0] X_anchor,
		input [5:0] Y_anchor,
		input [2:0] block,
		input [1:0] curr_rotation,
		input clk,
		input [5:0] ram_Q,
		output reg rotate_collides,
		output reg [7:0] ram_addr,
		output reg complete
	);
	
	reg [1:0] counter; // A counter for the clock, for us to check the 4 blocks of a tetromino
	wire [7:0] coord_x, coord_y; // The offsets of the new block

	lut b(block, (curr_rotation + 1'b1), coord_x, coord_y);
	
	always @(posedge clk) begin
		complete = 1'b0;
		if (~enable) begin
			counter = 2'b00;
			rotate_collides = 1'b0;
			else ram_addr = ((Y_anchor + coord_y[1:0]) * 7'b1010) + X_anchor + coord_x[1:0];
		end

		// Dealing with when the user want to move the piece left.
		else begin 
			case (counter)
				2'b00: begin
					rotate_collides = rotate_collides | (|ram_Q) | (Y_anchor + coord_y[3:2]) > 5'd23 | (X_anchor + coord_x[3:2]) >= 4'd9 | (X_anchor + coord_x[3:2]) <= 4'd0;
					ram_addr = ((Y_anchor + coord_y[3:2]) * 7'b1010) + X_anchor + coord_x[3:2];
				end
				2'b01: begin
					rotate_collides = rotate_collides | (|ram_Q) | (Y_anchor + coord_y[5:4]) > 5'd23 | (X_anchor + coord_x[3:2]) >= 4'd9 | (X_anchor + coord_x[3:2]) <= 4'd0;
					ram_addr = ((Y_anchor + coord_y[5:4]) * 7'b1010) + X_anchor + coord_x[5:4];
				end
				2'b10: begin
					rotate_collides = rotate_collides | (|ram_Q) | (Y_anchor + coord_y[7:6]) > 5'd23 | (X_anchor + coord_x[3:2]) >= 4'd9 | (X_anchor + coord_x[3:2]) <= 4'd0;
					ram_addr = ((Y_anchor + coord_y[7:6]) * 7'b1010) + X_anchor + coord_x[7:6];
				end
				2'b11: begin
					rotate_collides = rotate_collides | (|ram_Q) | (Y_anchor + coord_y[1:0]) > 5'd23 | (X_anchor + coord_x[3:2]) >= 4'd9 | (X_anchor + coord_x[3:2]) <= 4'd0;
					complete = 1'b1;
				end
			endcase
		end
		counter = counter + 1'b1;
	end
endmodule