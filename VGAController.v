module VGAController(read_en, Blank, Hsync, Vsync, R, G, B, Clock25, Reset, Data);

	input Clock25, Reset;
	input[23:0] Data;
	output read_en;
	output[7:0] R, G, B;
	output wire Blank, Vsync, Hsync;
	
	
	VGASincController inst_1(.clock(Clock25), 
									 .reset(Reset), 
									 .blank(Blank), 
									 .hsync(Hsync), 
									 .vsync(Vsync)); 
							  
	VGADataController inst_2(.clock(Clock25), 
									 .reset(Reset), 
									 .data(Data),
									 .read_en(read_en), 
									 .R(R), 
									 .G(G), 
									 .B(B));
endmodule