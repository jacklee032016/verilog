
/*
*
*/

`timescale 1ns/1ns

`define	CLK_PERIOD		10

module spiMasterTb;
	
	localparam CLK_DIV_COUNT = 10;
	
	logic clk;
	logic rst;
	
	logic CPOL = 1'b1;		  
	logic CPHA = 1'b1;
	
	logic [7:0] rInputData, rOutputData;
	logic rStart;
	logic wReady;
	
	logic wSpiCs;
	logic wSpiClk;
	logic wSpiMosi;
	logic rSpiMiso;
	
	
	SpiMaster
	#(
	.CLK_DIV_COUNT(CLK_DIV_COUNT)
	)
	inst
	( 
		.iClk(clk),
		.iRst(rst),
		
		.iCpol(CPOL),
		.iCpha(CPHA),
		
		.iDin(rInputData),
		.iStart(rStart),
		
		.oDout(rOutputData),
		.oReady(wReady),
		
		// spi signals
//		.oSpiCs(wSpiCs),
		.oSpiClk(wSpiClk),
		.oSpiMosi(wSpiMosi),
		.iSpiMiso(rSpiMiso)
	);
	
	
	initial
		begin
			fork 
			tskGenClk;
			tskGenReset;
			tskTestData;
			join
		end
		

	task tskTestData;  
	logic [7:0]	misoByte = 8'h3C; //8'h5A;		 
	integer i;
	begin					   
		
		#(`CLK_PERIOD*5+6);
		rInputData = 8'h5A; // MSB first, so first bit is 0
		rStart = 1'b1;
		
		// one pulse of start to trigger TX
		repeat(2) @(negedge(clk)); 
		rStart = 1'b0;
		rInputData = 8'bz;	 
		
		if(CPHA==1'b0) begin
			rSpiMiso = misoByte[7]; // CPHA=0
			for(integer i=0; i< 7; i++) begin
				if(CPOL==1'b0) // mode 0, SCLK later half period of SCLK
					@(negedge(wSpiClk)); // negedge output next data
				else
					@(posedge(wSpiClk));
					
				rSpiMiso = misoByte[7];
				misoByte = {misoByte[6:0], 1'b1};
			end					 
		end
		else begin // CPHA==1
			for(integer i=0; i< 8; i++) begin
				if(CPOL==1'b1) // mode 3, first edge, eg. negedge output data
					@(negedge(wSpiClk));
				else
					@(posedge(wSpiClk));
					
				rSpiMiso = misoByte[7];
				misoByte = {misoByte[6:0], 1'b1};
			end					 
		end	
		
		
		#2000;
	end
	endtask
		
	
	task tskGenClk;
	begin
		clk = 1'b0;
		forever clk = #(`CLK_PERIOD/2) ~clk;
	end
	endtask
	
	task tskGenReset;
	begin 
		rst = 1'b1;
		#(`CLK_PERIOD*4+3) rst = 1'b0;
	end
	endtask
	
endmodule

