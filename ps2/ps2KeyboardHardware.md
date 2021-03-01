# PS2 Keyboard Hardware

## communication protocol

* `ps2d`: data line: start/d0/../d7/oddParity/stop;
* `ps2c`: 60 ~ 100us(10KHz-->16.7KHz); sampling at falling edge; ps2d stable before and after 5 us of falling edage;

* internal pull-up must be enabled for both `ps2d` and `ps2c`;
   * defined in constraint file for these 2 pins;
* duplicated direction;

* "self-test passed" command (0xAA) after device is connected;


## Code
* make code:
   * one byte: A(0x1C)
   * extended keys: 2~4 bytes
* typematic/make code/100ms;
* break code: F0 + make code

## Design

### RX circuit

* ps2c, ps2d
* rx_en
* rx_data[8]
* rx_done

test bench

### Scan code process

* ps_in
* ps_data[8]
* out_en
* out_data[8]

stage-1: 
   * transform every bytes into 2 hexidecimal digits. i.e. 0~F;
   * send 2 ASCII chars '0' --> 'F', and one space to UART TX;

stage-2:
   * tranform 'make code' to key, eg. 0x1C to 'a';
   