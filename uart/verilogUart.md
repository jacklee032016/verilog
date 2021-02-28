# Verilog UART and Debug


## `case` and `casez`

```
	case ({wr, rd})
		2'b01: # can't be used as 1'bz1, so when wr is high Z, this is not selected
		
		2'b10:
		
		2:b11:
```		

change as following

```
	casez ({wr, rd})
		2'b11:
		
		2'bz1:
		
		2'b1z:
```

**Note**
* when `casez/casex` is used, the most specific case must be the first one;


## FIFO/memory read circuit

always read no matter whether `rd_enable` port is enabled

so `rd_enable` signal should be kept synchronized with sys clock, and only use the `rd_data` when `rd_enable` is enabled;

For example, read one byte from FIFO and send it to UART TX:
	* read data from FIFO and send data to TX in the same tick; 
	* default rd_data is always read in `rd_data` of FIFO;
	* Use the data at the beginning when `rd_enable` become 1;
	   * After this clock tick, the read index has been changed to next index, so read out another value;
	   * Use the current when clock tick begin, so how to use the read data is totally depends on app circuit; 

## Oversampling in TX and RX

Oversample rate for 11920/100MHz is 16;
	
	For TX, in the START byte, about #16 tick, begin to send data; if it send earlier, may the RX will refuse to recv;
	
	For RX, in the START byte, about #8 tick, recount about 16 ticks from beginning, so TX will samlpe data at the middle of first bit data;
	
	