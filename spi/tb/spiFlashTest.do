#vlog	fifo.v
#vlog	baudrate_gen.v	
#vlog	uart_rx.v
#vlog	uart_tx.v 
#vlog	uart.v
#vlog	debouncer.v


vlog	spiMaster.sv
vlog	spiFlash.sv
vlog	spiFlashTest.sv
vlog	spiFlashTestTb.sv

vsim -05 +access +w_nets +accb +accr +mSpiFlashTestTb SpiFlashTestTb
			
clear -wave

add wave	rCLK
add wave	rBTN

add wave	wSpiCs
add wave	wSpiClk
add wave	wSpiMosi
add wave	rSpiMiso  
add wave	test_ins/flash_inst/rState

add wave	wUartTx

add	wave	wLED
	 
add wave	test_ins/rState		
add wave	test_ins/rRdFlashStart
add wave	test_ins/rRdFlashAddress   

add wave	test_ins/rUartTxStart
add wave	test_ins/rUartTxData

run 15000
