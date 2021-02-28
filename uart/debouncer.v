/*
*
*/

module debouncer
	#(			
		parameter
		SYS_FREQ = 100_000_000,  // 100MHz
		TIME_LAPES = 10, // time duration in time, default 10ms
		TIME_BASE= 1000 // time unit; 1000: ms; 1_000_000: us

	)
	(
		input clk, rst,
		input sw,
		output deb,	/* debounced level */
		output tick /* debounced tick */
	);	 
	
	localparam COUNTER = SYS_FREQ/TIME_BASE*TIME_LAPES;
	localparam N = $clog2(COUNTER);
    initial $display("SYS_FREQ:%d, TIME_LAPES:%d, TIMEBASE:%d\nCOUNTER:%d, N:%d\n",

		SYS_FREQ, TIME_LAPES, TIME_BASE, COUNTER, N);
	
		
	wire clear_sig;
	
	reg [N-1: 0] cnt_r;
	reg deb_r;
	reg [1:0] deb_hist;
	reg [1:0] sigs;
	
	always@(posedge(clk), posedge(rst))
		if(rst)
			begin
				sigs <= 2'b00;
				cnt_r <= {N-1{1'b0}};
				deb_r <= 1'b0;
				deb_hist <= 2'b00;
			end
		else   
			begin		 
				sigs[0] <= sigs[1];
				sigs[1] <= sw;	
				
				deb_hist[0] <= deb_hist[1];
				deb_hist[1] <= deb_r;
				
				if(clear_sig)	
					begin
					cnt_r <= {N-1{1'b0}};
					end
				else if(cnt_r == COUNTER-1)	// output new db value
					begin
//					deb <= sw;	
					deb_r <= sigs[0];
					cnt_r <= {N-1{1'b0}};
					end
				else	
					begin
					cnt_r <= cnt_r + 1;
					end
			end
			
	// assign clear_sig = ~sigs[0] & sigs[1];		  
	assign clear_sig = sigs[0] ^ sigs[1]; // XOR, 1 when 2 signals are different	
	assign deb = deb_r;
	assign tick = ~deb_hist[0] & deb_hist[1]; // only tick out when from 0-->1
	
endmodule
