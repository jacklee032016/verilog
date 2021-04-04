/*
* SPI Flash controller demo
* read one byte from SPI flash 		 

* S25FL support mode 0(CPOL=0, CPHA=0) and 3(CPOL=1, CPHA=1)
* multiple bytes read/write (simple read flash transaction) on SPI bus without CS break and SCLK break
*/

module SpiFlash
	#(
	parameter CLK_COUNT_HALF_PERIOD = 4
	)						 
	(
		//system signal
		input logic			iClk,
		input logic			iRst,
		
		// flash interface
		input logic			iWr,
		input logic 		iRd,
		input logic [31:0]	iAddr, // 32 bit address
		input logic [7:0] 	iDataIn,  // data written to flash
		
		output logic [7:0]	oDataOut, // data read from flash
		output logic 		oDone,
		
		// SPI signal
		output	logic 		oSpiCs,
		output	logic		oSpiClk,
		output	logic		oSpiMosi,
		input	logic		iSpiMiso
	);


	localparam [7:0] 
		NOP			= 8'hFF,		// no cmd to execute
		WR_EN		= 8'h06,		// write enable
		WR_DI		= 8'h04,		// write disable
		RD_SR		= 8'h05,		// read status reg
		WR_SR		= 8'h01,		// write stat. reg	 

		RD_CMD		= 8'h03,		// read data
		FAST_RD		= 8'h0B,		// fast read data
		PAGE_PRO	= 8'h02,		// page program
		SEC_ERASE 	= 8'hD8,		// sector erase
		BLOCK_ERASE	= 8'hC7,		// bulk erase
		DEEP_DOWN 	= 8'hB9,		// deep power down
		READ_SIG 	= 8'hAB; 		// read signature

	typedef	enum
	{			 
		S_IDLE,
		S_CMD,
		S_ADDR_3,
		S_ADDR_2,
		S_ADDR_1,
		S_ADDR_0,
		S_READ,
		S_WRITE,
		S_DONE
	}FLASH_STATE;

	FLASH_STATE	rState;
	FLASH_STATE	wStateNext;
	
	logic [31:0] rAddress, wAddress;
	logic [7:0] rWrData, wWrData;
	logic [7:0] rDataToFlash;
	logic [7:0] wDataToFlash;
	logic rIsRead;
	logic wIsRead;
	
	logic [7:0]	rRdData, wRdData;
	
	logic rSpiStart;
	logic wSpiStart;
	
	
	logic rSpiCs, wSpiCs;
	
	// signals from SPI master
	logic [7:0]	wDataFromFlash;
	logic wSpiDone;	 
	
	// inst of SPI master
	SpiMaster
	#(
	.CLK_DIV_COUNT(CLK_COUNT_HALF_PERIOD)
	)
	spi_minst
	( 
		.iClk(iClk),
		.iRst(iRst),
/*		
		.iCpol(1'b1),
		.iCpha(1'b1),
*/		
		.iCpol(1'b1),
		.iCpha(1'b1),
		.iDin(rDataToFlash),
		.iStart(rSpiStart),
		
		.oDout(wDataFromFlash),
		.oReady(wSpiDone),
		
		// spi signals
//		.oSpiCs(oSpiCs),
		.oSpiClk(oSpiClk),
		.oSpiMosi(oSpiMosi),
		.iSpiMiso(iSpiMiso)
	);
	

	always_ff@(posedge iClk or posedge iRst)
	begin
		if(iRst) begin
			rState <= S_IDLE;		
			rAddress <= 0;
	
			rDataToFlash <= 8'h0;
			rIsRead <= 1'b0;	 
			
			rSpiStart <= 1'b0;
			rWrData <= 8'hz;  
			rRdData <= 8'hz;
			
			rSpiCs <= 1'b1;
		end
		else begin
			rState <= wStateNext;
			rAddress = wAddress;
			
			rDataToFlash <= wDataToFlash;
			rIsRead = wIsRead;
			
			rSpiStart <= wSpiStart;
			rWrData <= wWrData;	   
			rRdData <= wRdData;
			
			rSpiCs <= wSpiCs;
		end
	end

	
	always_comb
	begin		
		
		wStateNext = rState;	
		wAddress = rAddress;
		wDataToFlash = rDataToFlash;		 
		wIsRead = rIsRead;	  
		
		wSpiStart = rSpiStart;
		wWrData = rWrData;
		wRdData = rRdData;	
		
		wSpiCs = rSpiCs;
		
		case (rState)
			S_IDLE: begin 
				wSpiCs = 1'b1; // here S_IDLE state, means one transaction of flash has ended
				
				if(iWr || iRd) begin 
					wSpiCs = 1'b0;
					wStateNext = S_CMD;
					wAddress = iAddr;
					wSpiStart = 1'b1;	// start CMD tx at once
					if(iRd) begin
						wIsRead = 1'b1;
						wDataToFlash = RD_CMD;
					end	
					else begin
						wIsRead = 1'b0;
						wDataToFlash = PAGE_PRO;
						wWrData = iDataIn;
 					end	
				end
				
			end
			
			S_CMD: begin
				wSpiStart = 1'b0;
				if(wSpiDone) begin
					wSpiStart = 1'b1; // start address tx now
					wStateNext = S_ADDR_2;
					wDataToFlash = rAddress[23:16];
//					wStateNext = S_ADDR_3;
//					wDataToFlash = rAddress[31:24];
				end
			end
			
			S_ADDR_3: begin
				wSpiStart = 1'b0;  
				if(wSpiDone) begin
					wStateNext = S_ADDR_2;
					wSpiStart = 1'b1;
					wDataToFlash = rAddress[23:16];
				end	
			end
			
			S_ADDR_2: begin		
				wSpiStart = 1'b0;  
				if(wSpiDone) begin
					wStateNext = S_ADDR_1;
					wSpiStart = 1'b1;
					wDataToFlash = rAddress[15:8];
				end	
			end
			
			S_ADDR_1: begin
				wSpiStart = 1'b0;  
				if(wSpiDone) begin
					wStateNext = S_ADDR_0;
					wSpiStart = 1'b1;
					wDataToFlash = rAddress[7:0];
				end	
			end
			
			S_ADDR_0: begin
				wSpiStart = 1'b0;  
				if(wSpiDone) begin // addr[1] has been finished now
					wSpiStart = 1'b1;  // begin new spi tx/rx
					if(rIsRead) begin  // rx data
						wStateNext = S_READ;
					end	
					else begin
						wStateNext = S_WRITE;
						wDataToFlash = rWrData; // send 
					end	
				end	
			end
			
			S_READ: begin
				wSpiStart = 1'b0;  
				if(wSpiDone) begin
//					wSpiStart = 1'b1;
					wStateNext = S_DONE;
					wRdData = wDataFromFlash;// latch data from flash
				end	
			end
			
			S_WRITE: begin
				wSpiStart = 1'b0; 
				if(wSpiDone) begin 
//					wSpiStart = 1'b1;
//					wDataToFlash = rWrData;
					wStateNext = S_DONE;
				end	
			end
			
			S_DONE: begin
				wSpiStart = 1'b0;	   
				wStateNext = S_IDLE;
			end
			
			
		endcase
	end

	assign oDataOut = (rState==S_DONE)?rRdData:8'hz; // data read from flash
	assign oDone = (rState==S_DONE)?1'b1:1'b0;
	
	assign oSpiCs = rSpiCs;
endmodule

