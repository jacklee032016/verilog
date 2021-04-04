
## chip xc7a200tsbg484-1

##Clock Signal
set_property -dict { PACKAGE_PIN R4    IOSTANDARD LVCMOS33 } [get_ports { CLK }]; #IO_L13P_T2_MRCC_34 Sch=sysclk
#create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK}];


#UART
set_property -dict { PACKAGE_PIN AA19  IOSTANDARD LVCMOS33 } [get_ports { UART_TXD }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=uart_rx_out
# V18 RX for FPGA
set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports { UART_RXD }]; #IO_L14P_T2_SRCC_14 Sch=uart_tx_in


# Buttons
set_property -dict { PACKAGE_PIN B22  IOSTANDARD LVCMOS33} [get_ports { BTN[0] }]; #IO_L20N_T3_16 Sch=btnc
set_property -dict { PACKAGE_PIN D22  IOSTANDARD LVCMOS33} [get_ports { BTN[1]  }]; #IO_L22N_T3_16 Sch=btnd
set_property -dict { PACKAGE_PIN C22  IOSTANDARD LVCMOS33} [get_ports { BTN[2]  }]; #IO_L20P_T3_16 Sch=btnl
set_property -dict { PACKAGE_PIN D14  IOSTANDARD LVCMOS33} [get_ports { BTN[3]  }]; #IO_L6P_T0_16 Sch=btnr
set_property -dict { PACKAGE_PIN F15  IOSTANDARD LVCMOS33} [get_ports { BTN[4]  }]; #IO_0_16 Sch=btnu
#set_property -dict { PACKAGE_PIN G4   } [get_ports { cpu_resetn }]; #IO_L12N_T1_MRCC_35 Sch=cpu_resetn


#Switches
set_property -dict { PACKAGE_PIN E22  IOSTANDARD LVCMOS33} [get_ports { SW[0] }]; #IO_L22P_T3_16 Sch=sw[0]
set_property -dict { PACKAGE_PIN F21  IOSTANDARD LVCMOS33} [get_ports { SW[1] }]; #IO_25_16 Sch=sw[1]
set_property -dict { PACKAGE_PIN G21  IOSTANDARD LVCMOS33} [get_ports { SW[2] }]; #IO_L24P_T3_16 Sch=sw[2]
set_property -dict { PACKAGE_PIN G22  IOSTANDARD LVCMOS33} [get_ports { SW[3] }]; #IO_L24N_T3_16 Sch=sw[3]
set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS33} [get_ports { SW[4] }]; #IO_L6P_T0_15 Sch=sw[4]
set_property -dict { PACKAGE_PIN J16  IOSTANDARD LVCMOS33} [get_ports { SW[5] }]; #IO_0_15 Sch=sw[5]
set_property -dict { PACKAGE_PIN K13  IOSTANDARD LVCMOS33} [get_ports { SW[6] }]; #IO_L19P_T3_A22_15 Sch=sw[6]
set_property -dict { PACKAGE_PIN M17  IOSTANDARD LVCMOS33} [get_ports { SW[7] }]; #IO_25_15 Sch=sw[7]


#LEDs
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS25 } [get_ports { LED[0] }]; #IO_L15P_T2_DQS_13 Sch=led[0]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS25 } [get_ports { LED[1] }]; #IO_L15N_T2_DQS_13 Sch=led[1]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS25 } [get_ports { LED[2] }]; #IO_L17P_T2_13 Sch=led[2]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS25 } [get_ports { LED[3] }]; #IO_L17N_T2_13 Sch=led[3]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS25 } [get_ports { LED[4] }]; #IO_L14N_T2_SRCC_13 Sch=led[4]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS25 } [get_ports { LED[5] }]; #IO_L16N_T2_13 Sch=led[5]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS25 } [get_ports { LED[6] }]; #IO_L16P_T2_13 Sch=led[6]
set_property -dict { PACKAGE_PIN Y13   IOSTANDARD LVCMOS25 } [get_ports { LED[7] }]; #IO_L5P_T0_13 Sch=led[7]


##HID port
set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports { ps2_clk }]; #IO_L16N_T2_A15_D31_14 Sch=ps2_clk
set_property -dict { PACKAGE_PIN N13   IOSTANDARD LVCMOS33 } [get_ports { ps2_data }]; #IO_L23P_T3_A03_D19_14 Sch=ps2_data
# internal pull-up for clock and data
set_property PULLTYPE PULLUP [get_ports { ps2_clk }]
set_property PULLTYPE PULLUP [get_ports { ps2_data }]


##QSPI
set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33 } [get_ports { spi_cs }]; #IO_L6P_T0_FCS_B_14 Sch=qspi_cs
set_property -dict { PACKAGE_PIN P22   IOSTANDARD LVCMOS33 } [get_ports { spi_dout }]; #IO_L1P_T0_D00_MOSI_14 Sch=qspi_dq[0]
set_property -dict { PACKAGE_PIN R22   IOSTANDARD LVCMOS33 } [get_ports { spi_din }]; #IO_L1N_T0_D01_DIN_14 Sch=qspi_dq[1]
set_property -dict { PACKAGE_PIN P21   IOSTANDARD LVCMOS33 } [get_ports { spi_wp_n }]; #IO_L2P_T0_D02_14 Sch=qspi_dq[2]
set_property -dict { PACKAGE_PIN R21   IOSTANDARD LVCMOS33 } [get_ports { spi_hold_n }]; #IO_L2N_T0_D03_14 Sch=qspi_dq[3]
set_property -dict { PACKAGE_PIN W5    IOSTANDARD LVCMOS33 } [get_ports { spi_clk }]; #IO_L15N_T2_DQS_34 Sch=scl
