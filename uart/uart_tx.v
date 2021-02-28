/*
* UART TX
*
*/		 

module uart_tx
	#(parameter
		DATA_BIT = 8,
		STOP_BIT = 1
	)
	(
		input clk, rst,
		input start, bd_tick,
		input wire [7:0] data,
		output wire tx,
		output wire tx_done
	);

	localparam [1:0]
		S_IDLE  = 2'b00,
		S_START = 2'b01, /* start bit */
		S_DATA  = 2'b10, // 8 data bits, from LSB
		S_STOP  = 2'b11;
	
	reg [1:0] state_r, state_n;
	reg [3:0] d_cnt_r, d_cnt_n; // max 8-bit data
	reg [5:0] tick_cnt_r, tick_cnt_n; // bd tick, max 32
	
	reg tx_reg, tx_reg_n;  
	reg [7:0] tx_data_r, tx_data_n;
	reg tx_done_r, tx_done_n;
	
	// register, state
	always@(posedge(clk), posedge(rst))
		if(rst)
			begin
				state_r <= S_IDLE;
				d_cnt_r <= 4'b0000;
				tick_cnt_r <= 6'b00_0000;
				
				tx_reg <= 1'b1;	   							
				tx_data_r <= 8'b0000_0000;
				tx_done_r <= 1'b0; /* when FIFO is full, the full can only be cleared after the first bytes has been sent out */
			end
		else
			begin
				state_r <= state_n;
				d_cnt_r <= d_cnt_n;
				tick_cnt_r <= tick_cnt_n;
				
				tx_reg <= tx_reg_n;			
				tx_data_r <= tx_data_n;
				tx_done_r = tx_done_n;
			end	
			
	// combinational circuit, next state			
	always@(*)		
		begin
			state_n = state_r;
			d_cnt_n = d_cnt_r;
			tick_cnt_n = tick_cnt_r; 
			
			tx_done_n = tx_done_r;	
			tx_reg_n = tx_reg;
			tx_data_n = tx_data_r;
			
			
			case (state_r)
				S_IDLE:
				begin 	 
					tx_done_n = 1'b0;
					if(start) // one tick can start TX
					begin	
						tick_cnt_n = 6'b00_0000;
						state_n = S_START;
						tx_data_n = data;
						
						tx_reg_n = 1'b0;
					end	
				end
				
				S_START:
				begin	
					// tx must wait 15 ticks, otherwise rx may think it as wrong stop signal
					if(tick_cnt_r == 16) // change in the first clock cycle when tick_cnt_r == 8
						begin
							tick_cnt_n = 6'b00_0000;   
							d_cnt_n = 4'b0000;
							state_n = S_DATA;  
							
							tx_reg_n = tx_data_r[0];   // LSB first
							tx_data_n = {1'b1, tx_data_r[7:1]};// pading 1, so it plays as stop bit
						end	  
					if(bd_tick)	
						tick_cnt_n = tick_cnt_r + 1;
				end
				
				S_DATA:
				begin 	
//					if(tick_cnt_r == 0)// 6'b00_0000)  
//						begin
//						end	
//else 
					if(d_cnt_r == 8)
						begin							
							d_cnt_n = 4'b0000;
							tick_cnt_n = 6'b00_0000;
							state_n = S_STOP;  
							
							tx_reg_n = 1'b1; // stop bit is high
						end	
					else if(tick_cnt_r == 16 )
						begin
							d_cnt_n = d_cnt_r +1;
							tick_cnt_n = 6'b00_0000;   
							
							tx_reg_n = tx_data_r[0];   // LSB first
							tx_data_n = {1'b1, tx_data_r[7:1]}; // pading 1, it plays as stop bit
						end
					else if(bd_tick)
						tick_cnt_n = tick_cnt_r + 1;
						
				end	
				
				S_STOP:	 				
				begin	 
					if(tick_cnt_r == 16) // first cycle when tick_cnt_r == 32
						begin			 
							tx_done_n = 1'b1;// one tick of done signal
							state_n = S_IDLE;
						end
					else if(bd_tick)
						tick_cnt_n = tick_cnt_r + 1;
				end
				
				default:
				begin
				end	
			endcase
		end

	assign tx = tx_reg;
	assign tx_done = tx_done_r;
	
endmodule
