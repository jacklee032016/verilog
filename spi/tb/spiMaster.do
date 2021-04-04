vlog spiMaster.sv
vlog spiMasterTb.sv

vsim -05 +access +w_nets +accb +accr +mspiMasterTb spiMasterTb
			
clear -wave

add wave clk
add wave rst
add wave CPOL
add wave CPHA
add wave rStart
add wave wReady
add wave wSpiCs
add wave wSpiClk
add wave wSpiMosi
add wave rSpiMiso

add wave inst/rState
add wave inst/rBitCnt		 

add wave rOutputData


run 2000
