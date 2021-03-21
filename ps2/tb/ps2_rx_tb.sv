
`timescale 1ns/1ns

`define	PERIOD	10		 

`define	PS2_CLK_PERIOD		12 // : 8~10, OK, the least value is 8, because the minimum FILTER_STEPS is 2

module ps2_rx_tb;
	
	localparam	TEST_LOOPS = 6;
	
	reg clk, rst;
	
	reg ps2_data, ps2_clk;	 
	reg ps2_en;
	reg done;
	reg [7:0] rx_data;	 
	wire falling;		
	reg [9:0] tx_buf [TEST_LOOPS];
	reg [9:0] tx_data;
	
	ps2_rx
	#(
	.FILTER_STEPS(2)
	)
	rx_inst
	( 
		.clk(clk),
		.rst(rst),
		.ps2c(ps2_clk),
		.ps2d(ps2_data),
		.en(ps2_en),
		.done(done),
		.data(rx_data)
//		,.falling_edge_clk(falling)
	);

	initial
		begin
			fork
				ps2_gen;

				clk_gen;
				rst_gen;   
			join
		end

	task ps2_gen;	 
	integer data_idx;
	
	begin			
		tx_buf = {10'h23C, 10'h25A, 10'h2A5, 10'h2C3, 10'h269, 10'h296};
		
		// initial ps2 signals as high
		ps2_data = 1'b1;
		ps2_clk = 1'b1;
		
			ps2_en = 1'b1; // enable ps2 rx
		#100;	
		for(data_idx = 0; data_idx< TEST_LOOPS; data_idx++)
			begin:	  data_loop
			tx_data = tx_buf[data_idx];
			
			// ps2_data is half period earlier than ps2_clock
			ps2_data = 1'b0;
			repeat(`PS2_CLK_PERIOD/2) @(negedge(clk)); // delay half PS2 clock, then low ps2_data
			ps2_clk = 1'b0;
			
			for(integer i=0; i< 10; i++) // 8 bit data
				begin: byte_loop
					repeat(`PS2_CLK_PERIOD/2) @(negedge(clk));
					ps2_data = tx_data[i];
					ps2_clk = 1'b1; // rising edge of ps2 clock
					repeat(`PS2_CLK_PERIOD/2) @(negedge(clk)); 
					ps2_clk = 1'b0; // falling edge of ps2 clock, sampling moment
				end : byte_loop
	
			repeat(`PS2_CLK_PERIOD/2) @(negedge(clk));
			ps2_data = 1'b1;
	//		repeat(`PS2_CLK_PERIOD/2) @(negedge(clk)); // delay half PS2 clock, then low ps2_data
			ps2_clk = 1'b1;
			#100;

		end : data_loop
		
		repeat(`PS2_CLK_PERIOD/2) @(negedge(clk));
		ps2_data = 1'b1;
//		repeat(`PS2_CLK_PERIOD/2) @(negedge(clk)); // delay half PS2 clock, then low ps2_data
		ps2_clk = 1'b1;
			
		$display("Simulation end at %d with %d bytes data", $time, data_idx);
	end
	endtask

		
	task ps2_gen_falling_tb;	 
	begin	
//		ps2_data = 1'b1;
		#100;
		
		for(integer i=1; i< 10; i++)
			begin
				ps2_data = 1'b0;
				repeat(i) @(negedge(clk)); 
				$display("low level of ps2_data at i %d %d", i, $time);
				ps2_data = 1'b1;
				repeat(10) @(negedge(clk));
			end	
	end
	endtask
	
	task clk_gen;
	begin
	end		
		clk = 1'b0;
		forever clk = #(`PERIOD/2) ~clk;
	endtask
	
	task rst_gen;
	begin	
		rst = 1'b1;
		#(5*`PERIOD+3) rst = 1'b0;
	end
	endtask
	
endmodule
