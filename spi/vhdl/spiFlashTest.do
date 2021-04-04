endsim

vcom -dbg spi.vhd
#vlog
vcom -dbg spiFlash.vhd
vcom -dbg spiFlashTest.vhd

vcom -dbg spiFlashTest_tb.vhd
asim -O5 +access +w_nets +accb +accr +access +r +m+spiFlashTest_tb spiFlashTest_tb

clear -wave

add wave	CLK
add wave	BTN   

add wave	LED	 

add wave	spi_cs	  
add wave	spi_clk
add wave	spi_dout;
add wave	spi_din


run 10000
