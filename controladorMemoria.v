module calcBaseAddress(	input [9:0] coord_X,
						input [9:0] coord_Y,
						input clk,
						output reg [1:0] bank,
						output reg [12:0] row_addr,
						output reg [9:0] col_addr,
						output valid); // módulo para calcular o endereço base a partir das coordenadas dos pixels

	wire [24:0] num;
	assign valid = (coord_X < (1920 - 640)) & (coord_Y < (1440 - 480));
	assign num = coord_Y*1920 + coord_X;
	always @ (posedge clk) begin
		bank <= num[24:23];
		row_addr <= num[22:10];
		col_addr <= num[9:0];
	end


endmodule

module calcUpdatedAddress (	input [1:0] bank,
							input [12:0] row_addr,
							input [9:0] col_addr,
							output reg [1:0] next_bank,
							output reg [12:0] next_row,
							output reg [9:0] next_col); // módulo para calcular o próximo endereço a partir do atual


	always @ (*) begin
		next_col = 0;
		next_row = row_addr;
		next_bank = bank;
		if (col_addr < 1023) begin
			next_col = col_addr + 1;
		end
		else if (row_addr < 8191) begin
			next_row = row_addr + 1;
		end
		else begin
			next_bank = bank + 1;
			next_row = 0;
		end
	end

endmodule

module controladorMemoria 	(	input [15:0] data1,
					input [15:0] data2,
					input [9:0] coord_X,
					input [9:0] coord_Y,
					input clk,
					input rst,
					input FIFO_full,
					input [7:0] nwords_FIFO,
					output reg [12:0] addr,
					output reg[1:0] bank,
					output reg[3:0] command,
					output reg clk_enable,
					output reg [23:0] data_FIFO,
					output reg write_enable_FIFO); //modulo vai lidar diretamente com escrita e leitura na memoria
