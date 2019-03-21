module collision
	( // Assumes the RAM write signal is low
		input [4:0] X,
		input [5:0] Y,
		input [5:0] ram_Q, // RAM output
		output collision,
		output [7:0] ram_addr // RAM address that this unit will use
	);
	
	coord_to_addr a(X, Y, ram_addr);
	assign collision = (| ram_Q) || Y > 23; // If the colour is black, then there is no block at X, Y, or if are past the boundaries then we also have a collision
endmodule

module coord_to_addr
	(
		input [4:0] X,
		input [5:0] Y,
		output [7:0] addr
	);
	
	assign addr = Y * 10 + X;
endmodule