/*
* SPI Flash test circuit
* read one byte from flash memory and show through UART TX
* 04. 3rd, 2021
*/

//`define		WITH_TEST


module SpiFlashTest
	(
		input CLK,
		input [4:0] BTN,
		input [7:0] SW,
		input UART_RXD,

		output [7:0] LED,
		output UART_TXD,	 
		
		output		spi_cs,
		output		spi_clk,
		input		spi_din,
		output		spi_dout,
		
		output 		spi_wp_n,
		output		spi_hold_n
	);
	
	/* signal to/from sub-components */
	logic wRst;				   
	logic	wRdFlashBtnDeb, wRdFlashBtnTick;
	
	// signal to/from spi flash
	logic 	[7:0]	wRdFlashData; 
	logic			wRdFlashDone;
	logic	[31:0]	rRdFlashAddress, wRdFlashAddress;
	logic			rRdFlashStart, wRdFlashStart;
	
	// signal to/from UART TX
	logic 	[7:0]	rUartTxData, wUartTxData;
	logic			rUartTxStart, wUartTxStart;	
	logic 			wUartTxFull;
	
	
	typedef enum
	{		
		S_IDLE,
		S_READ, // read from flash
		S_WAIT_TX	// wait UART TX FIFO is available
	}FLASH_T_STATE;			  
	
	FLASH_T_STATE	rState, wStateNext;
	
	// test signals
	logic rLed1, wLed1, rLed2, wLed2, rLed3, wLed3;
	
	// disable USPI/QSPI
	assign	spi_wp_n 	= 1'b1;
	assign	spi_hold_n	= 1'b1;

	
	assign wRst = BTN[0];
	
