module rate_divider
	(
		input enable,
		input [24:0] rate,
		input [7:0] score,
		input down,
		input clk,
		output rd
	);
	
	reg [24:0] counter;
	
	wire [24:0] max_count;
	
	assign max_count = down ? 25'd4000000 : ((score < 4'd12) ? (25'd12500000 - (25'd500000 * score)) : (25'd6250000));
	
	always @(posedge clk) begin
		if (~enable) counter <= max_count;
		else counter <= counter - 1'b1;
	end
	
	assign rd = counter == 25'd0 ? 1'b1 : 1'b0;
endmodule