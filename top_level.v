module top_level
	(
		CLOCK_50,	//	On Board 50 MHz
      KEY,			// Keys
      SW,			// Switches
		HEX0,
		HEX1,
		VGA_CLK, 	//	VGA Clock
		VGA_HS,		//	VGA H_SYNC
		VGA_VS,		//	VGA V_SYNC
		VGA_BLANK_N,//	VGA BLANK
		VGA_SYNC_N,	//	VGA SYNC
		VGA_R,   	//	VGA Red[9:0]
		VGA_G,	 	//	VGA Green[9:0]
		VGA_B,   		//	VGA Blue[9:0]
		PS2_CLK,
		PS2_DAT
	);

	input	CLOCK_50;				//	50 MHz
	input [9:0] SW;
	input [3:0] KEY;

	output VGA_CLK;   				//	VGA Clock
	output VGA_HS;					//	VGA H_SYNC
	output VGA_VS;					//	VGA V_SYNC
	output VGA_BLANK_N;			//	VGA BLANK
	output VGA_SYNC_N;				//	VGA SYNC
	output [9:0] VGA_R;   				//	VGA Red[9:0]
	output [9:0] VGA_G;	 				//	VGA Green[9:0]
	output [9:0] VGA_B;   				//	VGA Blue[9:0]
	output [6:0] HEX0, HEX1;
	inout PS2_CLK;
	inout PS2_DAT;
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [5:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	
	// Keyboard Wires
	wire left,right,rotate,down,go,enter;
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 2;
		defparam VGA.BACKGROUND_IMAGE = "bg.mif";
		
	wire resetn;
	assign resetn = !enter;
		
	// Keyboard module
	keyboard_tracker #(.PULSE_OR_HOLD(0)) keyboard(
			.clock(CLOCK_50),
			.reset(resetn),
			.PS2_CLK(PS2_CLK),
			.PS2_DAT(PS2_DAT),
			.a(left),
			.d(right),
			.s(down),
			.w(rotate),
			.space(go),
			.enter(enter)
	);
	
	wire [7:0] score;
	control ctl(
		.reset_n(resetn),
		.go(go),
		.clk(CLOCK_50),
		.left(left),
		.right(right),
		.rotate(rotate),
		.down(down),
		.X(x),
		.Y(y),
		.colour(colour),
		.writeEn(writeEn),
		.total_score(score)
	);
	
	hex_decoder hex0 (
		.hex_digit(score[3:0]),
		.segments(HEX0)
	);
	
	hex_decoder hex1 (
		.hex_digit(score[7:4]),
		.segments(HEX1)
	);
endmodule
