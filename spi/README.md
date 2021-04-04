# SPI Flash Controller
April 4th, 2021, Easter Sunday


## Hardware
* Spansion S25FL256S flash

* xc7a200tsbg484-1

Read at 0x00_00_80, where value is 0xAA;

* Entry point:

   spiFlashTest.sv
   
   Debug with `SPI CS` should be controlled by externel module, not SpiMaster.
   
