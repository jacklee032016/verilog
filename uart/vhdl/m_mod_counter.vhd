-- mod the clock with param m, and assert one tick (one clock cycle)
-- Nov.30, 2020

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity m_mod_counter is
	generic(
		N: integer :=10; -- bits for counter
		M: integer := 163
	);	-- one tick per M clock
	port(
		clk, rst_n: in std_logic;
		tick: out std_logic
--		;res: out std_logic_vector(N-1 downto 0) -- use to debug this entity
	);
end m_mod_counter;


architecture beh of m_mod_counter is
signal cnt_r, cnt_next: unsigned(N-1 downto 0);

begin
	process(clk, rst_n)
	begin
		if(rst_n='0' ) then
			cnt_r <= (others=> '0');
		elsif (clk'event and clk ='1') then
			cnt_r <= cnt_next;
		end if;
	end process;

	cnt_next <= (others=>'0') when cnt_r=M-1 else
		cnt_r +1;
	tick <= '1' when cnt_r=M-1 else
		'0';
		
	-- res <= std_logic_vector(cnt_r);
	
end architecture;
