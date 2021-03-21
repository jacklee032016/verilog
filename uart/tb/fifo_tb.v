/*
* Test cases: 
*   overflow  (with rd=0 or rd=Z)
*	underflow (with wr=0 or wr=Z)
*   read-write simultaneously
*/

`timescale 1ns/1ns

// macro 
`define		PERIOD		10

module fifo_tb;
	
	localparam 
		WORD = 4,
		SIZE = 4;
		
	reg clk, rst;		
	reg wr, rd;
	wire full, empty;
	reg [WORD-1:0] wr_data;
	wire [WORD-1:0] rd_data;
	
	
	fifo
	#(	
	.WORD(WORD),
	.SIZE(SIZE)
	)	 
	fifo_inst
	(
		.clk(clk),
		.rst(rst),
		.wr(wr),
		.wr_data(wr_data),
		.rd(rd),
		.rd_data(rd_data),
		.full(full),
		.empty(empty)
	);
	
	

	initial
		begin	
			/* initialize */
			wr_data <= {(WORD-1){1'b0}};
			clk = 1'b0;
			wr = 1'b0; // must init these 2 signals
			rd = 1'b0;
/*			
			fork   
				clock_generator;
				reset_generator;
				tb_overflow;   
			join
			$display ("Simulation overflow ended @%d", $time);
		*/
			fork   
				clock_generator;
				reset_generator;
				tb_underflow;
//				tb_overflow;   
				debug_info;
			join
			$display ("Simulation end at %d", $time);
			
		end	

task tb_overflow;
	integer i;
begin 
	
//	for(i = 0; i< SIZE + 2; i++)
	for(i = 0; i< SIZE + 2; i = i+1)
	begin
		wr = 1'b1;
		wr_data =  {(WORD-1){1'b0}} + i;		
		@(negedge(clk)); 
		wr = 1'b0;
		@(negedge(clk)); 
	end
	wait (full == 1);
	$display("catch full signal on %d", $time);
end
endtask		  


// empty signal
task tb_underflow;
	integer i;
begin
	
	tb_overflow;
	
	$monitor("@%d: read data: %d", $time, rd_data);
//	for(i = 0; i< SIZE + 2; i++) // systemVerilog
	for(i = 0; i< SIZE + 2; i = i+1)
	begin
		rd = 1'b1;		 
		// rd_index has been changed at posedge(clk) ???
		@(negedge(clk)); 
		rd = 1'b0;
		@(negedge(clk)); 
	end
	wait (empty == 1);
	$display("catch empty signal on %d", $time);
end
endtask		  


task debug_info;
begin	
	$monitor("#%d full is %d", $time, full);
end
endtask
		
task clock_generator;
begin  
	forever
	clk = #(`PERIOD/1) ~clk;
end	
endtask	

task reset_generator;
begin	
	rst = 1'b0;
	# 10;
	rst = 1'b1;
	# 20;
	rst = 1'b0;
end			   
endtask		   


endmodule

	