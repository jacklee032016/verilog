-- UART IP, include Transmitter, receiver, baudrate generator, FIFO
-- Dec.11th, 2020 Jack Lee

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
	generic(
		BAUD_RATE : integer := 9600;
		DATA_BIT: integer := 8; -- 7: 8 bits per byte
		OVER_SAMPLE : integer := 16;
		STOP_BIT: integer := 2;
		CLK_MOD: integer := 651  -- 651 for baudrate 9600, eg. oversample rate
	);
	port(
		rst_n, clk: in std_logic;
	
	-- signal for RX
		UART_RXD: in std_logic;
		rx_data: out std_logic_vector(7 downto 0);
		rx_done: out std_logic;
		
	-- signals for TX
		UART_TXD: out std_logic;
		tx_data: in std_logic_vector(7 downto 0);
		tx_start: in std_logic; -- drive to send out
		tx_empty: out std_logic -- remove this signal
	);
end uart;


architecture uart_imp of uart is

signal baud_tick: std_logic;
signal not_empty: std_logic;

begin
	tbm: entity work.m_mod_counter
		generic map(	 
			-- for FPGA HW baudrate
			M=>CLK_MOD	-- for baudrate of simulation, CLK_MOD set as 5
--			M=>2  -- one baudrate tick in 5 clocks
		)
		port map(
			clk=>clk, 
			rst_n=>rst_n, 
			tick=>baud_tick	  -- 16 mtick sampling 1 bit
		);	  				
	
	uart_rx_t: entity work.uart_receiver
		generic map(
			DATA_BIT => DATA_BIT,
			STOP_BIT => STOP_BIT,
			OVER_SAMPLE => OVER_SAMPLE
		)
		port map(
			rst_n => rst_n, 
			clk => clk, 
			baud_tick => baud_tick,
			rx => UART_RXD, 
			dout => rx_data,
			done => rx_done
		);

		
	--fifo_comp: entity work.fifo 
	--	generic map(
	--		WORD_BIT => 8,
	--		ADDR_BIT => 2 -- 2**4, ie. 4 buffers
	--	)
	--	port map(
	--		rst_n => rst_n,
	--		clk => clk,
			
			-- input of FIFO from UART RX
	--		wr => rx_ready,  -- RX finish
	--		w_data => rx_data, -- RX data from UART, write to FIFO
			
			-- output of FIFO to UART TX
	--		rd => rd,
	--		r_data => tx_data,		 
			
	--		full => open,  -- not use
	--		empty => empty
	--	);
		
		
	uart_tx_t: entity work.uart_transmitter
		generic map(
			DATA_BIT => DATA_BIT,
			OVER_SAMPLE => OVER_SAMPLE,
			STOP_BIT => STOP_BIT
		)
		port map(
			rst_n => rst_n, 
			clk => clk, 
			baud_tick => baud_tick,
			
			din => tx_data,
			start => tx_start,
			empty => tx_empty,
			tx => UART_TXD
		);
		
	
end architecture;
