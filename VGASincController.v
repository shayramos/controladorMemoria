module VGASincController(clock, reset, blank, hsync, vsync, hcont, vcont);
	input reset, clock;
	output wire blank, vsync, hsync;
	
	output reg[9:0] hcont; 	//conta a quantidade de colunas 800
	output reg[9:0] vcont;	//conta a quantidade de linhas 525
	
	always@(posedge clock) begin
		if(reset) begin
			hcont <= 0;
			vcont <= 0;
		end 
		else begin
			hcont <= hcont+1;
			vcont <= vcont+1;
		end
		if(hcont>800 || vcont >525) begin
			hcont <= 0;
			vcont <= 0;
		end
	end
		
		assign hsync = !(hcont>655 & hcont<751); //96 pixels
		assign vsync = !(vcont>489 & vcont<492); //2 linhas
		assign blank = !((hcont>639 & hcont<801)||(vcont>480 & vcont<526));
		
endmodule
