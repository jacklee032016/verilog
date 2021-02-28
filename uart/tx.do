# Active HDL User Guide: Macro Command Reference

# test uart TX circuit

endsim						 
vlog -dbg $DSN/src/baudrate_gen.v
vlog -dbg $DSN/src/fifo.v 
vlog -dbg $DSN/src/uart_tx.v 
vlog -dbg $DSN/src/uart.v 
vlog -dbg $DSN/src/uart_tx_tb.v 

asim -O5 +access +w_nets +accb +accr +access +r +m+uart_tx_tb uart_tx_tb


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
wave tx
wave tx_inst/uart_tx_start   
wave tx_inst/uart_tx_done  # init as 1
wave tx_inst/tx_fifo_rd_data

wave tx_inst/tx_fifo/wr
wave tx_inst/tx_fifo/rd
wave tx_inst/tx_fifo/empty	
wave tx_inst/tx_fifo/full	
wave tx_inst/tx_fifo/wr_index
wave tx_inst/tx_fifo/rd_index
wave tx_inst/tx_fifo/fifo_buf

wave tx_inst/tx_inst/start
wave tx_inst/tx_inst/state_r
		   
# 7000: TX one byte 
# 50000 for 6 bytes
run 50000

