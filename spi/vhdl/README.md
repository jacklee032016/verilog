# SPI Flash Controller
Jan.2nd, 2021 

## About SPI
* CPHA(Clock PHAse): 
    * 0: send data in phase 0, ie. the first edge of clock cycle
	* 1: send data in phase 1, ie. the second edge of clock cycle
* CPOL(Clock POLarity): 
	* 0: PCLK is low when CS=0, ie. PCLK is low when idle
	* 1: PCLK is high when CS=0, ie. PCLK is high when idle
* Normally slave is "00" or "11"; SPI Flash and OLED all are "11";



## New Code
Jan.4th, 2021, Monday
* Read flash with new code successfully;


## Debug
* add startup2 primitive to the SPI Clock signal, so it can be used by flash controller after FPGA is configured;


## Hardware
* Spansion S25FL256S flash


* xc7a200tsbg484-1

Read at 0x00_00_80, where value is 0xAA;

* Entry point:

   spiFlashTest.vhd
