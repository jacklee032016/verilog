/*
* test bench for SPI Flash 
* April 3rd, 2021	
*/

`timescale 1ns/1ns

`define	CLK_PERIOD		10

module spiFlashTb;
	
	logic clk;
	logic rst;	
	
	logic rWr, rRd;
	logic [31:0]	rAddress;
	logic [7:0]		rWrData;
	
	logic [7:0]		wRdData;
	logic wDone;
	
	logic wSpiCs, wSpiClk, wSpiMosi;
	logic rSpiMiso;
	
	
	SpiFlash
	#(
	.FREQ(400_000)
	)		
	inst
	(
		//system signal
		.iClk(clk),
		.iRst(rst),
		
		// flash interface
		.iWr(rWr),
		.iRd(rRd),
		.iAddr(rAddress),
		.iDataIn(rWrData),  // data written to flash
		
		.oDataOut(wRdData), // data read from flash
		.oDone(wDone),
		
		// SPI signal
		.oSpiCs(wSpiCs),
		.oSpiClk(wSpiClk),
		.oSpiMosi(wSpiMosi),
		.iSpiMiso(rSpiMiso)
	);
	
	
	initial	begin		
		fork
			tskGenClk;
			tskGenRst;
			tskReadFlash;
		join	  
	end

	task tskReadFlash;
	logic [7:0] flashValue = 8'hAA;
	begin
		#(50);
		rRd = 1'b1;
		rAddress = 32'h00336655; 
		repeat(2) @(negedge clk);
		rRd = 1'b0;
		rAddress = 0;

		repeat(8) @(negedge(wSpiClk)); // cmd
		repeat(24) @(negedge(wSpiClk)); // 3-byte address

		for(integer i=0; i< 8; i++) begin
			@(negedge(wSpiClk));
			rSpiMiso = flashValue[7];
			flashValue = {flashValue[6:0], 1'b1};
		end

		wait (wDone==1'b1);
		$display("Read one byte ends at %d", $time);
	end
	endtask
	
	
	task tskGenRst;
	begin
		rst = 1'b1;
		#(`CLK_PERIOD*2+7) rst = 1'b0;
	end	
	endtask
	
	task tskGenClk;
	begin
		clk = 1'b0;
		forever #(`CLK_PERIOD/2) clk = ~clk;
	end	
	endtask
	
endmodule	
