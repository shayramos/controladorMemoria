module MemoryController(Blank, Hsync, Vsync, R, G, B, CoordX, CoordY, 
								Clock50Mhz, Reset, data1, data2,
								addr, bank, command, clk_enable);

	output wire Blank, Hsync, Vsync;
	output [7:0] R, G, B;
	input [15:0] data1, data2;
	output [12:0] addr;
	output [1:0] bank;
	output [3:0]command;
	output clk_enable;
	input Clock50Mhz, Reset;
	input[9:0] CoordX, CoordY;
	
VGAController inst_VGA(.read_en(read_en),
							  .Blank(Blank), 
							  .Hsync(Hsync), 
							  .Vsync(Vsync), 
							  .R(R), 
							  .G(G), 
							  .B(B), 
							  .Clock25(Clock25),
							  .Reset(Reset)
							  .Data(data));

						
controladorMemoria instControlador(.coord_X(CoordX),
											  .coord_Y(CoordY),
											  .clk(Clock75),
											  .rst(Reset),
											  .data1(data1),
											  .data2(data2),
											  .FIFO_full(FIFO_full),
											  .nwords_FIFO(nwords_FIFO),
											  .addr(addr),
											  .bank(bank),
											  .command(command),
											  .clk_enable(clk_enable),
											  .data_FIFO(data_FIFO),
											  .write_enable_FIFO(write_enable_FIFO));
				  

endmodule
