# creating library
alib work
# setting work library as the default target for all commands
set worklib work
# compiling verilog source files
alog fifo.v fifo_tb.v
# starting simulation with tb_top as the top level module
asim fifo_tb
# running the simulation
run 1000us
# closing the simulation
endsim
# quit
