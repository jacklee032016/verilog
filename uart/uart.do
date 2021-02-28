# Active HDL User Guide: Macro Command Reference

# test uart RX circuit

endsim						 
vlog -dbg $DSN/src/baudrate_gen.v
vlog -dbg $DSN/src/fifo.v 
vlog -dbg $DSN/src/uart_tx.v 
vlog -dbg $DSN/src/uart_rx.v 
vlog -dbg $DSN/src/uart.v 
vlog -dbg $DSN/src/uart_tb.v 

asim -O5 +access +w_nets +accb +accr +access +r +m+uart_tb uart_tb


# clear existing waveform
clear -wave
# create a new waveform every time
# wave

# wave /fifo_tb/clk
add wave clk
add wave rst
wave tx_start
wave tx_data
wave full		  
wave uart_tx
wave uart_rx
wave rx_ready
wave rx_data
wave rx
wave readMem

wave uart_inst/rx_inst/state_r   
wave uart_inst/rx_inst/d_cnt_r   
wave -literal uart_inst/rx_inst/tick_cnt_r   
wave -expand 					uart_inst/rx_inst/ready   
wave -alias "rx_rd_data"		uart_inst/rx_inst/rd_data

wave 							uart_inst/rx_fifo/rd			
wave -alias "rx_fifo_wr"		uart_inst/rx_fifo/wr			
wave -alias "rx_fifo_wr_data"	uart_inst/rx_fifo/wr_data		
wave -alias "rx_fifo_full"		uart_inst/rx_fifo/full		
wave -alias "rx_fifo_full"		uart_inst/rx_fifo/full_r		
wave -alias "rx_fifo_empty"		uart_inst/rx_fifo/empty   	
wave -alias "rx_fifo_buf"		uart_inst/rx_fifo/fifo_buf	
wave -alias "rx_fifo_wr_idx"	uart_inst/rx_fifo/wr_index  	
wave uart_inst/rx_fifo/wr_index_n  	

		   
# 7000: TX one byte 
run 50000

