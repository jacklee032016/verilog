/*
*
*/

`timescale 1ns/1ns

module uart_tx_tb;

	reg clk, rst;
	reg rx, tx_start;
	
	reg [7:0] mem[0:8];
	reg [7:0]  tx_data;
	
	wire tx, full;
	wire done;	
	
	
	uart
	#(
		.BAUDRATE_COUNT(5),
		.FIFO_SIZE(4)
	)
	tx_inst
	(
		.clk(clk),
		.rst(rst),
		// RX
		.uart_rx(rx),
		.rx_ready(), // output port, not connect
		.rx(1'b0), // input port, o
		.rx_data(),	// output port, no connection needed
		
		// TX
		.tx(tx_start),
		.tx_data(tx_data),
		.tx_full(full),
		.uart_tx(tx)
	);
	
	initial
		begin
			clk = 1'b0;
			forever
			clk = #5 ~clk;
		end
		
	integer i;
	
	initial
		begin
			rst = 1'b1;
			tx_start = 1'b0;
			
			mem[0] = 8'hA5;
			mem[1] = 8'h5A;
			mem[2] = 8'h3C;
			mem[3] = 8'hC3;
			mem[4] = 8'h69;
			mem[5] = 8'h96;
			mem[6] = 8'hA5;
			mem[7] = 8'h5A;
			
			#50;
			rst = 1'b0;
			
			for(i=0; i< 7; i = i+1)
				begin
					// 5 clock to begin tx
					repeat(1) @(negedge(clk));	
					tx_data = mem[i];
					tx_start = 1'b1;		   
					@(negedge(clk));
					tx_start = 1'b0;	// start only one tick cycle
					
		//			#2000;
//					repeat(10) @(negedge(clk));
				end

			wait(full == 1);
				
			repeat(100)	 @(negedge(clk)); // tx be high when no data
//			$stop;
			
			
		end	
	
endmodule

	