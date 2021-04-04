-- scan code monitor circuit
-- receive scan code, divide every code into 2 bytes; heximal of half byte, and send to uart with a extra SPACE byte
-- glue logic with different circuit parts
-- 12.19, 2020

library ieee;
use ieee.std_logic_1164.all;

entity scan_code_monitor is
	generic(
		-- param for UART 
		DATA_BIT: integer := 8; -- 7: 8 bits per byte
		OVER_SAMPLE : integer := 16;
		STOP_BIT: integer := 2;
		CLK_MOD: integer := 651  -- 651 for baudrate 9600, eg. oversample rate	
	);
	
	port(
		BTN: in std_logic_vector(4 downto 0);
		CLK: in std_logic;
		-- uart signals
		UART_RXD: in std_logic;
		UART_TXD: out std_logic;
		LED: out std_logic_vector(7 downto 0);
		SW: in std_logic_vector(7 downto 0);
		
		-- HID-PS2 signals
		ps2_clk: in std_logic;
		ps2_data: in std_logic
		
--		;rx_data: out std_logic_vector(7 downto 0)

--		ps2_clk, ps2_data: in std_logic;
--		uart_tx: out std_logic;
--		uart_tx_en: out std_logic;  -- signal only for test
--		uart_tx_data: out std_logic_vector(7 downto 0);	-- only for test
--		uart_tx_done: in std_logic	
	);
end scan_code_monitor;

architecture arch of scan_code_monitor is

type STATE is (S_IDLE, S_PREPARE, S_SEND_H, S_SEND_L, S_SEND_SP);
constant SPACE_CHAR: std_logic_vector(7 downto 0) := X"20";

-- signals about PS2 receiver
signal ps2_rx_data: std_logic_vector(7 downto 0);
signal ps2_data_ready: std_logic;  
signal ps2_en: std_logic;
signal fall_edge: std_logic;

signal slow_sig: std_logic;

-- signals about UART Transmitter
signal uart_wr_data_r, uart_wr_data_n: std_logic_vector(7 downto 0);
--signal uart_wr_en_r, uart_wr_en_n: std_logic; 
signal uart_wr_en: std_logic;
signal uart_wr_done: std_logic;


signal ascii_char: std_logic_vector(7 downto 0);   
signal hex_code: std_logic_vector(3 downto 0);

signal state_r, state_n: STATE;
signal uart_data_r, uart_data_n: std_logic_vector(7 downto 0);

signal rst_n: std_logic;

begin

	-- reset signal and light LED-0
	rst_n <= not BTN(0);
	LED(0) <= not rst_n;

	-- PS2 receiver
	ps2_rx: entity work.ps2_rx2
		port map(
			rst_n => rst_n,
			clk => CLK,
			ps2clk => ps2_clk,
			ps2d => ps2_data,
			ps2en => ps2_en,
			dout => ps2_rx_data,
			dready => ps2_data_ready
			
--			fall => fall_edge
		);

		-- PS2 receiver
	-- pps2_rx: entity work.pps2_rx 
	--	port map(
	--		rst_n => rst_n,
	--		clk => CLK,
	--		ps2c => ps2_clk,
	--		ps2d => ps2_data,
			
	--		rx_en  => '1',
	--		rx_done_tick => ps2_data_ready,
	--		dout => ps2_rx_data
	--	);
	
		
--	led_on:	entity work.level_widepulse
--		generic map(
--			WIDTH => 100000000
--		)
--		port map(
--			rst_n => rst_n,
--			clk => CLK,
			-- btn => ps2_data+ready,
--			btn => fall_edge,
--			ntick => slow_sig
--	);		 

	
LED(1) <= ps2_data_ready;	
LED(2) <= not uart_wr_done;
LED(3) <= uart_wr_en;
LED(4) <= fall_edge;

