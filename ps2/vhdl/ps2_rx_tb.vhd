-- simulation ps2 receiving circuit
-- simulation time: 100us

library ieee;
use ieee.std_logic_1164.all;

entity ps2_rx_tb is
end ps2_rx_tb;


architecture arch of ps2_rx_tb is
signal clk: std_logic := '0';
signal rst_n: std_logic;
signal ps2_clk: std_logic;
signal ps2_data: std_logic;			   
signal ps2_en: std_logic;
signal ps2_rx_code: std_logic_vector(7 downto 0);
signal ps2_rx_ready: std_logic;

-- signals for tests
signal fall_edge: std_logic;

-- 8 clock ticks check one rising or falling edge, so cycle should be 20xclock_tick, then fall edge can be checked correctly
constant ps2_cycle : time := 300 ns;

type TEST_ROM is array (0 to 15) of std_logic_vector(8 downto 0);  -- bit8 is odd parity

signal rom_char : TEST_ROM :=
(		  
"000011100", -- -0x1C, make code of A
"000110010", -- 0x32, B
"100100001", -- 1 + 0x21, make code of C
"000100011", -- 0x23, D
"000110100",  -- 0x34, G
"100100100", -- 0x24, E
"100101011", -- 0x2B, F
"100110011", -- 0x33, H

"001000101", -- 0x45, "0"
"000010110", -- 0x16, "1"
"100011110", -- 0x1E, "2",
"000100110", -- 0x26, "3",
"000100101", -- 0x25, "4"
"100101110", -- 0x2E, "5"
"100110110", -- 0x36, "6",
"000111101"  -- 0x3D, "7",
);
																  
begin
	ps_rx_comp: entity work.ps2_rx
		port map(
			rst_n => rst_n,
			clk => clk,
			ps2clk => ps2_clk,
			ps2d => ps2_data,  
			ps2en => ps2_en,
			dout => ps2_rx_code,
			dready => ps2_rx_ready,
--			db_clk => deb_clk,
--			db_data => deb_data,
			fall => fall_edge
		);

	rst_n <= '0', '1' after 20 ns;
	clk <= not clk after 5 ns;
	
	-- ps2_data and ps2_clock
	ps2_data_proc: process 
		variable send_data : std_logic_vector(8 downto 0) := "100100001";  -- 0x21, C
	begin		 				
		wait for 80 ns;
		for j in 0 to 15 loop
			ps2_data <= '1'; -- stop status. high
			ps2_clk <= '1';	   -- no ps2 clock 
			wait for 300 ns; -- must be synchronized with ps2 clock, same cycle and sync	   
			send_data :=  rom_char(j);
			
			ps2_en <= '1';
			ps2_data <= '0'; -- start bit: one cycle
			wait for 5 ns;
			ps2_clk <= '0'; -- falling edge
			wait for ps2_cycle/2;
			ps2_clk <= '1'; -- falling edge
			wait for ps2_cycle/2;
			for i in 0 to 8 loop
				ps2_data <= send_data(i); -- rising edge, send data
				wait for 5 ns;
				ps2_clk <= '0'; -- falling edge, sample data
				wait for ps2_cycle/2;
				ps2_clk <= '1'; -- rising edge
				wait for ps2_cycle/2;
			end loop;	 
			
			-- last ps2 clock cycle
			ps2_data <= '1'; -- rising edge, send data
			wait for 5 ns;
			ps2_clk <= '0'; -- falling edge, sample data

			-- rx finish, output ready
			wait until ps2_rx_ready = '1';

			assert(ps2_rx_code = send_data(7 downto 0))
			report("PS2 receive code wrong")
			severity failure;
			
			wait for ps2_cycle/2;
			ps2_clk <= '1'; -- rising edge
			-- wait for ps2_cycle/2;
			
			wait for 500 ns;
		end loop;
		
	end process ps2_data_proc;
	
	
	--test_deb_proc: process
	--begin
	--	wait for 30 ns;
		
	--	ps2_clk <= '0';
	--	ps2_data <= '0';
	--	for i in 0 to 20 loop
	--		ps2_clk <= '1';
	--		ps2_data <= '1';
	--		wait for i*5 ns;
	--		ps2_clk <= '0';
	--		ps2_data <= '0';
	--		wait for i*5 ns;
	--	end loop;			 		
	-- end process test_deb_proc;
	
	
end architecture;

