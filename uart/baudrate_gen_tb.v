/*
* testbench for baudrate generator
*/								  

`timescale 1ns/1ns


module baudrate_gen_tb;
	
	localparam CNT = 10; // one tick per 10 clock cycles
	
	reg clk, rst;
	wire bd_tick;
	
	baudrate_gen 
		#(.N(CNT))
		baud_inst
		(
		.clk(clk),
		.rst(rst),
		.bd_tick(bd_tick)
		);
		
	initial
		begin
			clk = 1'b0;
			forever
			clk = #5 ~clk;
		end	
		
	initial
		begin
			rst = 1'b1;
			#20;
			rst = 1'b0;
			
			#1000;
			
			$stop;
		end	
			
endmodule
