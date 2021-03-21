# Active HDL User Guide: Macro Command Reference

# end simulation first
endsim						 
vlog -dbg $DSN/src/fifo.v
vlog -dbg $DSN/src/fifo_tb.v 
# VSIM: Simulation has finished.
# vsim and asim both; vsim: simu session or GUI
# vsim fifo_tb   
asim -O5 +access +w_nets +accb +accr +access +r +m+fifo_tb fifo_tb


#    Wave - creates an empty waveform
#    Wave CE - adds CE signal to waveform

#    Force LOAD 1 0ns, 0 10ns - changes LOAD to 1 at 0ns and to 0 at 10ns
#    Force CE 1 - changes CE to 1

# clear existing waveform
clear -wave
# create a new waveform every time
# wave

# wave /fifo_tb/clk
add wave /fifo_tb/clk
add wave /fifo_tb/rst
wave /fifo_tb/wr
wave /fifo_tb/rd
wave /fifo_tb/full
wave /fifo_tb/empty
wave /fifo_tb/wr_data
wave /fifo_tb/rd_data

wave /fifo_tb/fifo_inst/wr_index
wave /fifo_tb/fifo_inst/rd_index
wave /fifo_tb/fifo_inst/fifo_buf

# read/write simultaneously
# run 300
# sequence write --> read
run 500
