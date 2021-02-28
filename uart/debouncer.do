
vlog $dsn/src/debouncer.v
vlog $dsn/src/debouncer_tb.v

vsim +access +mdebouncer_tb debouncer_tb

clear -wave

add wave clk
add wave rst
add wave button
add wave deb
add wave tick

add wave dounce_inst/clear_sig
add wave dounce_inst/cnt_r

run 8000
