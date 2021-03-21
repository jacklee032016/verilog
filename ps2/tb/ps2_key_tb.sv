/*
* Test bench for ps2 keyboard
*/

`timescale 1ns/1ns

`define	PERIOD		10

`define	PS2_CLK_PERIOD		20 // : 8~10, OK, the least value is 8, because the minimum FILTER_STEPS is 2

`define		TEST_PS_KEY		// otherwise test ps2_rc

module ps2_key_tb;
	
	reg clk, rst;
	reg en;
	reg ps2d, ps2c;
	
	wire ascii_ready;
	wire [7:0] ascii;

`ifdef	TEST_PS_KEY	
	ps2_key
	#(
	.N(8)
	)
	key_inst
	(
		.clk(clk), 
		.rst(rst),
		.en(en),
		.ps2c(ps2c), 
		.ps2d(ps2d),
		.done(ascii_ready),
		.ascii(ascii)
	);		
`else
	ps2_rx
	#(
	.FILTER_STEPS(2)
	)
	key_inst
	( 
		.clk(clk),
		.rst(rst),
		.en(en),
		.ps2c(ps2c),
		.ps2d(ps2d),
		.done(ascii_ready),
		.data(ascii)
//		,.falling_edge_clk()
	);
`endif

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
		ps2c = 1'b1;
		ps2d = 1'b1; 
		#(`PERIOD*6);		
		for(integer i=0; i< 3; i++)
			begin
				en = 1'b1; 
				ps2_send_one_byte(scan_codes[i], `PS2_CLK_PERIOD);
				en = 1'b0;
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

