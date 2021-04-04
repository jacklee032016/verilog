library ieee;
use ieee.std_logic_1164.all;

entity m_mod_counter_tb is
end m_mod_counter_tb;

architecture tb of m_mod_counter_tb is
signal clk : std_logic := '0';
signal rst_n : std_logic;
signal mtick: std_logic;
-- signal res:std_logic_vector (9 downto 0);

begin
	tbm: entity work.m_mod_counter
		generic map(M=>10)  -- one tick every 10 clock
		port map(
			clk=>clk, 
			rst_n=>rst_n, 
			tick=>mtick
--			, res=>res
		);
	
	process
	begin
		rst_n <= '0';
		wait for 14 ns;
		rst_n <= '1';
		wait;
	end process;
	
	process
	begin
		clk <= not clk;
		wait for 5 ns;
	end process;
	
end architecture;
	
	