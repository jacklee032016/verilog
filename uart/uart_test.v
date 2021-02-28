/*
* test UART TX and RX on xvideo board
* 
*/

//`define	TEST_BENCH

module uart_test
	(
		input CLK,
		input [4:0] BTN,
		input [7:0] SW,
		input UART_RXD,
		
		output [7:0] LED,
		output UART_TXD
`ifdef	TEST_BENCH
		,output reg done
`endif
	);
	

	wire rst;			
	wire deb_btn1;
	wire deb_tick;		
	wire [7:0] rd_data, wr_data;

	
	assign rst = BTN[0];
	
	debouncer
//	debounce
`ifdef	 TEST_BENCH
	#(
			.SYS_FREQ(1000), // 1KHz
			.TIME_LAPES(10), // time duration in time, default 10ms
			.TIME_BASE(1000) // 1000/1000*10 = 10 ticks for debouncer period
	)
`else	
`endif	
	deb1_inst
	( 
		.clk(CLK),
		.rst(rst),
		.sw(BTN[1]),
		.deb(deb_btn1),
		.tick(deb_tick)
	);

// not permitted in vivado	
//	assign LED[0] = rst;
	
	
	uart	 
`ifdef	TEST_BENCH
	#(
		.BAUDRATE_COUNT(5)
	)
`else
`endif	
	uart_inst
	(
		.clk(CLK),
		.rst(rst),	

		/* RX */
		.rx_ready(), // not connect
		.rx(deb_tick), // btn's tick
		.rx_data(rd_data),			
		.uart_rx(UART_RXD),	// RX pin

		/* TX port */
		.tx(deb_tick),
		.tx_data(wr_data),	
		.tx_full(), // not connect
		.uart_tx(UART_TXD)

	);

	assign wr_data = rd_data + 1; 
	
	assign LED[0] = rst;
	assign LED[1] = deb_btn1;	
	
endmodule
