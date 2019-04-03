module add_to_ram
    (
        input enable,
        input [4:0] x_anc,
        input [5:0] y_anc,
        input [2:0] block,
        input [1:0] rotation,
        input clk,
        output [7:0] ram_addr,
        output reg wren,
        output [5:0] data,
        output complete
    );
    
    reg [1:0] state; // the 3 states, setting up addr and data, enabling wren and disabling wren
    reg [2:0] curr_block; // Which block we're currently storing
    reg [4:0] curr_x;
    reg [5:0] curr_y; 
    
    coord_to_addr a(curr_x, curr_y, ram_addr);

    wire [7:0] x_offsets, y_offsets;
    lut l(block, rotation, x_offsets, y_offsets, data);

    always @(posedge clk) begin
        if (~enable) begin
            curr_block <= 3'b000;
            state <= 2'b00;
				wren <= 1'b0;
        end
        else begin
            case (state) 
                2'b00: begin
                    // We set address
                    case (curr_block)
                        2'b00: begin
                            curr_x <= x_anc + x_offsets[1:0];
                            curr_y <= y_anc + y_offsets[1:0];
                        end
                        2'b01: begin
                            curr_x <= x_anc + x_offsets[3:2];
                            curr_y <= y_anc + y_offsets[3:2];
                        end
                        2'b10: begin
                            curr_x <= x_anc + x_offsets[5:4];
                            curr_y <= y_anc + y_offsets[5:4];
                        end
                        2'b11: begin
                            curr_x <= x_anc + x_offsets[7:6];
                            curr_y <= y_anc + y_offsets[7:6];
                        end
                    endcase
						  state <= 2'b01;
                end
                2'b01: begin
                    wren <= 1'b1;
                    state <= 2'b10;
                end
                2'b10: begin
                    wren <= 1'b0;
                    state <= 2'b00;
						  curr_block <= curr_block + 3'b001;
                end
					 default: begin
						curr_block <= 3'b001;
						state <= 2'b00;
					 end
            endcase
        end
    end
	 
	 assign complete = curr_block[2];
endmodule

module coord_to_addr
	(
		input [4:0] X,
		input [5:0] Y,
		output [7:0] addr
	);
	
	assign addr = Y * 8'd10 + X;
endmodule