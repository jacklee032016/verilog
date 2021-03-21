/*
* Test PS2 keyboard on xvideo board
* RX simple scan code and send to UART TX
* BTN0: reset; SW0: en;
*/

`define		TEST_PS_KEY		// otherwise test ps2_rc


module ps2_key_test
	(
		input CLK,
		input [4:0] BTN,
		input [7:0] SW,
		input UART_RXD,
		
		input ps2_clk,
		input ps2_data,

		output [7:0] LED,
		output UART_TXD
		
	);


	wire rst;			
	wire deb_btn1;
	wire deb_tick;		
	wire [7:0] rd_data, wr_data;
	wire en;
	
	wire ascii_ready;
	wire [7:0] ascii;

	
	assign rst = BTN[0];
	assign en = SW[0];
	

`ifdef	TEST_PS_KEY	
	ps2_key
	#(
	.N(8)
	)
	key_inst
	(
		.clk(CLK), 
		.rst(rst),
		.en(en),
		.ps2c(ps2_clk), 
		.ps2d(ps2_data),
		.done(ascii_ready),
		.ascii(ascii)
	);		
`else
	ps2_rx
	#(
	.FILTER_STEPS(2)
	)
	key_inst
	( 
		.clk(CLK),
		.rst(rst),
		.en(en),
		.ps2c(ps2_clk),
		.ps2d(ps2_data),
		.done(ascii_ready),
		.data(ascii)
//		,.falling_edge_clk()
	);
`endif
	
	
	uart	 
`ifdef	TEST_PS_KEY

/*	only used in simulation
	#(
		.BAUDRATE_COUNT(5)
	)
	*/
`else
	#(
		.BAUDRATE_COUNT(5)
	)
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
		.tx(ascii_ready),
		.tx_data(wr_data),	
		.tx_full(), // not connect
		.uart_tx(UART_TXD)

	);					
							
	assign LED[0] = rst;
	assign LED[1] = en;
	assign LED[2] = ascii_ready;
	assign wr_data = ascii;
	
	
endmodule
	