--rx_data <= uart_wr_data_r;

	-- UART, only tx is used; rx, no connection	
	uart_comp: entity work.uart
		generic map(
			DATA_BIT => DATA_BIT,
			STOP_BIT => STOP_BIT,
			OVER_SAMPLE => OVER_SAMPLE,
			CLK_MOD => CLK_MOD
		)
		port map(
			rst_n =>rst_n,
			clk => CLK, 
	
		-- signal for RX
			UART_RXD => UART_RXD,
			rx_data => open, -- output signal, open
			rx_done => open,
		
		-- signals for TX
			UART_TXD => UART_TXD,
--			tx_data => tx_data,
--			tx_start => tx_start_r,
			tx_data => uart_wr_data_r,
			tx_start => uart_wr_en,
			tx_empty => uart_wr_done
	);
	

	
-- uart_tx_data <= uart_wr_data;
-- uart_tx_en <= uart_wr_en;  
-- uart_wr_done <= uart_tx_done;
		
	reg_proc:process(rst_n, clk)
	begin
		if(rst_n = '0') then
			state_r <= S_IDLE; 
			uart_data_r <= (others=>'0'); 
			uart_wr_data_r <= (others => '0');
			--uart_wr_en_r <= '0';
		elsif(rising_edge(clk))	then
			state_r <= state_n;
			uart_data_r <= uart_data_n;
			uart_wr_data_r <= uart_wr_data_n;
			--uart_wr_en_r <= uart_wr_en_n;
		end if;	
	end process reg_proc;
	
	next_state_proc: process(state_r, ps2_data_ready, uart_wr_done, ascii_char) -- 
	begin				 
		state_n <= state_r;	 
		uart_wr_en <= '0';
		uart_data_n <= uart_data_r;	   
		uart_wr_data_n <= uart_wr_data_r;
		
		case state_r is
			when S_IDLE =>
				LED(7) <= '0';
				ps2_en <= '1';
				uart_wr_data_n <= (others=> '0');
				if(ps2_data_ready ='1') then 
					ps2_en <= '0';
					state_n <= S_PREPARE;
					-- send out data at beginning of next clock tick, not now
					uart_wr_en <= '1';
					uart_data_n <= ps2_rx_data;	  -- one tick to update local registered data
					-- uart_wr_data <= ascii_char;
				end if;
			when S_PREPARE => 	-- stay for one tick in this state
				state_n <= S_SEND_H;
				uart_wr_en <= '1';	-- so uart_wr_done is '0' when enter into S_SEND_H state
				uart_wr_data_n <= ascii_char;	   
				LED(5) <= '1';
				
			when S_SEND_H => -- stay for one UART char period 
				if(uart_wr_done = '1') then
					state_n <= S_SEND_L;
					uart_wr_en <= '1'; -- start tx in state of S_SEND_L
					uart_wr_data_n <= ascii_char;	   
				end if;
				
			when S_SEND_L => 
				if(uart_wr_done ='1' ) then
					state_n <= S_SEND_SP;
					uart_wr_en <= '1';-- start tx in state of S_SEND_SP
					uart_wr_data_n <= ascii_char;
					LED(5) <= '0';
					LED(6) <= '1';
				end if;
				
			when S_SEND_SP => 
				if(uart_wr_done = '1') then
					state_n <= S_IDLE;
					-- uart_wr_en_n <= '1';	-- no more TX needed now
					uart_wr_data_n <= SPACE_CHAR;
					LED(6) <= '0';
					LED(7) <= '1';
				end if;	
				
			when others=> 
				null;
		end case;
		
	end process next_state_proc;

hex_code <= uart_data_r(7 downto 4)	 when state_r = S_PREPARE else
	uart_data_r(3 downto 0);
	
with hex_code select
ascii_char <= 
		X"30" when "0000", -- "0"
		X"31" when "0001", -- "1"
		X"32" when "0010", -- "2"
		X"33" when "0011", -- "3"
		X"34" when "0100", -- "4"
		X"35" when "0101", -- "5"
		X"36" when "0110", -- "6"
		X"37" when "0111", -- "7"
		X"38" when "1000", -- "8"
		X"39" when "1001", -- "9"
		X"41" when "1010", -- "A"
		X"42" when "1011", -- "B"
		X"43" when "1100", -- "C"
		X"44" when "1101", -- "D"
		X"45" when "1110", -- "E"
		X"46" when others;	-- "F"
	
	
end architecture;
