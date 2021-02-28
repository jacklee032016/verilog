
vlib work

vlog ../uart/src/fifo.v
vlog ../uart/src/fifo_tb.v

vsim -c -do simFifo.do 
rem -wlf fifo.wlf

vsim -view vsim.wlf
