/*
* test UART TX on xvideo board
* 
*/

`define	TEST_BENCH

module uart_tx_test
	(
		input CLK,
		input [4:0] BTN,
		input [7:0] SW,
		input UART_RXD,
		
		output reg [7:0] LED,
		output UART_TXD
`ifdef	TEST_BENCH
		,output reg done
`endif
	);
	
	
	// test states
	localparam [1:0] 
		S_IDLE = 2'b00,
		S_TX   = 2'b01,
		S_DONE = 2'b10;
		
	reg [1:0] test_state_r, test_state_n;
	

	wire rst;			
	wire deb_btn1;
	wire deb_tick;
	reg tx_start;				  
	reg [7:0] tx_mem [0:3];
	reg [7:0] tx_data;	  
	reg [3:0] c_cnt_r; // char counter 
//	reg tx_done;
	wire tx_done;
	
	assign rst = BTN[0];
	
	debouncer
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
		.rx_data(),			
		.uart_rx(UART_RXD),	// RX pin

		/* TX port */
		.tx(deb_tick),
		.tx_data(),	
		.tx_full(), // not connect
		.uart_tx(UART_TXD)

	);

	
	always@(posedge(CLK), posedge(rst))
		if(rst)
			begin
				test_state_r <= S_IDLE;	
				tx_start <= 1'b0;  
				
				tx_mem[0] <= 8'h41; // 41 // A
				tx_mem[1] <= 8'h55; // U
				tx_mem[2] <= 8'h66; // f
				tx_mem[3] <= 8'h7A; // z	 
				
				c_cnt_r <= 4'b0000;
				LED[0] <= 1'b1;
			end
		else
			begin
				case (test_state_r)
					S_IDLE:
					begin			
`ifdef	 TEST_BENCH
						done = 1'b0;
`endif
						if(deb_btn1)   
							begin
								test_state_r <= S_TX;
								tx_data <= tx_mem[0];
								c_cnt_r <= 4'b0000;	  
								
								tx_start <= 1'b1; /* start TX */
							end
					end
					
					S_TX:
					begin
						LED[1] <= 1'b1;
						tx_start <= 1'b0; // one cycle 
						if(tx_done)
							begin
								if(c_cnt_r == 3)  
									begin
										test_state_r <= S_DONE;
`ifdef	 TEST_BENCH
										done <= 1'b1;
`endif
										c_cnt_r <= 4'b0000;
									end
								else		 
									begin	   
										tx_start <= 1'b1;
										tx_data <= tx_mem[c_cnt_r+1];
										c_cnt_r <= c_cnt_r + 1;
									end	  
								
								LED[2] <= 1'b1;
							end
						else
							LED[2] <= 1'b0;
					end
					
					S_DONE:
					begin						  
						LED[7] <= 1'b1;
						if(~deb_btn1)
							test_state_r <= S_IDLE;
					end	   
					
					default:
					begin
					end
					
				endcase	
			end	

endmodule