/* COMANDOS - Em ordem: nCS, nRAS, nCAS, nWE */
	parameter 	DESL = 4'b1111, //Device Deselect
			NOP = 4'b0111, //No Operation
			BST = 4'b0110, //Burst Stop
			READ = 4'b0101, //A10 = 0 => No auto precharge, A10 = 1 => Auto precharge
			WRITE = 4'b0100, //A10 = 0 => No auto precharge, A10 = 1 => Auto precharge
			ACT = 4'b0011, //Bank Activate
			PRE = 4'b0010, //A10 = 0 => Precharge selected bank, A10 = 1 => Precharge all banks
			REF = 4'b0001, //clk_enable = 0 => Self-Refresh, clk_enable = 1 => CBR Auto-Refresh
			MRS = 4'b0000; //Mode Register Set

	parameter	INICIAL = 5'b00000,
			FIRST_PRECHARGE = 5'b00001,
			AUTOREFRESH1 = 5'b00010,
			NOP1 = 5'b00011,
			AUTOREFRESH2 = 5'b00100,
			NOP2 = 5'b00101,
			LOADREGISTER = 5'b00110,
			NOP3 = 5'b00111,
			READY = 5'b01000,
			START_READ = 5'b01001,
			NOP_READ = 5'b01010,
			PUT_COL = 5'b01011,
			NOP_READ2 = 5'b01100,
			REFRESH_INIT = 5'b01101,
			NOP_REFRESH = 5'b01110,
			START_REFRESH = 5'b01111,
			EXIT_REFRESH = 5'b10000,
			END_REFRESH = 5'b10001,
			RECEIVE_DATA = 5'b10010;

	reg	clk_enable_next, valid;
	reg [3:0] command_next;
	reg [4:0] cs, ns;
	reg [15:0] counter, counter_next;
	reg [11:0] refresh_counter, refresh_counter_next;
	wire [2:0] base_bank;
	wire [12:0] base_row_addr;
	wire [9:0] base_col_addr;
	reg [1:0] curr_bank, next_bank;
	reg [12:0] curr_row_addr, next_row, addr_next;
	reg [9:0] curr_col_addr, next_col;
	wire FIFO_almost_full;

	calcBaseAddress calc(coord_X, coord_Y, clk, base_bank, base_row_addr, base_col_addr, valid);
	calcUpdatedAddress upd(curr_bank, curr_row_addr, curr_col_addr, next_bank, next_row, next_col);

	assign FIFO_almost_full = nwords_FIFO > 251;
	always @ (negedge clk) begin
		if (cs == READY & valid) begin
			if ({curr_bank, curr_row_addr, curr_col_addr} - {base_bank, base_row_addr, base_col_addr} < 640*480) begin
				curr_bank <= next_bank;
				curr_row_addr <= next_row;
				curr_col_addr <= next_col;
			end
			else begin
				curr_bank <= base_bank;
				curr_row_addr <= base_row_addr;
				curr_col_addr <= base_col_addr;
			end
		end
	end

	always @ (posedge clk) begin
		if (rst) begin
			cs <= INICIAL;
			counter <= 0;
			refresh_counter <= 0;
		end
		else begin
			counter <= counter_next; //zera o contador quando muda de estado
			cs <= ns;
			if (refresh_counter <= 3610)
				refresh_counter <= refresh_counter_next;
			else
				refresh_counter <= 0;

		end
	end

	always @ (*) begin
		data_FIFO = {data1,data2[15:8]};
	end

	//Decodificador de próximo estado
	always @ (*) begin
		case(cs)
			INICIAL: begin
				if (counter > 7500) //Delay de 100 us no inicio - Clock de 75 MHz
					ns = FIRST_PRECHARGE;
				else
					ns = INICIAL;
			end
			FIRST_PRECHARGE: begin
				if (counter > 7502) // trp 18 ns
					ns = AUTOREFRESH1;
				else
					ns = FIRST_PRECHARGE;
			end
			AUTOREFRESH1: begin
				ns = NOP1;
			end
			NOP1: begin
				if (counter > 7506)
					ns = AUTOREFRESH2;
				else
					ns = NOP1;
			end
			AUTOREFRESH2: begin
				ns = NOP2;
			end
			NOP2: begin
				if (counter > 7510)
					ns = LOADREGISTER;
				else
					ns = NOP2;
			end
			LOADREGISTER: ns = NOP3;
			NOP3: ns = READY;
			READY: begin
				if (refresh_counter > 3600) ns = REFRESH_INIT;
				else if (FIFO_full | FIFO_almost_full | (~valid)) ns = READY;
				else ns = START_READ;
			end
			START_READ: begin
				ns = NOP_READ;
			end
			NOP_READ: begin
				ns = PUT_COL;
			end
			PUT_COL: ns = NOP_READ2;
			NOP_READ2: ns = RECEIVE_DATA; //reset counter
			RECEIVE_DATA: begin
				if (counter > 2) ns = READY;
				else ns = RECEIVE_DATA;
			end
			REFRESH_INIT: begin
				ns = NOP_REFRESH;
			end
			NOP_REFRESH: ns = START_REFRESH;
			START_REFRESH: begin
				if (counter > 2) ns = EXIT_REFRESH;
				else ns = START_REFRESH;
			end
			EXIT_REFRESH: begin
				if (counter > 6) ns = END_REFRESH;
				else ns = EXIT_REFRESH;
			end
			END_REFRESH: ns = READY;
			default: ns = INICIAL;
		endcase
	end
	always @ (negedge clk) begin
		command <= command_next;
		addr <= addr_next;
	end
	always @ (*) begin
		clk_enable = 1'b1;
		addr = 13'b0;
		write_enable_FIFO = 1'b0;
		bank = 2'b0;
		command_next = NOP;
		counter_next = counter + 1;
		case (cs)
			INICIAL: begin
			end
			FIRST_PRECHARGE: begin
				command_next = PRE;
				addr_next[10] = 1;
			end
			AUTOREFRESH1: begin
				command_next = REF;
			end
			AUTOREFRESH2: command_next = REF;
			LOADREGISTER: begin
				addr_next[9:0] = 10'b0000100010;
				command_next = MRS;
			end
			READY: begin
				counter_next = 0;
				if (refresh_counter > 3600) begin
					command_next = PRE;
					addr_next[10] = 1;
				end
				else if (FIFO_full | FIFO_almost_full | (~valid)) command_next = NOP;
				else begin
					addr_next = curr_row_addr;
					bank = curr_bank;
					command_next = ACT;
				end
			end
			START_READ: bank = curr_bank;
			NOP_READ: begin
				addr_next[9:0] = curr_col_addr;
				addr_next[10] = 1;
				bank = curr_bank;
			end
			NOP_READ2: counter_next = 0;
			RECEIVE_DATA: begin
				write_enable_FIFO = 1;
			end
			NOP_REFRESH: begin
				clk_enable_next = 0;
				command_next = REF;
				counter_next = 0;
			end
			START_REFRESH: begin
				if (counter > 2) begin
					command_next  = NOP;
				end
				else begin
					clk_enable_next = 0;
				end
			end
			EXIT_REFRESH: begin
				command_next = REF;
			end
		endcase
	end


endmodule
