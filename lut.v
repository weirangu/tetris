module lut
	(
		input [2:0] block, // 0 is I, 1 is J, 2 is L, 3 is O, 4 is S, 5 is T,6 is Z.
		input [1:0] rotation,
		output reg [7:0] X, // [1:0] x1, [3:2] x2, [5:4] x3, [7:6] x4
		output reg [7:0] Y, // [1:0] y1, [3:2] y2, [5:4] y3, [7:6] y4
		output reg [5:0] colour
	);
	
	always @(*) begin
		case (block)
			3'b000: begin
				colour = 6'b00_11_11;
				if (rotation == 2'b00 || rotation == 2'b10) begin
					X = 8'b00_01_10_11;
					Y = 8'b00_00_00_00;
				end
					 
				else begin
					X = 8'b10_10_10_10;
					Y = 8'b00_01_10_11;
				end
			end
			
			3'b001: begin
				colour = 6'b00_00_11;
				if (rotation == 2'b00) begin
					X = 8'b00_00_01_10;
					Y = 8'b00_01_01_01;
				end
				else if (rotation == 2'b01) begin
					X = 8'b01_01_01_10;
					Y = 8'b00_01_10_00;
				end
				else if (rotation == 2'b10) begin
					X = 8'b00_01_10_10;
					Y = 8'b01_01_01_10;
				end
				else begin
					X = 8'b00_01_01_01;
					Y = 8'b10_10_01_00;
				end
			end
			
			3'b010: begin
				colour = 6'b11_10_00;
				
				if (rotation == 2'b00) begin
					X = 8'b00_01_10_10;
					Y = 8'b01_01_01_00;
				end
				
				if (rotation == 2'b01) begin
					X = 8'b01_01_01_10;
					Y = 8'b00_01_10_10;
				end
				
				if (rotation == 2'b10) begin
					X = 8'b00_00_01_10;
					Y = 8'b10_01_01_01; // may be a problem
				end
				
				else begin
					X = 8'b00_01_01_01;
					Y = 8'b00_00_01_10;
				end
			end
			
			// The Square
			3'b011: begin
				X = 8'b00_01_00_01;
				Y = 8'b00_00_01_01;
				colour = 6'b11_11_00;
			end
			
			3'b100: begin
				colour = 6'b00_11_00;
				if (rotation == 2'b00) begin
					X = 8'b00_01_01_10;
					Y = 8'b01_01_00_00;
				end
				
				else if (rotation == 2'b01) begin
					X = 8'b01_01_10_10;
					Y = 8'b00_01_01_10;
				end
				
				else if (rotation == 2'b10) begin
					X = 8'b00_01_01_10;
					Y = 8'b10_10_01_01;
				end
				
				else begin
					X = 8'b00_00_01_01;
					Y = 8'b00_01_01_10;
				end	
			end
			
			
			3'b101: begin
				colour = 6'b11_00_11;
				if (rotation == 2'b00) begin
					X = 8'b00_01_01_10;
					Y = 8'b01_01_00_01;
				end
				
				else if (rotation == 2'b01) begin
					X = 8'b01_01_01_10;
					Y = 8'b00_01_10_01;
				end
				
				else if (rotation == 2'b10) begin
					X = 8'b00_01_01_10;
					Y = 8'b01_01_10_01;
				end
				
				else begin
					X = 8'b00_01_01_01;
					Y = 8'b01_00_01_10;
				end
			end
			3'b110: begin
				X = 8'b00_01_01_10;
				Y = 8'b00_00_01_01;
				colour = 6'b11_00_00;
			end
			
			default: begin
				colour = 6'b00_11_11;
				if (rotation == 2'b00) begin
					X = 8'b00_01_10_11;
					Y = 8'b00_00_00_00;
				end
				
				else if (rotation == 2'b01) begin
					X = 8'b01_01_10_10;
					Y = 8'b01_10_01_00;
				end
				
				else if (rotation == 2'b10) begin
					X = 8'b00_01_01_10;
					Y = 8'b01_01_10_10;
				end
				
				else begin
					X = 8'b00_00_01_01;
					Y = 8'b10_01_01_00;
				end
			end
		endcase
	end
endmodule
