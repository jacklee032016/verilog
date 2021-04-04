-- test circuit for UART core
-- Dec.12, 2020

library ieee;
use ieee.std_logic_1164.all;

use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity uart_test is
	generic(
		DATA_BIT: integer := 8; -- 7: 8 bits per byte
		OVER_SAMPLE : integer := 16;
		STOP_BIT: integer := 2;
		CLK_MOD: integer := 651;  -- 651 for baudrate 9600, eg. oversample rate		 
		TIME_LAPES : integer := 10; -- 10ms, real environment
		TIME_BASE: integer := 1_000  -- unit as ms for simulation
	);
	port(
		BTN: in std_logic_vector(4 downto 0);
		CLK: in std_logic;
		UART_RXD: in std_logic;
		UART_TXD: out std_logic;
		LED: out std_logic_vector(7 downto 0);
		SW: in std_logic_vector(7 downto 0)
--		txover: out std_logic
	);
end uart_test;

architecture uart_test_beh of uart_test is

signal rst_n: std_logic;

signal data: std_logic_vector(7 downto 0);
signal tx_data: std_logic_vector(7 downto 0) := "10101010";	
signal rx_data: std_logic_vector(7 downto 0);	

-- signal chr_index: integer range 0 to 15;
signal chr_index_r, chr_index_n : std_logic_vector(3 downto 0) := "0000";
signal tx_start_r, tx_start_n: std_logic := '0';
signal btnPressed: std_logic := '0';	
signal start_flag_r, start_flag_n: std_logic := '0';

signal rx_done: std_logic;
signal tx_empty: std_logic; -- test flow

-- for button toggle when change to high level
signal btn_tmp: std_logic_vector(1 downto 0);
signal btn_high: std_logic;

signal counter_r, counter_n: std_logic_vector(2 downto 0);
--			chr_index <= (others=>'0'); 
			-- LED <= (others=> '0'); 
--			tx_start <= '0';
--			tx_over <= '0';			 

signal ntick: std_logic;

begin
	
	rst_n <= not BTN(0);
	
	LED(0) <= not rst_n;

		-- my_chr_comp: rom_str
	my_chr_comp: entity work.rom_str(beh_str) -- dram_concurrent)
		port map(
			rst_n => rst_n, 
			clk => CLK,
			addr => chr_index_r,
			data => tx_data
		);

 	d_bouncer: entity work.debouncer(logic)
	generic map(
		TIME_LAPES=> TIME_LAPES, -- simulation and hw assign its generic differently in their code
		TIME_BASE=> TIME_BASE)
	port map(
		clk=>clk, 
		rst_n=>rst_n, 
		sw=>BTN(1), 
		db=>btnPressed
	);	-- btnPressed is level sensitive
	
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
			rx_data => rx_data,
			rx_done => rx_done,
		
		-- signals for TX
			UART_TXD => UART_TXD,
--			tx_data => tx_data,
--			tx_start => tx_start_r,
			tx_data => rx_data,
			tx_start => rx_done,
			tx_empty => tx_empty
	);
	
	pulse_comp: entity work.level_widepulse
		generic map(
			WIDTH => 1
		)
		port map(
			rst_n => rst_n,
			clk => clk,
			btn => btnPressed,
			ntick => ntick
	);
	
--	tx_over <= '1' when btnPressed = '1';	 -- circuit??
	
	ctrl_proc: process(rst_n, CLK)--, btnPressed, tx_over, btn_high)
	begin				 
		if(rst_n = '0') then
			btn_tmp <= (others=> '0');
			--btn_high <= '0'; --- !!! very important, assigned more than one time, this is problem of 'multiple driver', so the result is 'X'
			
			tx_start_r <= '0'; 
			start_flag_r <= '0';
			chr_index_r <= (others => '0');
			
			counter_r <= (others=>'0');
		elsif(rising_edge(clk)) then 
			btn_tmp(0) <= btnPressed;
			btn_tmp(1) <= btn_tmp(0); 
			
			tx_start_r <= tx_start_n;
			start_flag_r <= start_flag_n;
			chr_index_r <= chr_index_n;
			
			counter_r <= counter_n;
					--tx_start <= '1';
			
	--			else
			--end if;
		end if;
			
	end process ctrl_proc;		 
	
	tx_proc: process(btn_high, ntick, start_flag_r, tx_empty, chr_index_r )	
	begin	
		tx_start_n <= tx_start_r;
		chr_index_n <= chr_index_r;
		counter_n <= counter_r;
		
		if(btn_high = '1') then 
		-- if(ntick = '1' ) then -- btn_high only keep one tick
			if(start_flag_r = '0') then
				start_flag_n <= '1';			
				tx_start_n <= '1'; -- TX the first one, so 16 will be txed
			end if;	
		end if;

		if(start_flag_r = '1') then	
			if(tx_empty = '1') then -- TX is free now
				if(chr_index_r < 15) then
					chr_index_n <= chr_index_r +1;
					tx_start_n <= '1'; -- start TX
				else
					chr_index_n <= (others => '0');
					start_flag_n <= '0'; 
					tx_start_n <= '1';
				end if;	 
			end if;
		else
			tx_start_n <= '0';
		end if;	

	end process tx_proc;

	
btn_high <= btn_tmp(0) and (btn_tmp(0) and not btn_tmp(1));	  

--tx_over <= '1' when btn_high = '1' else
--			'0';
	
LED(1) <= btnPressed;	
LED(2) <= tx_start_r;
LED(3) <= not tx_empty;	 -- LED2: TX busy
LED(4) <= ntick;
LED(5) <= btn_high;

LED(6) <= rx_done;

-- txover <= tx_over;

end architecture;
