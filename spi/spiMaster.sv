
/*
* SPI master Controller
*
* SPI CS should be controlled by client, so CS can be enable across multiple SPI bytes
* SCLK should be no gap between multiple SPI bytes
*/

module SpiMaster
	#(
	parameter CLK_DIV_COUNT = 10	// count 0f half period of SCLK
	)
	( 						
		// system signals
		input iClk,
		input iRst,
		
		// spi configuration
		input iCpol,
		input iCpha,
		
		input	[7:0] iDin,
		input	iStart,
		
		output	[7:0] oDout,
		output	oReady,
		
		// spi signals
//		output	oSpiCs,	// client control SPI CS as their requirement
		output	oSpiClk,
		output	oSpiMosi,
		input	iSpiMiso
	
	);					
	
	
	logic [$clog2(CLK_DIV_COUNT*2)-1:0] rClkCnt;
	logic [$clog2(CLK_DIV_COUNT*2)-1:0] wClkCnt;

	typedef	enum
	{			 
		S_IDLE,
		S_WAIT,
		S_PHASE0,
		S_PHASE1
	}SPI_M_STATE;
	
	SPI_M_STATE  rState;
	SPI_M_STATE wStateNext;
	
	
	logic [7:0] rDataMosi;// data register for mosi
	logic [7:0] rDataMiso;	 
	logic [7:0] wDataMosi;
	logic [7:0] wDataMiso;
	
//	logic rSpiCs;
//	logic wSpiCs;
	logic rSpiClk;
	logic [2:0] rBitCnt;
	logic rDone;
	
	logic wSpiClk;
	logic [2:0]	wBitCnt;
	logic wDone;
	wire wClk; 
	
	always_ff@(posedge iClk or posedge iRst)
	begin
		if(iRst) begin
			rState <= S_IDLE;
			rClkCnt <= 0;//{(CLK_DIV_BITS-1){1'b0}};
//			rSpiCs <= 1'b1; // CS is high, deselected 
			
			rSpiClk <= (iCpol)?1'b1:1'b0; // CPOL is 1, default SCLK is high
			rBitCnt <= 3'h0;	
			
			rDone <= 1'b0;

			rDataMosi <= 8'h0;
			rDataMiso <= 8'h0;
		end						   
		else begin
			rState <= wStateNext;
			rClkCnt <= wClkCnt;
//			rSpiCs <= wSpiCs;
			
			rSpiClk <= wSpiClk;
			rBitCnt <= wBitCnt;
			
			rDone <= wDone;	
			
			rDataMosi <= wDataMosi;
			rDataMiso <= wDataMiso;
		end
			
	end
	
	
	always_comb
	begin
		wStateNext = rState;
		wClkCnt = rClkCnt;	
//		wSpiCs = rSpiCs; 
//		wSpiClk = rSpiClk;
		
		wBitCnt = rBitCnt;	
		wDone = rDone;	 
		wDataMosi = rDataMosi;
		wDataMiso = rDataMiso;
		
		case (rState)
			S_IDLE:			
			begin		 
				wClkCnt = 0;
//				wSpiCs = 1'b1; // no CS
				wDone = 1'b0;
				
				if(iStart)
					begin	 
						/* this is not combinational circuit, so change as following */
						// rDataMosi = iDin; // lock in data							 
						wDataMosi = iDin;
						
//						wSpiCs = 1'b0; // begin to CS  
						wBitCnt = 3'h0;	
							
						if(iCpha) // CPHA = 1: delay half SCLK
							begin
								wStateNext = S_WAIT;
							end	
						else
							wStateNext = S_PHASE0;
					end
			end		 
		
			S_WAIT:
			begin	 
				if(rClkCnt == CLK_DIV_COUNT-1 ) begin
					wStateNext = S_PHASE0;
					wClkCnt = 0;
				end
				else begin
					wClkCnt = rClkCnt +1;
				end
			end
			
			// master: output first half period of SCLK 
			S_PHASE0:
			begin				
				if(rClkCnt == CLK_DIV_COUNT-1) begin	 
					// when it is here, half period of SCLK has passed, so capture the MISO now
					// rDataMiso = {rDataMiso[6:0], iSpiMiso};
					// change to combin circuit
					wDataMiso = {rDataMiso[6:0], iSpiMiso};
					wStateNext = S_PHASE1;
					wClkCnt = 0;
				end
				else begin		
					wClkCnt = rClkCnt + 1;
				end
				
			end
			
			// master : output second half period of SCLK
			S_PHASE1:
			begin					   
				if(rClkCnt == CLK_DIV_COUNT-1) begin
					// whole period of SCLK ends now, so output next bit
					// rDataMosi = {rDataMosi[6:0], 1'b1}; // output MOSI process
					wDataMosi = {rDataMosi[6:0], 1'b1};
					if(rBitCnt == 7) begin // one byte has been finished now
						wStateNext = S_IDLE;
						wDone = 1'b1; // ready signal for one tick	  
						wBitCnt = 0;	
					end	
					else begin
						wStateNext = S_PHASE0; // next bit
						wBitCnt = rBitCnt + 1;
					end
					
					wClkCnt = 0;
					
				end
				else begin
					wClkCnt = rClkCnt + 1;
				end
			end
			
			
		endcase
	end	
	
	// rState maybe is better
	assign wClk = (rState==S_PHASE0 && iCpha) || (rState==S_PHASE1 && ~iCpha); // validate: 1; others: 0
	assign wSpiClk = (iCpol)?~wClk:wClk;// CPOL's validation is 0
	
	assign oDout  = (rDone)?rDataMiso:8'hz;
	assign oReady = rDone;
//	assign oSpiCs = rSpiCs;																	 
	assign oSpiClk = rSpiClk;
	
	// high impedence, other spi devices can talk, and output MOSI early, so it also work even CPHA=0, eg. MOSI is earlier than SCLK
	// assign oSpiMosi = (rSpiCs)?1'bz: rDataMosi[7];	
	assign oSpiMosi = rDataMosi[7];	
endmodule

