/*
* include baudrate generator (shared by RX and TX)
* TX
*/

module uart
	#(parameter
		BAUDRATE_COUNT = 326,
		DATA_BITS = 8,
		FIFO_SIZE = 8
	)
	(
		input clk, rst,
		/* RX port */				   
		output rx_ready,
		input rx, // read data from RX FIFO
		output [DATA_BITS-1:0] rx_data,			
		input uart_rx,	// RX pin

		/* TX port */
		input tx,
		input [DATA_BITS-1:0] tx_data,	
		output tx_full,	// write buffer is full 
		output uart_tx
	);

	wire bd_tick;
	
	reg tx_fifo_rd;
	wire tx_fifo_empty;
	wire [DATA_BITS-1:0] tx_fifo_rd_data; // from fifo:rd_data --> tx:wr_data
	reg uart_tx_start;
	wire uart_tx_done; 		  
	
	/* RX */
	wire rd_ready;				 
	wire rd_empty, rx_full;
	wire [DATA_BITS-1:0] rx_rd_data;
	
	/* baudrate generator to TX */
	baudrate_gen 
		#(
		.N(BAUDRATE_COUNT)
		)
		baudrate_inst
		(
			.clk(clk),
			.rst(rst),
			.bd_tick(bd_tick)
		);

	fifo
	#(
		.WORD(DATA_BITS),
		.SIZE(FIFO_SIZE)
	)
	rx_fifo
	(			 
		.clk(clk),
		.rst(rst),
		.wr(rd_ready), // from RX
		.wr_data(rx_rd_data),// from RX
		.rd(rx), // external
		.rd_data(rx_data), /* */
		.full(rx_full), // RX don't use it
		.empty(rd_empty)
 	);		
	 
	assign rx_ready = ~rd_empty; 
		
	uart_rx	
	#(
		.DATA_BITS(DATA_BITS)//,
//		.STOP_BIT(1)
	)
	rx_inst
	( 
		.clk(clk),
		.rst(rst),
		.bd_tick(bd_tick),
		.rx(uart_rx),
		.ready(rd_ready),
		.rd_data(rx_rd_data)
	);

	
	fifo
	#(
		.WORD(DATA_BITS),
		.SIZE(FIFO_SIZE)
	)
	tx_fifo
	(			 
		.clk(clk),
		.rst(rst),
		.wr(tx),
		.wr_data(tx_data), // external	
		/* use this, a bug in which when the last byte has been sent out, always read from memory and send the next bytes */
//		.rd(uart_tx_done), // uart tx
		/* when is not empty, then read from FIFO and send to TX in same tick */
//		.rd(uart_tx_start), // uart tx 
		.rd(tx_fifo_rd),
		.rd_data(tx_fifo_rd_data), /* uart tx_done. so full is cleared when the first byte has been txed by ~empty */
		.full(tx_full), // external
		.empty(tx_fifo_empty)
 	);			 
	
	uart_tx	
	#(
		.DATA_BIT(8),
		.STOP_BIT(1)
	)
	tx_inst
	( 
		.clk(clk),
		.rst(rst),
		.start(uart_tx_start),
		.bd_tick(bd_tick),
		.data(tx_fifo_rd_data),
		.tx(uart_tx),
		.tx_done(uart_tx_done)
	);
		
	/* problem send current byte in FIFO when fifo is not empty and read index is not change; 
	so this bytes always send twice when it become not empty */
//	assign uart_tx_start = ~tx_fifo_empty;
	
	/* use following circuit add delay and current control of TX/FIFO */
	localparam [1:0]
		TX_IDLE = 2'b00,
		TX_DATA = 2'b01, // read from FIFO and send to TX: use the data from FIFO when rd is active, so the data before read index is changed
//		TX_SEND = 2'b10,
		TX_DONE = 2'b11;
		
	reg [1:0] state_tx;
	
	always@(posedge(clk), posedge(rst))
		if(rst)
			begin
				state_tx <= TX_IDLE;
			end
		else
			case (state_tx)
				TX_IDLE:
				begin
					if(~tx_fifo_empty)	
						begin
							state_tx <= TX_DATA;
							tx_fifo_rd <= 1'b1;
							uart_tx_start = 1'b1;
						end 
				end
				
				TX_DATA:
				begin
					state_tx = TX_DONE;
					tx_fifo_rd <= 1'b0;	
					uart_tx_start = 1'b0;
				end
/*				
				TX_SEND:
				begin
					state_tx = TX_DONE;
					uart_tx_start = 1'b0;
				end
*/				
				TX_DONE:
				begin	  
					if(uart_tx_done)
						state_tx = TX_IDLE;
				end	   
				
				default:
				begin
				end
				
			endcase
			
	
endmodule
