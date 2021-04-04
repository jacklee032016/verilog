
library ieee;
use ieee.std_logic_1164.all;

use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pulse_gen_tb is
end pulse_gen_tb;

architecture tb of pulse_gen_tb is

signal clk: std_logic := '1';
signal rst_n: std_logic;
signal btn: std_logic;
signal ntick: std_logic;

begin
	pulsewidth_comp: entity work.level_widepulse
		generic map(
			WIDTH => 2
		)
		port map(
			rst_n => rst_n,
			clk => clk,
			btn => btn,
			ntick => ntick
	);

	rst_n <= '0', '1' after 10 ns;
	clk <= not clk after 5 ns;
	
	process
	begin				
		for i in 0 to 3 loop
			btn <= '0';
			wait for 25 ns;
			btn <= '1';
		
			wait for 25 ns;	 
		
			btn <= '0';
		end loop;
		--wait until ntick = '1';
		wait;
		
	end process;
	
end architecture;
