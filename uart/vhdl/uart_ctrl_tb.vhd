library ieee;
use ieee.std_logic_1164.all;

entity tb_uart_tx is
end tb_uart_tx;


architecture tb_uart of tb_uart_tx is	 

signal	BTN: std_logic_vector(4 downto 0); -- ON: high level; off(default): low level
signal	SW: std_logic_vector(7 downto 0);
signal	LED: std_logic_vector(7 downto 0);
signal	CLK: std_logic := '1';
signal	UART_TXD: std_logic;

-- simulation in time unit of us; total 10 us; modify generic param in uart_tx to 1us

begin	 
	uart_com: entity work.uart_ctrl
		port map(
		BTN=>BTN, 
		SW => SW,
		LED => LED,
		CLK => CLK,
		UART_TXD => UART_TXD);
		
	CLK <= not CLK after 5 ns;	
	BTN(0) <= '1', '0' after 25 ns;--rst
	
	
	process		  
	begin
		BTN(1) <= '1'; --  button glitch 1us limit 
		wait for 1200 ns;

		BTN(1) <= '0';
		wait for 1200 ns;
		
		wait for 50 ns;

	end process;
	
end architecture;
