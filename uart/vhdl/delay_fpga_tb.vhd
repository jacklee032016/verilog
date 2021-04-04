library ieee;
use ieee.std_logic_1164.all;

entity tb_delay_fpga is
end tb_delay_fpga;


architecture tb_delay of tb_delay_fpga is	 

signal	BTN: std_logic_vector(4 downto 0); -- ON: high level; off(default): low level
signal	SW: std_logic_vector(7 downto 0);
signal	LED: std_logic_vector(7 downto 0);
signal	CLK: std_logic := '1';
signal	UART_TXD, UART_RXD: std_logic;

-- simulation in time unit of us; total 10 us; modify generic param in uart_tx to 1us

begin	 
	delay_comp: entity work.delay_fpga
		port map(
		BTN=>BTN, 
		SW => SW,
		LED => LED,
		CLK => CLK,
		UART_TXD => UART_TXD,
		UART_RXD => UART_RXD);
		
	CLK <= not CLK after 5 ns;	 -- 100M clock
	BTN(0) <= '1', '0' after 25 ns;--rst
	
	-- count SW(0), one clock tick every 100ns when sw(0) is ON
	process		  
	begin
		SW(0) <= '0'; --  button glitch 1us limit 
		wait for 120 ns; 
		
		SW(0) <= '1'; --  button glitch 1us limit 
		wait for 120 ns;

--		SW(0) <= '0';
--		wait for 120 ns;
		
--		SW(0) <= '1';
--		wait for 50 ns;
		-- wait;

	end process;
	
end architecture;
