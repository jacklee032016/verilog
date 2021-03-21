endsim

# vlog -dbg ps2_rx.sv
#vlog
# vlog -dbg ps2_key.sv

vlog -dbg ps2_key_test_tb.sv
asim -O5 +access +w_nets +accb +accr +access +r +m+ps2_key_test_tb ps2_key_test_tb

clear -wave

add wave CLK
add wave clk
add wave rst   
add wave BTN  
add wave SW  
add wave LED  

add wave ps2d
add wave ps2c	  

add wave UART_TXD


add wave ps_ins/key_inst/falling_edge_clk
add wave ps_ins/key_inst/state_r
add wave ps_ins/key_inst/rx_done
add wave ps_ins/en
add wave ps_ins/ascii_ready
add wave ps_ins/ascii
add wave ps_ins/wr_data
				
run 18500
