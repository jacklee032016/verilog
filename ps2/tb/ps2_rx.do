vlog ps2_rx.sv
vlog ps2_rx_tb.sv

vsim -05 +access +w_nets +accb +accr +mps2_rx_tb ps2_rx_tb
			
clear -wave

add wave clk
add wave rst
add wave ps2_data
add wave ps2_clk 
add wave done
add wave rx_data   
add wave falling   
add wave rx_inst/filter_r
add wave rx_inst/falls
add wave rx_inst/falling_edge_clk
add wave rx_inst/state_r
add wave rx_inst/ps2d
add wave rx_inst/data_idx_r
add wave rx_inst/rx_data_r

run 8000

