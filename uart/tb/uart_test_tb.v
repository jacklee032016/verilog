/*
* testbench for UART test circuit
* 02.21, 2021	
*/

`timescale 1ns/1ns

module uart_test_tb;

	reg CLK;
	wire UART_TXD, UART_RXD;
	reg [7:0] LED, SW;
	
	reg [4:0] BTN;
	
	wire tx, full;
	wire done;	
	

	uart_tx_test
	uart_test_inst
	(
		.CLK(CLK),
		.BTN(BTN),
		.SW(SW),
		.UART_RXD(UART_RXD),
		.LED(LED),
		.UART_TXD(UART_TXD),
		.done(done)
	);
	
	initial
		begin
			CLK = 1'b0;
			forever
			CLK = #5 ~CLK;
		end
		
	integer i;
	
	initial
		begin
			BTN[0] = 1'b1;
			BTN[1] = 1'b0;
			
			
			#50;
			BTN[0] = 1'b0;
			
			for(i= 1; i< 5;i ++)
				begin
					// 5 clock to begin tx
					repeat(5) @(negedge(CLK));	
					BTN[1] = 1'b1;		   
					repeat(50) @(negedge(CLK)); // debouncer 10 ticks
					BTN[1] = 1'b0;	// start only one tick cycle
					
					wait(done == 1);
		//			#2000;
					repeat(10) @(negedge(CLK));
				end
				
			repeat(100)	 @(negedge(CLK)); // tx be high when no data
			$stop;
			
			
		end	
	
endmodule
