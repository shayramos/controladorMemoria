module VerificaCoord(coordX, coordY, outX, outY, enable);

	input [10:0]coordX, coordY;

	output wire enable;
	output reg[9:0] outX;
	output reg[8:0] outY;
	
	assign enable =((coordX+640)<1920)&((coordY+480)<1440);
	
	always@(*)begin
		if(enable) begin
			outX[9:0] = coordX[9:0]; 
			outY[8:0] = coordY[8:0];
		end
	end
	
endmodule
