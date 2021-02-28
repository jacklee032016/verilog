# README

## Test with HW

add following files into vivado to test onboard
*. fifo.v
*. debouncer.v
*. baudrate_gen.v
*. uart_tx.v
*. uart_rx.v
*. uart.v
*. uart_test.v
*. constrains/nexysUart.xdc


Top level module `uart_test`:
* Button-1: output every bytes received on TX with value +1


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
