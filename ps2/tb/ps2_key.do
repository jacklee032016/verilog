endsim

# vlog -dbg ps2_rx.sv
#vlog
# vlog -dbg ps2_key.sv

vlog -dbg ps2_key_tb.sv
asim -O5 +access +w_nets +accb +accr +access +r +m+ps2_key_tb ps2_key_tb

clear -wave

add wave clk
add wave rst   

add wave ps2d
add wave ps2c	  

add wave en
add wave ascii_ready
add wave ascii;


add wave key_inst/rx_done
add wave key_inst/rx_data
add wave key_inst/ascii_code
add wave key_inst/state_r
				
add wave key_inst/falling_edge_clk 

run 8500
