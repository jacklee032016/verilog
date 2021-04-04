library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_5clk is
	port(
		clk, rst_n: in std_logic;
		go, stop: in std_logic;
		pulse: out std_logic
		);
end pulse_5clk;	   

architecture regular_seq_arch of pulse_5clk is
	constant P_WIDTH: natural := 5;
	signal c_reg, c_next: unsigned(3 downto 0);
	signal flag_reg, flag_next: std_logic;		 
	
begin
	-- register
	reg_proc: process(clk, rst_n)
	begin
		if (rst_n = '0' ) then
			c_reg <= (others=> '0' );
			flag_reg <= '0';
		elsif (clk'event and clk = '1') then
			c_reg <= c_next;
			flag_reg <= flag_next;
		end if;
	end process reg_proc;
	
	-- next-state logic
	process(c_reg, flag_reg, go, stop)
	begin
		c_next <= c_reg;
		flag_next <= flag_reg;
		if (flag_reg = '0') and (go = '1') then
			flag_next <= '1';
			c_next <= (others=> '0');
		elsif (flag_reg = '1') and
			((c_reg = P_WIDTH-1) or (stop = '1')) then
			flag_next <= '0';
		elsif (flag_reg = '1') then
			c_next <= c_reg + 1;
		end if;
	end process;
	
	pulse <= '1' when flag_reg='1' else '0';	
		
end architecture;
