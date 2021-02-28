/*			
* 100MHz, baudrate 19200
* 19200x16(oversample) = 307200
* 307200x325 =  99,840,000
* 307200x326 = 100,147,200
* so N = 326
*/

module 
	baudrate_gen
	#(
	parameter  N= 326
	)
	(
		input clk, rst,
		output bd_tick
	);				   
	
	localparam WIDTH = log2(N);
	
	reg [WIDTH-1:0] cnt_r;
	
	always@(posedge(clk), posedge(rst))
		if(rst)			   
			cnt_r <= {WIDTH{1'b0} };
		else
			begin
				if(cnt_r == N-1)
					cnt_r = {WIDTH{1'b0} };
				else
					cnt_r <= cnt_r + 1;
			end	
			
	assign bd_tick = (cnt_r == N-1)? 1'b1:1'b0;
	
	function integer log2(input integer n);
		integer i;
	begin
		log2 = 1;
		for (i = 0; 2**i < n; i = i + 1)
			log2 = i + 1;
	end
	endfunction
	
endmodule
