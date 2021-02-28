/*
* UART RX
* Feb.25, 2021
*/

module uart_rx
	#(parameter
	DATA_BITS = 8
	)
	(
		input clk, rst,
		input bd_tick,
		input rx,
		output ready,
		output [DATA_BITS-1:0] rd_data
	);
	
	localparam [1:0]
		S_IDLE 	= 2'b00,
		S_START = 2'b01,
		S_DATA 	= 2'b10,
		S_STOP 	= 2'b11;
		
	localparam D_CNT_SIZE = 4, TICK_CNT_SIZE = 6;	

	reg [D_CNT_SIZE-1:0] d_cnt_r, d_cnt_n;	// max 7
	reg	[TICK_CNT_SIZE-1:0] tick_cnt_r, tick_cnt_n;	// max 32
	
	reg [1:0] state_r, state_n;
	reg [DATA_BITS-1:0] data_r, data_n;	  
	reg ready_r, ready_n;
	
	always@(posedge(clk), posedge(rst))
		if(rst)
			begin
				state_r <= S_IDLE;
				
				d_cnt_r <= {(D_CNT_SIZE-1){1'b0}}; 
				tick_cnt_r <= {(TICK_CNT_SIZE-1){1'b0}}; 
				
				data_r <= {(DATA_BITS-1){1'b0}};
				
				ready_r <= 1'b0;
			end
		else
			begin
				state_r <= state_n;
				
				d_cnt_r <= d_cnt_n; 
				tick_cnt_r <= tick_cnt_n; 	 
				
				data_r <= data_n;
				
				ready_r <= ready_n;
			end
				

	always@(*)
		begin
			
			state_n = state_r;
			
			d_cnt_n = d_cnt_r;
			tick_cnt_n = tick_cnt_r;
			
			data_n = data_r;	
			
			ready_n = ready_r;
			
			case (state_r)
				S_IDLE:
				begin 					 
					ready_n = 1'b0;
					data_n <= {(DATA_BITS-1){1'b0}};
					if(~rx)
						begin
							tick_cnt_n = {(TICK_CNT_SIZE-1){1'b0}};
							state_n = S_START;
						end	
				end	

				S_START:
				begin
					if(rx)
						begin
							state_n = S_IDLE;
						end
					else if(bd_tick)
						begin
							if(tick_cnt_r == 7)
								begin
									state_n = S_DATA;
									d_cnt_n = {(D_CNT_SIZE-1){1'b0}};
									tick_cnt_n = {(TICK_CNT_SIZE-1){1'b0}};
								end
							else
								begin
									tick_cnt_n = tick_cnt_r + 1;
								end	
						end	
				end	

				S_DATA:	 
				if(bd_tick)
					begin
						if(d_cnt_r == 8)
							begin
								tick_cnt_n = {(TICK_CNT_SIZE-1){1'b0}};
								state_n = S_STOP;
							end	
						else if(tick_cnt_r == 15)	
							begin
								data_n = {rx, data_r[DATA_BITS-1:1]};
								d_cnt_n = d_cnt_r + 1;
								tick_cnt_n = {(TICK_CNT_SIZE-1){1'b0}};
							end	
						else
							tick_cnt_n = tick_cnt_r + 1;
					end	
				
				S_STOP:
				if(bd_tick)
					begin		
						// no need to check rx state now
						if(tick_cnt_r == 15)
							begin
								ready_n = 1'b1;	 // ready for one tick
								state_n = S_IDLE;
							end	 
						else
							tick_cnt_n = tick_cnt_r + 1;
							
					end	
				
				default:
				begin
				end	
			endcase
			
		end	
	
	assign ready = ready_r;	
	assign rd_data = data_r; //(ready_r)? data_r: {(DATA_BITS-1){1'bz}};
	
endmodule

