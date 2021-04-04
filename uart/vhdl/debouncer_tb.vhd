
library ieee;
use ieee.std_logic_1164.all;

entity tb_debouncer is
end tb_debouncer;

architecture tb of tb_debouncer is
constant period: time := 10ns; -- 100MHz

signal clk: std_logic := '0';
signal rst_n: std_logic := '0';
signal sw: std_logic;
signal db: std_logic;

begin														 
	-- simulation time: 5 us
	-- VHDL'93 instantiate a entity, no component is needed
	d_bouncer: entity work.debouncer(logic)
		generic map(
			TIME_LAPES=>1, -- 1 us
			TIME_BASE=>1_000_000)  -- unit as us for simulation
		port map(clk=>clk, rst_n=>rst_n, sw=>sw, db=>db);
		
	rst_n <= '0', '1' after 20 ns; 
	clk <= not clk after 5 ns;
	
	
	gsw: process
	begin
		sw <= '0';
		wait for 55 ns;
		
		-- 200ns positive pulse
		sw <= '1';
		wait for 200ns;	  
		sw <= '0';
		wait for 20ns;

		-- 900ns positive pulse
		sw <= '1';
		wait for 900ns;	  
		sw <= '0';
		wait for 20ns;

		-- 1200ns positive pulse
		sw <= '1';
		wait for 1200ns;	  
		sw <= '0';
		wait for 20ns;


		-- 900ns nagative pulse
		sw <= '1';
		wait for 20ns;
		sw <= '0';
		wait for 900ns;	  
		sw <= '1';
		wait for 20ns;

		-- 1200ns positive pulse
		sw <= '0';
		wait for 1200ns;	  
		sw <= '1';
		wait for 20ns; 
		
		wait;

	end process;
	
	
end;

