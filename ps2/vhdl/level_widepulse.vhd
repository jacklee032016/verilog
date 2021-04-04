-- output a pulse with width of n cycle of clock when signal change its state
-- Dec.13, 2020

library ieee;
use ieee.std_logic_1164.all;

use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity level_widepulse is
	generic(
		WIDTH: integer :=2
	);
	port(
		rst_n, clk: in std_logic;
		btn: in std_logic;
		ntick: out std_logic
	);
end level_widepulse;

architecture beh of level_widepulse is

-- signal counter_r, counter_n: std_logic_vector (2 downto 0);
signal counter_r, counter_n: integer range 0 to WIDTH;
signal dout_r, dout_n: std_logic;
signal flag_r, flag_n: std_logic;

begin		  
	-- type 2 processes: one only register; one for control
	reg_proc: process(rst_n, clk)
	begin
		if(rst_n = '0') then
			counter_r <= 0;-- (others => '0');
			dout_r <= '0'; 
			flag_r <= '0';
		elsif(rising_edge(clk))	then
			counter_r <= counter_n;
			dout_r <= dout_n; 
			flag_r <= flag_n;
		end if;	
	end process reg_proc;

	state_next: process(clk, btn, counter_r, dout_r)
	begin				
		dout_n <= dout_r;
		counter_n <= counter_r;			   
		flag_n <= flag_r;
		
		if(btn = '1' ) then
			if(flag_r = '0') then
				flag_n <= '1';
				dout_n <= '1';
				counter_n <= 0; --(others=> '0');
			elsif(counter_r < WIDTH -1 and flag_r = '1' )	then
				counter_n <= counter_r +1;
			else
				dout_n <= '0'; 						
			end if;
		else	
			flag_n <= '0';
			dout_n <= '0';
		end if;
		
	end process state_next;


ntick <= '1' when dout_r = '1' else
	'0';

	
end architecture;
