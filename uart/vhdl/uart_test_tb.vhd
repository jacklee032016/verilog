-- test bench for UART test circuit

library ieee;
use ieee.std_logic_1164.all;

entity uart_test_tb is
end uart_test_tb;

architecture tb of uart_test_tb is

--signal rst_n : std_logic;
signal BTN: std_logic_vector(4 downto 0);
signal CLK : std_logic := '0';
signal uart_tx, uart_rx: std_logic;
signal LED: std_logic_vector(7 downto 0);		
signal SW: std_logic_vector(7 downto 0);

signal test_data: std_logic_vector(7 downto 0) := "10101010";	
signal txstart: std_logic;

-- simulation for 8 bytes about 35us when baudrate is 2xclock
type DATA_BUF is array (0 to 7) of std_logic_vector(7 downto 0);
signal in_datas : DATA_BUF :=
	(	
		"01001001",	-- differ from start bit and stop bit
		X"A8",
		X"A9",
		X"AA",
		X"AB",
		X"AC",
		X"AD",
		X"AF"
	);
signal rx_data: std_logic_vector(7 downto 0);


begin
	comp: entity work.uart_test	
		generic map(
			CLK_MOD => 2,
			TIME_LAPES => 1, -- 1 us
			TIME_BASE => 1_000_000  -- unit as us for simulation
		)
		port map(
			BTN => BTN,
			CLK => CLK,
			UART_RXD => uart_rx,
			UART_TXD => uart_tx,
			LED => LED,
			SW => SW
--			txover => txstart
		);
	
	BTN(0) <= '1', '0' after 15 ns;
	CLK <= not CLK after 5 ns;

	data_rx_proc: process
	begin				
		wait for 20 ns;
		
		loop_data: for j in 0 to 7 loop
			wait for 20 ns;
			uart_rx <= '0';	-- start signal
			rx_data <= in_datas(j);
			wait for 16*20 ns; 
			
			-- data bits
			loop_byte: for i in 0 to 7 loop
				uart_rx <= rx_data(i);
				wait for 16*20 ns;
			end loop loop_byte;
			
			uart_rx <= '1';
			wait until LED(5) = '1';
			
			--assert( rx_data = in_data)
			--	report("UART RX data is wrong")
			--	severity error;
		end loop loop_data;
		
		wait;
	end process data_rx_proc;

	data_tx_proc: process
	begin				
		BTN(1) <= '1';
		wait for 35 ns;
		BTN(1) <= '0';
		wait for 3 us;
		BTN(1) <= '1';
		wait for 1135 ns;	-- in simulation, button deounce limit 1us; like 11 ms with hw
		wait for 100 us;		-- simulate 1 s in hw
		BTN(1) <= '0';
--		wait until ready = '1';
--		data <= "00000011";
--		rx <= '0';
--		wait for 16*20 ns; -- start signal
		
-- wait until ready = '1';
--		for i in 0 to 7 loop
--			rx <= test_data(i);
--			wait for 16*20 ns;		
--		end loop;			  
		
--		rx <= '1';
--		wait for 32*20 ns; -- stop signal 
		
		wait;

	end process data_tx_proc;
	
end architecture;
