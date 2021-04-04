-- testbench for uart_receiver
-- test with clock of 100MHz, 
-- baudrate generator: period 20ns, 50MHz

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entity name
entity uart_receiver_tb is
end uart_receiver_tb;

architecture uart_rx_tb of uart_receiver_tb is
signal rst_n: std_logic;
signal clk: std_logic := '0';


signal rx: std_logic;
signal rx_data: std_logic_vector(7 downto 0);
signal rx_ready: std_logic;

signal in_data: std_logic_vector(7 downto 0) := "01011010";		 

-- signal for TX
signal tx: std_logic;
signal tx_data: std_logic_vector (7 downto 0);
signal tx_en: std_logic;
signal tx_empty: std_logic;

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


begin	 
	uart_rx: entity work.uart 
		generic map(
			-- CLK_MOD: integer := 651  -- 651 for baudrate 9600, eg. oversample rate
			CLK_MOD => 2  -- for simulation
		)
		port map(
			rst_n =>rst_n,
			clk => clk, 
	
		-- signal for RX
			UART_RXD => rx,
			rx_data => rx_data,
			done => rx_ready,
		
		-- signals for TX
			UART_TXD => tx,
			wr_data => tx_data,
			wr_en => tx_en,
			wr_empty => tx_empty
	);


	clk <= not clk after 5 ns;
	rst_n <= '0', '1' after 10 ns;
	-- baud_clk <= not baud_clk after 10 ns; -- syn with clock
	
	-- test case for TX
	tx_bytes_test: process
	begin					  

		-- data <= "00000001";
		tx_en <= '0';
		wait for 35 ns;
--		wait until ready = '1';
--		data <= "00000011";
		
-- wait until ready = '1';
		for i in 0 to 7 loop
			tx_data <= in_datas(i);
			tx_en <= '1';
			wait for 10 ns;
			tx_en <= '0';
		
			wait until tx_empty = '1';
		end loop;

	end process tx_bytes_test;	
	
	-- 
	-- test case for receiving bytes and compare with the raw data correctly
	rx_bytes_test:process
	begin  				  
		wait for 20 ns;
		
		loop_data: for j in 0 to 7 loop
			wait for 20 ns;
			rx <= '0';	-- start signal
			in_data <= in_datas(j);
			wait for 16*20 ns; 
			
			-- data bits
			loop_byte: for i in 0 to 7 loop
				rx <= in_data(i);
				wait for 16*20 ns;
			end loop loop_byte;
			
			rx <= '1';
			wait until rx_ready = '1';
			
			assert( rx_data = in_data)
				report("UART RX data is wrong")
				severity error;
		end loop loop_data;
		
	end process rx_bytes_test;	  
	
		
end architecture;
