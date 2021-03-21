/*
* system verilog
*/

//`define		TEST_TB

module ps2_rx 
	#(parameter
	FILTER_STEPS = 8
	)
	(
		input clk, rst,
		input ps2c,
		input ps2d,
		input en,	 
		output done,
		output [7:0] data
`ifdef	TEST_TB		
		,output falling_edge_clk
`endif
	);		 			 

	localparam RX_BITS = 10;	// 8 bit data, 1 parity, 1 stop 
	
	typedef	enum 
	{
		S_IDLE, 
//		S_START, first falling edge of ps2 clock indicates half period of START bit, so no other process for START bit
		S_DATA,
		S_DONE
	}state_t; 
	
	state_t		state_r, state_n;
	
	reg [FILTER_STEPS-1:0] filter_r;   
	reg [3:0] data_idx_r;		  
	reg [RX_BITS-1:0] rx_data_r;
	reg [FILTER_STEPS-1:0] filter_n; 
	reg [3:0] data_idx_n;
	reg [RX_BITS-1:0] rx_data_n;
	
	// only detect falling edge of ps2 clock, not data: when falling edge of ps2 clock, sampling new data bit. refer to figure 9.1
	wire falling_edge_clk; // one tick, falling edge of ps2 clock
	reg [1:0] falls; 
	wire falling;
	
	
	always_ff@(posedge(clk), posedge(rst))
		if(rst)
			begin
				state_r <= S_IDLE;
				filter_r <= {(FILTER_STEPS-1){1'b0}}; 
				rx_data_r <= {(RX_BITS-1){1'b0}};
				
				data_idx_r <= 4'b0000;
				falls <= 2'b00;
			end
		else
			begin
				state_r <= state_n;
				filter_r <= filter_n;	
				data_idx_r <= data_idx_n; 
				rx_data_r <= rx_data_n;
				
				falls[1] <= falls[0];
				falls[0] <= falling;
			end

	assign filter_n = {ps2c, filter_r[FILTER_STEPS-1:1]};
	assign falling = (filter_r == {(FILTER_STEPS-1){1'b1}} ) ? 1'b1:
			(filter_r == {(FILTER_STEPS-1){1'b0}})? 1'b0: falls[0];
			
	assign falling_edge_clk = falls[1] & ~ falls[0];
			
	always_comb
	begin
		state_n = state_r;	
		data_idx_n = data_idx_r;
		rx_data_n = rx_data_r;
		
		casex (state_r)
			S_IDLE:
			begin						  
				// when first falling_edge of ps2 clock, the ps2 data has been low for half period
				if(en & falling_edge_clk) 
					begin
						state_n = S_DATA;
						rx_data_n <= {(RX_BITS-1){1'b0}}; // zero rx_data
					end	
			end	
			
			S_DATA:
			begin
				if(falling_edge_clk) // sample data from the 2nd falling edge of ps2 clock
					begin// tx from b0 --> b7; RX, right shift
						if(data_idx_r == RX_BITS -1 )// when idx=9, it will rx the last bit(stop bit) and then exchange into DONE
							begin
								state_n = S_DONE;  
								data_idx_n = 4'b0000;
							end	
						else				 
							begin
								data_idx_n = data_idx_r + 1;
							end	
						rx_data_n = {ps2d, rx_data_r[RX_BITS-1:1]};							
					end	
			end
			
			S_DONE:
			begin
				state_n = S_IDLE;
				
			end
			
			default:
			begin
			end
			
		endcase	
	end
	
	assign done = (state_r == S_DONE)? 1'b1: 1'b0;
	assign data = (state_r == S_DONE)? rx_data_r[7:0]: 8'bz;
			
endmodule 
