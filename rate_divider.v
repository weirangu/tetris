module rate_divider
	(
		input enable,
		input [24:0] rate,
		input clk,
		output rd
	);
	
	reg [24:0] counter;
	
	always @(posedge clk) begin
		if (~enable) counter <= rate;
		else counter <= counter - 1'b1;
	end
	
	assign rd = counter == 25'd0 ? 1'b1 : 1'b0;
endmodule