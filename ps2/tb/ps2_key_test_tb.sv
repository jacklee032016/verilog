
`timescale 1ns/1ns

`define	PERIOD		10

`define	PS2_CLK_PERIOD		20 // : 8~10, OK, the least value is 8, because the minimum FILTER_STEPS is 2


module ps2_key_test_tb;

	wire CLK;
	reg clk;
	wire UART_TXD, UART_RXD;
	reg [7:0] LED, SW;
	
	reg [4:0] BTN;
	reg ps2c, ps2d;	  
	reg rst;
	
	assign CLK = clk;
	assign BTN[0] = rst;
	
	
	ps2_key_test
	ps_ins
	(
		.CLK(CLK),
		.BTN(BTN),
		.SW(SW),
		.UART_RXD(UART_RXD),
		
		.ps2_clk(ps2c),
		.ps2_data(ps2d),

		.LED(LED),
		.UART_TXD(UART_TXD)
		
	);
	
	initial
		begin
			fork
			clk_gen;
			rst_gen;	
			ps2_send_scan_code;
			join 						 
			$display("Simulation ends at %d", $time);
		end
		
	
	// must be automatic; otherwise, tx_data only can be 2XX. 
	// because without automatic, tx_data is static, means it is allocated before run task
	task automatic ps2_send_one_byte(input [7:0] byte_data, input byte len);	
	
	begin 
		logic [9:0] tx_data = {2'b10, byte_data}; // 10 bit : 8 data bit + parity bit + stop bit
		#(`PERIOD*2);
		
		$display("tx_data: %x; data: %x", tx_data, byte_data);
		// start bit, half ps2_clk earlier
		ps2d = 1'b0;
		repeat(len/2) @(negedge(clk));
		for(integer i=0; i < 10; i++)
			begin					  
				ps2c = 1'b0; // first half of ps2_clk
				repeat(len/2) @(negedge(clk)); // sample time point
				
				ps2d = tx_data[i]; // second half of ps2_clk, beginning of new data bit
				ps2c = 1'b1;
				repeat(len/2) @(negedge(clk));
			end	

			
		ps2c = 1'b0; // the last half of ps2_clk  
		ps2d = 1'b1;
		repeat(len/2) @(negedge(clk)); 
		ps2c = 1'b1;
			
	end
	endtask	   
	
	task ps2_send_scan_code;
	byte scan_codes[3] = {8'h1c, 8'hf0, 8'h1c};
	begin				
		SW[0] = 1'b1;	  
		
		ps2c = 1'b1;
		ps2d = 1'b1; 
		#(`PERIOD*6);		
		for(integer i=0; i< 3; i++)
			begin
//				en = 1'b1; 
				ps2_send_one_byte(scan_codes[i], `PS2_CLK_PERIOD);
//				en = 1'b0;
				#(`PERIOD*20);		
			end		
			
		ps2c = 1'b1;
		ps2d = 1'b1;
		
	end
	endtask
	
	task clk_gen;
	begin
		clk = 1'b0;
		forever 
		clk = #(`PERIOD/2) ~clk; 
	end	
	endtask
	
	
	task rst_gen;
	begin  
		rst = 1'b1;
		#54;
		rst = 1'b0;
	end
	endtask
	
	
endmodule
