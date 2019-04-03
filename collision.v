module collision
	(
		input enable,
		input [4:0] X_anchor,
		input [5:0] Y_anchor,
		input [2:0] block,
		input [1:0] curr_rotation,
		input clk,
		input [5:0] ram_Q,
		output reg collides_left,
		output reg collides_right,
		output reg collides_down,
		output reg collides_rotate,
		output reg [7:0] ram_addr,
		output reg complete
	);
	
	reg [1:0] which_side;
	reg [2:0] counter; // A counter for the clock, for us to check the 4 blocks of a tetromino (where state 111 is setting up the first read)
	wire [7:0] coord_x, coord_y; // The offsets of the block
	wire [7:0] new_x, new_y; // The offsets of a new rotated block

	reg collides_left, collides_right, move_horizontal; // This signal determines whether a piece can move left/right.

	lut normal(block, curr_rotation, coord_x, coord_y);
	lut rotate(block, (curr_rotation + 1'b1), new_x, new_y);
	
	always @(posedge clk) begin
		complete = 1'b0;

		if (~enable) begin
			counter = 3'b111;
			which_side = 2'b00;
			collides_down = 1'b0;
			collides_left = 1'b0; // 0 means no collision, 1 means collision
			collides_right = X_anchor < 4'd9 ? 1'b0 : 1'b1;
			collides_rotate = 1'b0
		end

		// Dealing with when the user want to move the piece left.
		else begin 
			if (which_side == 2'b00) begin // left side
				case (counter)
					3'b000: begin
						collides_left = collides_left || (|ram_Q) || (X_anchor + coord_x[3:2]) <= 4'd0;
						ram_addr = ((Y_anchor + coord_y[3:2]) * 7'b1010) + X_anchor + coord_x[3:2] - 1'b1;
						counter = counter + 1'b1;
					end
					3'b001: begin
						collides_left = collides_left || (|ram_Q) || (X_anchor + coord_x[5:4]) <= 4'd0;
						ram_addr = ((Y_anchor + coord_y[5:4]) * 7'b1010) + X_anchor + coord_x[5:4] - 1'b1;
						counter = counter + 1'b1;
					end
					3'b010: begin
						collides_left = collides_left || (|ram_Q) || (X_anchor + coord_x[7:6]) <= 4'd0;
						ram_addr = ((Y_anchor + coord_y[7:6]) * 7'b1010) + X_anchor + coord_x[7:6] - 1'b1;
						counter = counter + 1'b1;
					end
					3'b011: begin
						collides_left = collides_left || (|ram_Q) || (X_anchor + coord_x[1:0]) <= 4'd0;
						counter = 3'b111;
						wnich_side = which_side + 1'b1;
					end
					3'b111: begin 
						ram_addr = ((Y_anchor + coord_y[1:0]) * 7'b1010) + X_anchor + coord_x[1:0] - 1'b1;
						counter = counter + 1'b1;
					end
					default:  ram_addr = ((Y_anchor + coord_y[1:0]) * 7'b1010) + X_anchor + coord_x[1:0] - 1'b1;
				endcase

			// Dealing with when the user wants to move the piece right
			else if (which_side = 2'b01) begin // right side
				case (counter)
					3'b000: begin
						collides_right = collides_right || (|ram_Q) || (X_anchor + coord_x[3:2]) >= 4'd9;
						ram_addr = ((Y_anchor + coord_y[3:2]) * 7'b1010) + X_anchor + coord_x[3:2] + 1'b1;
						counter = counter + 1'b1;
					end
					3'b001: begin
						collides_right = collides_right || (|ram_Q) || (X_anchor + coord_x[5:4]) >= 4'd9;
						ram_addr = ((Y_anchor + coord_y[5:4]) * 7'b1010) + X_anchor + coord_x[5:4] + 1'b1;
						counter = counter + 1'b1;
					end
					3'b010: begin
						collides_right = collides_right || (|ram_Q) || (X_anchor + coord_x[7:6]) >= 4'd9;
						ram_addr = ((Y_anchor + coord_y[7:6]) * 7'b1010) + X_anchor + coord_x[7:6] + 1'b1;
						counter = counter + 1'b1;
					end
					3'b011: begin
						collides_right = collides_right || (|ram_Q) || (X_anchor + coord_x[1:0]) >= 4'd9;
						counter = 3'b111;
						wnich_side = which_side + 1'b1;
					end
					3'b111: begin
						ram_addr = ((Y_anchor + coord_y[1:0]) * 7'b1010) + X_anchor + coord_x[1:0] + 1'b1;
						counter = counter + 1'b1;
					end
					default:  ram_addr = ((Y_anchor + coord_y[1:0]) * 7'b1010) + X_anchor + coord_x[1:0] + 1'b1;
				endcase
			end

			else if (which_side == 2'b10) begin // dealing with it falling down
				case (counter)
					3'b000: begin
						collides_down = collides_down || (|ram_Q) || (Y_anchor + coord_y[1:0]) > 5'd23;
						ram_addr = ((Y_anchor + coord_y[3:2] + 1'b1) * 7'b1010) + X_anchor + coord_x[3:2];
						counter = counter + 1'b1;
					end
					3'b001: begin
						collides_down = collides_down || (|ram_Q) || (Y_anchor + coord_y[3:2]) > 5'd23;
						ram_addr = ((Y_anchor + coord_y[5:4] + 1'b1) * 7'b1010) + X_anchor + coord_x[5:4];
						counter = counter + 1'b1;
					end
					3'b010: begin
						collides_down = collides_down || (|ram_Q) || (Y_anchor + coord_y[5:4]) > 5'd23;
						ram_addr = ((Y_anchor + coord_y[7:6] + 1'b1) * 7'b1010) + X_anchor + coord_x[7:6];
						counter = counter + 1'b1;
					end
					3'b011: begin
						collides_down = collides_down || (|ram_Q) || (Y_anchor + coord_y[7:6]) > 5'd23;
						counter = 3'b111;
						wnich_side = which_side + 1'b1;
					end
					3'b111: begin 
						ram_addr = ((Y_anchor + coord_y[1:0] + 1'b1) * 7'b1010) + X_anchor + coord_x[1:0];
						counter = counter + 1'b1;
					end
					default: ram_addr = ((Y_anchor + coord_y[1:0] + 1'b1) * 7'b1010) + X_anchor + coord_x[1:0];
				endcase
			end

			else begin // dealing with rotation
				case (counter)
				3'b000: begin
					collides_rotate = collides_rotate | (|ram_Q) | (Y_anchor + new_y[3:2]) > 5'd23 | (X_anchor + new_x[3:2]) >= 4'd9 | (X_anchor + new_x[3:2]) <= 4'd0;
					ram_addr = ((Y_anchor + new_y[3:2]) * 7'b1010) + X_anchor + new_x[3:2];
					counter = counter + 1'b1;
				end
				3'b001: begin
					collides_rotate = collides_rotate | (|ram_Q) | (Y_anchor + new_y[5:4]) > 5'd23 | (X_anchor + new_x[5:4]) >= 4'd9 | (X_anchor + new_x[5:4]) <= 4'd0;
					ram_addr = ((Y_anchor + new_y[5:4]) * 7'b1010) + X_anchor + new_x[5:4];
					counter = counter + 1'b1;
				end
				3'b010: begin
					collides_rotate = collides_rotate | (|ram_Q) | (Y_anchor + new_y[7:6]) > 5'd23 | (X_anchor + new_x[7:6]) >= 4'd9 | (X_anchor + new_x[7:6]) <= 4'd0;
					ram_addr = ((Y_anchor + new_y[7:6]) * 7'b1010) + X_anchor + new_x[7:6];
					counter = counter + 1'b1;
				end
				3'b011: begin
					collides_rotate = collides_rotate | (|ram_Q) | (Y_anchor + new_y[1:0]) > 5'd23 | (X_anchor + new_x[1:0]) >= 4'd9 | (X_anchor + new_x[1:0]) <= 4'd0;
					counter = 3'b111;
					wnich_side = which_side + 1'b1;
					complete = 1'b1; // Finally it completes
				end
				3'b111: begin 
					ram_addr = ((Y_anchor + new_y[1:0]) * 7'b1010) + X_anchor + new_x[1:0];
					counter = counter + 1'b1;
				end
				default: ram_addr = ((Y_anchor + new_y[1:0]) * 7'b1010) + X_anchor + new_x[1:0];
			endcase
			end
		end
	end
endmodule