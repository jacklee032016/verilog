
/*
* test for both TX and RX (TX --> RX)
*/

`timescale 1ns/1ns

module uart_tb;

	reg clk, rst;
	reg uart_rx, tx_start;	 
	wire rx_ready;	   
	reg rx;
	
	reg [7:0] mem[0:8];
	reg [7:0] readMem[0:8];
	reg [7:0] tx_data;
	wire [7:0] rx_data;
	
	wire uart_tx, full;
	wire done;	
	
	
	uart
	#(
		.BAUDRATE_COUNT(5),
		.FIFO_SIZE(4)
	)
	uart_inst
	(
		.clk(clk),
		.rst(rst),	

		.rx_ready(rx_ready),		   
		.rx(rx), // read data from RX
		.rx_data(rx_data),			
		.uart_rx(uart_rx),	// RX pin
	
		.tx(tx_start),
		.tx_data(tx_data),
		.tx_full(full),
		.uart_tx(uart_tx)
	);
	
	/* TX --> RX */
	assign uart_rx = uart_tx; 
	
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
			rx = 1'b0;
			
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
		//			repeat(50) @(negedge(clk));
				end

			wait(full == 1);  
			$display("Data TX to FIFO @%d", $time);
				
			repeat(100)	 @(negedge(clk)); // tx be high when no data
//			$stop;					

			/* 2 cases for rx: high Z or 0, FIFO works */
			rx = 1'b0;
			for(i=0; i< 4; i = i+1)
				begin
					wait(rx_ready==1);
					$display("Data %d RX @%d", i, $time); 
					rx = 1'b1;
					readMem[i] = rx_data;
					repeat(5) @(negedge(clk));	
					rx = 1'b0;
					@(negedge(clk));
		//			#2000;
		//			repeat(50) @(negedge(clk));
				end
			
			$display("Data RX to FIFO %x %x %x %x", readMem[0], readMem[1], readMem[2], readMem[3]);
			
			
		end	
	
endmodule