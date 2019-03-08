module robo_v(h,l,f,g,clk,rst);
output reg f, g;            
input h, l, clk, rst;
	
reg [3:0] estado_atual,estado_futuro;  
	parameter
	inicio=2'b00,
	parede_frente=2'b01,		
	parede_lado=2'b10,
	parede_frente_lado=2'b11;		
	
always@(estado_atual or h or l)        	  // Decodificador de proximo estado
begin
	estado_futuro = inicio;
	case(estado_atual)
		inicio:
		case({h,l})
			2'b00:estado_futuro = inicio;
			2'b01:estado_futuro = parede_lado;
			2'b11:estado_futuro = parede_frente_lado;		
			2'b10:estado_futuro = parede_frente;
		endcase	
	
		parede_frente:
		case({h,l})
			2'b00:estado_futuro = parede_frente;
			2'b10:estado_futuro = parede_frente;
			2'b11:estado_futuro = parede_frente_lado;		
			2'b01:estado_futuro = parede_lado;
		endcase
	
		parede_frente_lado:
		case({h,l})
			2'b11:estado_futuro = parede_frente_lado;	
			2'b00:estado_futuro = parede_frente_lado;	
			2'b10:estado_futuro = parede_frente;
			2'b01:estado_futuro = parede_lado;
		endcase
	
		parede_lado:
		case({h,l})
			2'b00:estado_futuro = inicio;
			2'b10:estado_futuro = inicio;
			2'b01:estado_futuro = parede_lado;
			2'b11:estado_futuro = parede_frente_lado;		
		endcase		
	endcase
end					

always@(posedge clk)			// Registrador
begin
		 if (rst)
              estado_atual<=inicio;
       else
              estado_atual<=estado_futuro;
end

always@(estado_atual or h or l)		// Decodificador de sa�da
begin
	case(estado_atual)
		inicio:
		case({h,l})
			2'b10:
			begin		f = 1'b0;
						g = 1'b1;
			end
			2'b11:
			begin 	f = 1'b0;
						g = 1'b1;
			end
			2'b00:
			begin 	f = 1'b1;
						g = 1'b0;
			end
			2'b01:
			begin		f = 1'b1;
						g = 1'b0;
			end						
		endcase
		parede_frente:
		case({h,l})
			2'b00:
			begin		f = 1'b0;
						g = 1'b1;
			end
			2'b10:	
			begin 	f = 1'b0;
						g = 1'b1;
			end
			2'b11:
			begin		f = 1'b0;
						g = 1'b1;
			end
			2'b01:
			begin		f = 1'b1;
						g = 1'b0;
			end
		endcase
		parede_lado:
		case({h,l})
			2'b11:
			begin		f = 1'b0;
						g = 1'b1;
			end
			2'b00:
			begin		f = 1'b0;
						g = 1'b1;
			end
			2'b10:
			begin		f = 1'b0;
						g = 1'b1;
			end
			2'b01:
			begin		f = 1'b1;
						g = 1'b0;
			end			
		endcase		
		parede_frente_lado:
		case({h,l})
			2'b00:	
			begin		f = 1'b0;
						g = 1'b1;
			end
			2'b11:
			begin 	f = 1'b0;
						g = 1'b1;
			end
			2'b10:
			begin 	f = 1'b0;
						g = 1'b1;
			end
			2'b01:
			begin 	f = 1'b1;
						g = 1'b0;
		end
		endcase
	endcase
end
endmodule