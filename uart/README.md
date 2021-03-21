# README

## Test with HW

add following files into vivado to test onboard
1. fifo.v
1. debouncer.v
1. baudrate_gen.v
1. uart_tx.v
1. uart_rx.v
1. uart.v
1. uart_test.v
1. constrains/nexysUart.xdc


Top level module `uart_test`:
* Button-1: output every bytes received on TX with value +1
* baudrate: 19200
* test with RealTerm to capture ASCII and bin simultaneously;
* be carefull: input focus should be in terminal window when use `RealTerm`;


## test bench

Add modules and their testbench in Active-HDL to test;

And run
```
do XXX.do
```


### Simulating in ModelSim

Enter ModelSim environment

```
open.bat
start.bat

vsim -view vsim.wlf # waveform, etc.
```
