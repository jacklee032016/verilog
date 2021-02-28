/*
* FIFO used for both TX and RX
*/

module fifo
	#(parameter	  
		WORD = 8,
		SIZE = 8 // buffer number in fifo
	)
	(
		input clk, rst,
		input wr,
		input [WORD-1:0] wr_data,
		input rd,
		output [WORD-1:0] rd_data,
		output full, empty
	);
	
	localparam N = $clog2(SIZE) + 1; // add i for the case SIZE not equal to 2**n
	
	reg [WORD-1:0] fifo_buf [0:SIZE-1];	   
	reg [N-1:0] wr_index, rd_index, wr_index_n, rd_index_n;
	reg [N-1:0] wr_suc_index, rd_suc_index; // add 2 regs, so circuit synthesis is more simpler
	
	// full/empty as DFF
	reg full_r, full_n, empty_r, empty_n;
	
	integer i;
	
	//
	always@(posedge(clk), posedge(rst))
		if(rst)				  
			begin
				empty_r <= 1'b1;
				full_r <= 1'b0;	   	 
				
				wr_index <= {(N-1){1'b0}};
				rd_index <=	{(N-1){1'b0}};
//				for(i=0; i<SIZE; i++) only SystemVerilog
				for(i=0; i<SIZE; i = i+1)
					fifo_buf[i] <= {(WORD-1){1'b0}};
			end
		else
			begin	   
				empty_r <= empty_n;
				full_r <= full_n;
				
				wr_index <= wr_index_n;
				rd_index <= rd_index_n;
				
				if( wr & ~full )
					fifo_buf[wr_index] <= wr_data;
			end

	/* when rd changed, but rd_index not, then read out wrong value 
	* and rd can be disabled at any time; if rd is disabled before rising edge of clk, it will read out high impedence
	*/		
//	assign rd_data = (rd & ~empty)?fifo_buf[rd_index]: {(WORD-1){1'bz}};
	/* read new value any time when rd_index changed, so it is sync read, not related with rd directly
	* how and when to use it is the problem of app circuit
	*/
	assign rd_data = fifo_buf[rd_index];
	
	
	// next state
	always@(*)	
		begin
		wr_index_n = wr_index;
		rd_index_n = rd_index;	 		
		
		/* only one add circuit for wr_index and rd_index after use these 2 signals */
		wr_suc_index = wr_index + 1;
		rd_suc_index = rd_index + 1;
		
		empty_n = empty_r;
		full_n = full_r;
		
		// casez because rd or wr is high z when only one op is executing
		casez ({wr, rd})		 
			
			/* more specific case must be the first case */
			2'b11:	// there is warning, but it works correctly 
			begin
				rd_index_n = rd_suc_index;
				wr_index_n = wr_suc_index;				
			end			
			
			2'b1z: // only write  
			if(~full_r)
				begin
					if(wr_index == SIZE -1) 
						wr_index_n = {N-1{1'b0}};	 
					else
	//					wr_index_n = wr_index + 1; 
						wr_index_n = wr_suc_index;
						
					empty_n = 1'b0;
					
					if(wr_index_n == rd_index)
						full_n = 1'b1;
				end
			
			2'bz1: // read only	
			if(~empty_r)
			begin
				if(rd_index == SIZE -1)
					rd_index_n = {(N-1){1'b0}};
				else
					rd_index_n = rd_suc_index;
					
				full_n = 1'b0;
				
				if(rd_index_n == wr_index)
					empty_n = 1'b1;
			end	 
			
			
			default: // neither read or write
			begin
			end
		endcase	
	end		

	assign empty = empty_r;
	assign full = full_r;
	
endmodule
