module VGADataController(clock, reset, data, hcont, vcont, read_en, R, G, B);

	input clock, reset;
	input[9:0] hcont, vcont; 
	input[23:0] data;
	output reg read_en;
	output reg[7:0] R, G, B;
	
	reg[2:0] estado_atual, estado_futuro;
	parameter Inicio = 			3'b000,
				 WaitNewLinha = 	3'b001,
				 Escreve = 			3'b010,
				 Espera1Clk = 		3'b011,
				 GetData =			3'b100;
	
	always@(posedge clock)begin
		if(reset) begin
			estado_atual <= Inicio;
		end
		else begin
			estado_atual <= estado_futuro;
		end
	end
	 
	 always@(*) begin
		estado_futuro = Inicio;
		
		case(estado_atual)
			Inicio: begin 
				read_en = 0;
				if(vcont>524 & hcont<798) begin
					estado_futuro = Espera1Clk;
				end 
				else begin 
					estado_futuro = Inicio;
				end
			end
			WaitNewLinha: begin
				read_en = 0;
				if(vcont>480) begin
					estado_futuro = Inicio;
				end 
				else begin 
					if(hcont>800 & vcont<481) begin 
						estado_futuro = Espera1Clk;
					end 
					else begin
						if(hcont<801) begin 
							estado_futuro = WaitNewLinha;
						end
					end 
				end
			end
			Escreve: begin
				if(hcont<640) begin
					read_en = 1;
					estado_futuro = Espera1Clk;
				end 
				else begin 
					if(hcont>639) begin
						read_en = 0;
						estado_futuro = WaitNewLinha;
					end
				end
			end			
			Espera1Clk: begin
				read_en = 1;
				estado_futuro = GetData;
			end				
			GetData: begin
				read_en = 1;
				R[7:0] = data[23:15];		//verificar ordem
				G[7:0] = data[15:7];
				B[7:0] = data[7:0];
				estado_futuro = Escreve;
			end
		endcase
	 end
	 
endmodule
