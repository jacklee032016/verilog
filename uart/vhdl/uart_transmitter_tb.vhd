-- check output waveform of TX, compare with the data in ROM

library ieee;
use ieee.std_logic_1164.all;

use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uart_transmitter_tb is
end uart_transmitter_tb;

architecture tb of uart_transmitter_tb is

signal rst_n: std_logic;
signal clk: std_logic := '0';
signal data: std_logic_vector(7 downto 0) := "10101010"; -- LSB first
signal wr_en, ready: std_logic;
signal tx: std_logic;
signal readaddr: std_logic_vector(3 downto 0)  :="0000";

signal rx: std_logic;
-- simulation time:
-- mtick: 50ns; so 16x50ns=800ns per bit
-- one bytes: 1 start bit, 8-bit data, 2-bit stop bit: 11x800ns =8.8 us per bytes
begin					
	uart_tx: entity work.uart 	
		generic map(
			CLK_MOD => 5
		)
		port map(
			rst_n => rst_n, 
			clk => clk,
	
	-- signal for RX
			UART_RXD => rx,
			rx_data => open,
			rx_done => open,
		
	-- signals for TX
			UART_TXD => tx,
			tx_data => data,
			tx_start => wr_en,
			tx_empty => ready -- remove this signal
		);		
	
	chr_rom: entity work.rom_str(beh_str)
		port map(
			rst_n=>rst_n, 
			clk=>clk, 
			addr=>readaddr, 
			data=>data
		);

	rst_n <= '0', '1' after 15 ns;
	clk <= not clk after 5 ns;
	
	process
	begin
		-- data <= "00000001";	
		wr_en <= '0';
		wait for 50 ns; -- init, wait reset 
		
		for i in 0 to 15 loop -- about n*8.8us 
			wr_en <= '1';
			wait for 10 ns;
			wr_en <= '0';
			wait until ready = '1';	  -- wait until signal change; 
			readaddr <= readaddr + 1;	-- read data and signal to TX
		end loop;
		
		wait ;
		
	end	process;
	
	
end architecture;
