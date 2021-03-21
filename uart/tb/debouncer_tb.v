

`timescale 1ns/1ns

module debouncer_tb;
	
	localparam PERIOD= 10;
	
	reg clk, rst;
	reg button;
	
	wire deb;
	wire tick;
	integer i;
	
	debouncer 
		#(
			.SYS_FREQ(1000), // 1KHz
			.TIME_LAPES(10), // time duration in time, default 10ms
			.TIME_BASE(1000) // 1000/1000*10 = 10 ticks for debouncer period
		)			 

		dounce_inst
		(
			.clk(clk),
			.rst(rst),
			.sw(button),
			.deb(deb),
			.tick(tick)
		);
	
initial
	begin
		fork
			clk_gen;
			reset_gen;
			btn_pulse_gen;	
			capture_tick;
		join	
		
		$display("Simulation at %d", $time);
	end
	
	
		
task clk_gen;
	begin
		clk = 1'b0;
		forever 
		begin
			clk = #(PERIOD/2) ~clk;
		end	
	end
endtask

task reset_gen;
begin
	rst = 1'b1;
	#50;  
	rst = 1'b0;
end
endtask


task btn_pulse_gen;	  
	integer i;
begin		   

	/* test switch to 1 */
	button = 1'b0;			
	#50;  
	for(i=1; i< 20; i= i+1 )
		begin			
			/* from 1 --> 0 */
			button = 1'b1;
			repeat(i) @(negedge(clk));	
			
			button = 1'b0;
//					#100; 		  
			
			/* from 0 --> 1 */
			button = 1'b0;
			repeat(i) @(negedge(clk));	
			
			button = 1'b1;
//					#100; 
		end
	
	/* test switch to 0 */	
	button = 1'b1;			
end

endtask

task capture_tick;
begin	
	$monitor("At%d tick %d", $time, tick);
end

endtask

endmodule