`ifdef	 WITH_TEST
`else
	STARTUPE2
    #(
		.PROG_USR("FALSE"), // Activate program event security feature. Requires encrypted bitstreams.
		.SIM_CCLK_FREQ(0.0) // Set the Configuration Clock Frequency(ns) for simulation.
	)
    start2_inst
	(
		.CFGCLK(),			// open, 1-bit output: Configuration main clock output
		.CFGMCLK(), 		// open, 1-bit output: Configuration internal oscillator clock output
		.EOS(), 			// open, 1-bit output: Active high output signal indicating the End Of Startup.
		.PREQ(),          	// 1-bit output: PROGRAM request to fabric output
		.CLK(CLK),            // 1-bit input: User start-up clock input
		.GSR(1'b0),           // 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
		.GTS(1'b0),           // 1-bit input: Global 3-state input (GTS cannot be used for the port name)
		.KEYCLEARB(1'b0),      // 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
		.PACK(1'b0),          // 1-bit input: PROGRAM acknowledge input
		.USRCCLKO(spi_clk),   // 1-bit input: User CCLK input
		.USRCCLKTS(1'b0),     // 1-bit input: User CCLK 3-state enable input
		.USRDONEO(1'b1),      // 1-bit input: User DONE pin output control
		.USRDONETS(1'b0)      // 1-bit input: User DONE 3-state enable output
	);
`endif  

	/* douncer for start signal */
	debouncer
`ifdef	 WITH_TEST
	#(
		.SYS_FREQ(1000), // 1KHz
		.TIME_LAPES(10), // time duration in time, default 10ms
		.TIME_BASE(1000) // 1000/1000*10 = 10 ticks for debouncer period
	)
`else	
`endif	
	deb_inst
	( 
		.clk(CLK),
		.rst(wRst),
		.sw(BTN[1]),
		.deb(wRdFlashBtnDeb),
		.tick(wRdFlashBtnTick)
	);


	/* Flash read */
	SpiFlash
	#(
`ifdef	 WITH_TEST
		.CLK_COUNT_HALF_PERIOD(4)
`else
		.CLK_COUNT_HALF_PERIOD(4)		// maximum 25MHz spi clock	
`endif	
	)		
	flash_inst
	(
		//system signal
		.iClk(CLK),
		.iRst(wRst),
		
		// flash interface
		.iWr(1'b0),// disable write to flash
		.iRd(rRdFlashStart),
		.iAddr(rRdFlashAddress),
		.iDataIn(8'hz),  // data written to flash
		
		.oDataOut(wRdFlashData), // data read from flash
		.oDone(wRdFlashDone),
		
		// SPI signal
		.oSpiCs(spi_cs),
		.oSpiClk(spi_clk),
		.oSpiMosi(spi_dout),
		.iSpiMiso(spi_din)
	);
	
	
	uart	 
`ifdef	WITH_TEST

/*	only used in simulation*/
	#(
		.BAUDRATE_COUNT(5)
	)
`else
/*	default 19200, eg count as 326 
	#(
		.BAUDRATE_COUNT(5)
	)
*/	
`endif	
	uart_inst
	(
		.clk(CLK),
		.rst(wRst),	

		/* RX */
		.rx_ready(), // not connect
		.rx(1'b0), // btn's tick
		.rx_data(),			
		.uart_rx(UART_RXD),	// RX pin

		/* TX port */
		.tx(rUartTxStart),
		.tx_data(rUartTxData),	
		.tx_full(wUartTxFull), // not connect
		.uart_tx(UART_TXD)

	);					
	

	always_ff @(posedge CLK or posedge wRst)
	begin
		if(wRst) begin			
			rState <= S_IDLE;
			rRdFlashStart <= 1'b0; 
			rRdFlashAddress <= 32'h00_00_00_0F;
			
			rUartTxData <= 8'h00;
			rUartTxStart <= 1'b0;
			
			rLed1 <= 1'b0;
			rLed2 <= 1'b0;
			rLed3 <= 1'b0;
		end
		else begin
			rState <= wStateNext; 
			rRdFlashStart <= wRdFlashStart;
			rRdFlashAddress <= wRdFlashAddress;
			
			rUartTxData <= wUartTxData;
			rUartTxStart <= wUartTxStart;
			
			rLed1 <= wLed1;
			rLed2 <= wLed2;
			rLed3 <= wLed3;
		end
	end

	
	always_comb
	begin
		wStateNext = rState;			   
		wRdFlashStart = rRdFlashStart;
		wRdFlashAddress = rRdFlashAddress;
		
		wUartTxData = rUartTxData;
		wUartTxStart = rUartTxStart;
		
		wLed1 = rLed1;
		wLed2 = rLed2;
		wLed3 = rLed3;
		
		case (rState)
			S_IDLE: begin
				wRdFlashStart = 1'b0;
				wUartTxStart = 1'b0;
				
				if(wRdFlashBtnTick) begin
					wRdFlashStart = 1'b1;  // start read from flash
					wRdFlashAddress = rRdFlashAddress + 1;	 
					wStateNext = S_READ;
					wLed1 = 1'b0;
				end	
			end
			
			S_READ: begin
				wRdFlashStart = 1'b0;  // stop, so only one read for one debounced signal
				if(wRdFlashDone) begin // if read is ready
					wLed2 = 1'b1;
					wUartTxData = wRdFlashData;// tx data from flash
					if(wUartTxFull) begin 
						wStateNext = S_WAIT_TX;
					end
					else begin
						wUartTxStart = 1'b1;	// begin to tx
						wStateNext = S_IDLE;	// send to UART TX's FIFO, so it can read more at once
					end		
				end
				
			end
			
			S_WAIT_TX: begin	
				wLed3 = 1'b1;
				if(~wUartTxFull) begin
					wUartTxStart = 1'b1;
					wStateNext = S_IDLE;
				end	
			end
		endcase	
	end
/*	
	assign LED[0] = wRst;
	assign LED[1] = rLed1;
	assign LED[2] = rLed2;
	assign LED[3] = rLed3;		  
*/	
	assign LED = rUartTxData;
	
endmodule	
