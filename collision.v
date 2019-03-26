module collision
	(
		input enable,
		input [4:0] X_anchor,
		input [5:0] Y_anchor,
		input [3:0] block,
		input left,
		input right,
		input clk,
		input [5:0] ram_Q,
		output reg [4:0] X_out,
		output reg [5:0] Y_out,
		output reg collision,
		output reg [7:0] ram_addr,
		output reg complete
	);
	
	reg [1:0] counter; // A counter for the clock, for us to check the 4 blocks of a tetromino
	wire [5:0] colour;
	wire [7:0] coord_x, coord_y; // The offsets of the block
	reg collides_left, collides_right, move_horizontal; // This signal determines whether a piece can move left/right.

	lut b(block, 2'b00, coord_x, coord_y, colour);
	
	always @(posedge clk) begin
		complete = 1'b0;
		move_horizontal = 1'b0;
		if (~enable) begin
			counter = 2'b00;
			collision = Y_out > 5'd23 ? 1'b1 : 1'b0;
			collides_left = X_anchor > 1'd0 ? 1'b0 : 1'b1; // 0 means no collision, 1 means collision
			collides_right = X_anchor < 4'd9 ? 1'b0 : 1'b1;
			ram_addr = ((Y_anchor + coord_y[1:0] + 1'b1) * 4'b1010) + X_anchor + coord_x[1:0];
		end

		// Dealing with when the user want to move the piece left.
		else if (left) begin
			case (counter)
				2'b00: begin
					collides_left = collides_left | (|ram_Q);
					ram_addr = ((Y_anchor + coord_y[3:2]) * 4'b1010) + X_anchor + coord_x[3:2] - 1'b1;
				end
				2'b01: begin
					collides_left = collides_left | (|ram_Q);
					ram_addr = ((Y_anchor + coord_y[5:4] + 1'b1) * 4'b1010) + X_anchor + coord_x[5:4] - 1'b1;
				end
				2'b10: begin
					collides_left = collides_left | (|ram_Q);
					ram_addr = ((Y_anchor + coord_y[7:6] + 1'b1) * 4'b1010) + X_anchor + coord_x[7:6] - 1'b1;
				end
				2'b11: begin
					collides_left = collides_left | (|ram_Q);
					// Y_out = collides_left ? Y_anchor + 1'b1 : Y_anchor;  // We want to move down if can't move left.
					X_out = collides_left == 1'b0 ? X_anchor - 1'b1 : X_anchor;
					move_horizontal = ~collides_left;
					complete = 1'b1;
				end
			endcase
		end

		// Dealing with when the user wants to move the piece right
		else if (right) begin
			case (counter)
				2'b00: begin
					collides_right = collides_right | (|ram_Q) | (X_anchor + coord_x[3:2]) >= 4'd9;
					ram_addr = ((Y_anchor + coord_y[3:2]) * 4'b1010) + X_anchor + coord_x[3:2] + 1'b1;
				end
				2'b01: begin
					collides_right = collides_right | (|ram_Q) | (X_anchor + coord_x[5:4]) >= 4'd9;
					ram_addr = ((Y_anchor + coord_y[5:4] + 1'b1) * 4'b1010) + X_anchor + coord_x[5:4] + 1'b1;
				end
				2'b10: begin
					collides_right = collides_right | (|ram_Q) | (X_anchor + coord_x[7:6]) >= 4'd9;
					ram_addr = ((Y_anchor + coord_y[7:6] + 1'b1) * 4'b1010) + X_anchor + coord_x[7:6] + 1'b1;
				end
				2'b11: begin
					collides_right = collides_right | (|ram_Q) | (X_anchor + coord_x[1:0]) >= 4'd9;
					// Y_out = collides_right ? Y_anchor + 1'b1 : Y_anchor;  // We want to move down if can't move right.
					X_out = collides_right == 1'b0 ? X_anchor + 1'b1 : X_anchor;
					move_horizontal = ~collides_right;
					complete = 1'b1;
				end
			endcase
		end

		// Dealing with when the block is falling down i.e. no left/right.
		//else begin
			case (counter)
				2'b00: begin
					collision = collision | (|ram_Q) | (Y_anchor + coord_y[3:2]) > 5'd23;
					ram_addr = ((Y_anchor + coord_y[3:2] + 1'b1) * 4'b1010) + X_anchor + coord_x[3:2];
				end
				2'b01: begin
					collision = collision | (|ram_Q) | (Y_anchor + coord_y[5:4]) > 5'd23;
					ram_addr = ((Y_anchor + coord_y[5:4] + 1'b1) * 4'b1010) + X_anchor + coord_x[5:4];
				end
				2'b10: begin
					collision = collision | (|ram_Q) | (Y_anchor + coord_y[7:6]) > 5'd23;
					ram_addr = ((Y_anchor + coord_y[7:6] + 1'b1) * 4'b1010) + X_anchor + coord_x[7:6];
				end
				2'b11: begin
					collision = collision | (|ram_Q) | (Y_anchor + coord_y[1:0]) > 5'd23;
					if (~move_horizontal) begin
						Y_out = Y_anchor + 1'b1;
						X_out = X_anchor;
					end
					complete = 1'b1;
				end
			endcase
		//end
		counter = counter + 1'b1;
	end
endmodule