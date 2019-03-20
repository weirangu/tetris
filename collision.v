module collision
	( // Assumes the RAM write signal is low
		input [7:0] X,
		input [6:0] Y,
		input [5:0] ram_Q, // RAM output
		output collision,
		output [7:0] ram_addr // RAM address that this unit will use
	);
	
	coord_to_addr a(X, Y, ram_addr);
	assign collision = | ram_Q; // If the colour is black, then there is no block at X, Y
endmodule

module coord_to_addr
	(
		input [7:0] X,
		input [6:0] Y,
		output [7:0] addr
	);
	
	assign addr = Y * 10 + X;
endmodule