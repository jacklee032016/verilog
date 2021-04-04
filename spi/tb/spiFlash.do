vlog spiMaster.sv
vlog spiFlash.sv
vlog spiFlashTb.sv

vsim -05 +access +w_nets +accb +accr +mspiFlashTb spiFlashTb
			
clear -wave

add wave clk
add wave rst

add wave rWr
add wave rRd
add wave rAddress
add wave rWrData
add wave wRdData
add wave wDone

add wave wSpiCs
add wave wSpiClk
add wave wSpiMosi
add wave rSpiMiso
	 
	 
add wave inst/rState
#add wave inst/rBitCnt		 

# add wave rOutputData


run 3800