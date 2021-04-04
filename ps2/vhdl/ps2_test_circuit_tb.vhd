
-- simulation scan code monitor circuit
-- simulation time: 100us

library ieee;
use ieee.std_logic_1164.all;

entity ps2_test_circuit_tb is
end ps2_test_circuit_tb;


architecture arch of ps2_test_circuit_tb is   

signal clk: std_logic := '0';
signal rst_n: std_logic;

signal LED: std_logic_vector(7 downto 0);
signal SW: std_logic_vector(7 downto 0);
signal BTN: std_logic_vector(4 downto 0);  

signal UART_TXD, UART_RXD: std_logic;

signal ps2_clk: std_logic;
signal ps2_data: std_logic;	  

signal ps2_rx_data: std_logic_vector(7 downto 0);	
signal ps2_rx_done: std_logic;

-- signals for tests
signal fall_edge, deb_clk, deb_data: std_logic;

-- 8 clock ticks check one rising or falling edge, so cycle should be 20xclock_tick, then fall edge can be checked correctly
constant ps2_cycle : time := 200 ns;

type TEST_ROM is array (0 to 15) of std_logic_vector(9 downto 0);  -- bit8 is odd parity

-- 10 bits: stop bit+odd parity+8-bit data, simplify simulation
signal rom_char : TEST_ROM :=
(		  
"1000011100", -- -0x1C, make code of A
--"1101010101", -- -0x1C, make code of A
"1000110010", -- 0x32, B
"1100100001", -- 1 + 0x21, make code of C
"1000100011", -- 0x23, D
"1000110100",  -- 0x34, G
"1100100100", -- 0x24, E
"1100101011", -- 0x2B, F
"1100110011", -- 0x33, H

"1001000101", -- 0x45, "0"
"1000010110", -- 0x16, "1"
"1100011110", -- 0x1E, "2",
"1000100110", -- 0x26, "3",
"1000100101", -- 0x25, "4"
"1100101110", -- 0x2E, "5"
"1100110110", -- 0x36, "6",
"1000111101"  -- 0x3D, "7",
);
																  
begin
	ps2_rx: entity work.ps2_test_circuit
		generic map(	 
			CLK_MOD => 5
		)	
		port map(
			BTN => BTN,
			CLK => CLK,
			-- uart signals
			UART_RXD => '1',
			UART_TXD => UART_TXD,
			LED => LED,
			SW => SW,
			
			-- HID-PS2 signals
			ps2_clk => ps2_clk,
			ps2_data => ps2_data
		);
	
	-- btn pressed: high, eg. reset	
	BTN(0) <= rst_n;
	rst_n <= '1', '0' after 20 ns;
	clk <= not clk after 5 ns;
	
	-- ps2_data and ps2_clock
	ps2_data_proc: process 
		variable send_data : std_logic_vector(9 downto 0) := "1100100001";  -- 0x21, C
	begin		 				
		wait for 80 ns;
		for j in 0 to 15 loop
			ps2_data <= '1'; -- stop status. high
			ps2_clk <= '1';	   -- no ps2 clock 
			wait for 300 ns; -- must be synchronized with ps2 clock, same cycle and sync	   
			send_data :=  rom_char(j);
			
			-- start bit
			ps2_data <= '0'; -- start bit: one cycle
--			wait for 5 ns;
			wait for ps2_cycle/2;
			ps2_clk <= '0'; -- beginning of clk
			wait for ps2_cycle/2;
			ps2_clk <= '1'; -- falling edge	  			
			wait for ps2_cycle/2;			  
			
			-- 9 bits, include odd parity check
			for i in 0 to 9 loop
				ps2_data <= send_data(i); -- rising edge, send data
				-- wait for 5 ns;
				--wait for ps2_cycle/2;
				ps2_clk <= '0'; -- falling edge, sample data
				wait for ps2_cycle/2;
				ps2_clk <= '1'; -- rising edge
				wait for ps2_cycle/2;
			end loop;	 
			
			ps2_clk <= '1'; -- falling edge, sample data
			ps2_clk <= '1'; -- rising edge
			-- wait for ps2_cycle/2;
			
			wait for 500 ns;
		end loop;
		
	end process ps2_data_proc;
	
	
	
end architecture;
