
vlog src/baudrate_gen.v
vlog src/baudrate_gen_tb.v

vsim +access +mbaudrate_gen_tb baudrate_gen_tb

# clear -wave

add wave clk
add wave rst
add wave bd_tick

run 500


