/*
*
*
*/

`timescale 1ns/1ns	

`define	CLK_PERIOD		10

module SpiFlashTestTb;

	logic 			rCLK;
	logic [4:0] 	rBTN;
	logic [7:0]		rSW;
	logic [7:0]		wLED;
	
	logic			wSpiCs;
	logic			wSpiClk;
	logic			wSpiMosi;
	logic			rSpiMiso;	 
	
	logic			wUartTx;
	
	SpiFlashTest
	test_ins
	(
		.CLK(rCLK),
		.BTN(rBTN),
		.SW(rSW),
		.UART_RXD(),

		.LED(wLED),
		.UART_TXD(wUartTx),	 
		
		.spi_cs(wSpiCs),
		.spi_clk(wSpiClk),
		.spi_din(rSpiMiso),
		.spi_dout(wSpiMosi),
		
		.spi_wp_n(),
		.spi_hold_n()
	);
	
	initial
		begin
			fork
			tskGenClk;
			tskGenReset;
			tskGenBtnDebounced;
			tskGenSignals;
			join
		end
		

	task tskGenBtnDebounced;
	begin		 
		#(55);
		rBTN[1] = 1'b1;	 
		repeat(50) @(posedge rCLK);//debouncer 50 clk
		rBTN[1] =1'b0;
	end
	endtask
	
	task tskGenSignals;
	logic [7:0] flashValue = 8'hAA;
	begin		 
		
		repeat(8) @(negedge(wSpiClk)); // cmd
		repeat(24) @(negedge(wSpiClk)); // 3-byte address

		for(integer i=0; i< 8; i++) begin
			@(negedge(wSpiClk));
			rSpiMiso = flashValue[7];
			flashValue = {flashValue[6:0], 1'b1};
		end
		
		
	end
	endtask
	
	
	task tskGenClk;
	begin	
		rCLK = 1'b0;
		forever rCLK = #(`CLK_PERIOD/2) ~rCLK;
	end
	endtask								 
	
	task tskGenReset;
	begin	
		rBTN[0] = 1'b1;
		#(`CLK_PERIOD*3+3) rBTN[0] = 1'b0;
	end
	endtask
	
endmodule
