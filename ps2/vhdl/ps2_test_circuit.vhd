-- mainly used to test signal of ps2 on fpga board

library ieee;
use ieee.std_logic_1164.all;

entity ps2_test_circuit is
	generic(
		CLK_MOD: integer := 651 -- 9600
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
--;rx_ready: out std_logic
	);
end ps2_test_circuit;	

architecture test_arch of ps2_test_circuit is

signal rst_n: std_logic;

signal fall_edge: std_logic;

signal ps2_en_r, ps2_en_n: std_logic;
signal ps2_rx_done: std_logic;
signal ps2_rx_data: std_logic_vector(7 downto 0);

signal rx_data_r, rx_data_n: std_logic_vector(7 downto 0);	
signal uart_wr: std_logic;	   
signal tx_free: std_logic;

begin			 
		-- reset signal and light LED-0
	rst_n <= not BTN(0);
	--LED(0) <= not rst_n;

	-- PS2 receiver
	ps2_rx: entity work.ps2_rx
		port map(
			rst_n => rst_n,
			clk => CLK,
			ps2clk => ps2_clk,
			ps2d => ps2_data, 
			ps2en => ps2_en_r,
			
			dout => ps2_rx_data,
			dready => ps2_rx_done
--			fall => fall_edge
		);
-- rx_ready <= ps2_rx_done;
		
	uart_comp: entity work.uart
		generic map(
		--	DATA_BIT => DATA_BIT,
		--	STOP_BIT => STOP_BIT,
		--	OVER_SAMPLE => OVER_SAMPLE,
			CLK_MOD => CLK_MOD
		)
		port map(
			rst_n =>rst_n,
			clk => CLK, 
	
		-- signal for RX
			UART_RXD => '1',
			rx_data => open, -- output signal, open
			rx_done => open,
		
		-- signals for TX
			UART_TXD => UART_TXD,
			tx_data => rx_data_r,
			tx_start => uart_wr,
			tx_empty => tx_free
	);
	

	process(clk, rst_n)
	begin
		if(rst_n = '0') then
			rx_data_r <= "10101010";
			ps2_en_r <= '1';
		elsif(rising_edge(clk)) then		 
			rx_data_r <= rx_data_n;
			ps2_en_r <= ps2_en_n;
		end if;
		
	end process;
	
	uart_wr <= not 	ps2_en_r;
	process(ps2_rx_done, ps2_rx_data, tx_free) 
	begin
		rx_data_n <= rx_data_r;
		ps2_en_n <= ps2_en_r;
		
		-- rx_data_r and ps2_en_r will be later one tick than ps2_rx_done 
		if(ps2_rx_done = '1') then	
			if(tx_free = '1') then -- ignore the data when uart tx is busy
				rx_data_n <= ps2_rx_data;	
				ps2_en_n <= '0'; 
			end if;	
		end if;			
		
		-- when rx_data_r get data for UART TX, ps2_rx can begin to receive next scan code
		if(tx_free = '1' ) then
			if(ps2_en_r = '0') then
				ps2_en_n <= '1';
			end if;
			
		end if;
		
	end process;
	
	LED <= rx_data_r; --rx_data_r;   
	--LED(1) <= ps2_rx_done;
	--LED(2) <= fall_edge;
	--LED(3) <= uart_wr;
	--LED(4) <= ps2_en_r;
	
end architecture;	
