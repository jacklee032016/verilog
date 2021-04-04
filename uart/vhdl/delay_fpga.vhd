-- interface circuit with FPGA board			 
-- used to test delay

library ieee;
use ieee.std_logic_1164.all;

-- operator for std_logic_vector + 1
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity delay_fpga is
	port(
		BTN: in std_logic_vector(4 downto 0);
		SW: in std_logic_vector(7 downto 0);
		LED: out std_logic_vector(7 downto 0);
		CLK: in std_logic;
		UART_TXD: out std_logic;
		UART_RXD: in std_logic);
end delay_fpga;


architecture test_circuit of delay_fpga is					

signal chr_index : std_logic_vector(3 downto 0) := "0000";
signal second_tick : std_logic;	   
signal tick_en: std_logic := '1';	

signal tx_ready: std_logic := '0';
signal tx_en: std_logic := '1';

signal data: std_logic_vector(7 downto 0);

signal data2: std_logic_vector(7 downto 0) := X"41";

signal read_cnt: integer range 0 to 2 := 0;
signal rst_n : std_logic;			   

signal btnPressed: std_logic;
signal btnCount: integer range 0 to 8; -- std_logic_vector(7 downto 0);							  
signal btnDff: std_logic_vector (1 downto 0);
signal btnAdd: std_logic;			   
signal led_r, led_next: std_logic_vector(7 downto 0);		  
signal baud_tick: std_logic;

signal led_blink_r: std_logic;

--signal uart_tx: std_logic;
signal fake_rst : std_logic := '0';

--component rom_str is
--	generic(DEPTH: integer := 16;
--	WIDTH: integer := 8);
--	port(rst_n, clk: in std_logic;
--	addr: in std_logic_vector(3 downto 0);
--	data: out std_logic_vector(WIDTH-1 downto 0));
--end component;

begin
	
	-- reset signal BTN(0)
	rst_n <= not BTN(0); -- BTN: unpressed: low level; pressed: high
	
	-- delay circuit
	delay_timer: entity work.delay(beh_one_counter)
		generic map(		 
			-- for FPGA hw: delay 100 ms=(100x10**6)/(10x10**6); delay 1s: (100x10**6)/(100x10**6)
			COUNT_PER_MS => 100_1000,
			COUNT_DELAY => 100
			
			-- for simulation: delay: 100 ns= 10 period
--			COUNT_DELAY =>10,
--			COUNT_PER_MS => 1
		)
		port map(
			clk => clk, 
			rst_n=>rst_n, 
			en => SW(0),
			tick=>second_tick
		);	
	--LED(0) <= second_tick;		
	
	-- my_chr_comp: rom_str
	my_chr_comp: entity work.rom_str(beh_str) -- dram_concurrent)
		port map(
			rst_n => rst_n, 
			clk => clk,
			addr => chr_index,
			data => data
		);

	-- debug button, and result to drive UART TX		
	d_bouncer: entity work.debouncer(logic)
	generic map(
		-- FPGA HW
--		TIME_LAPES=>2_000, -- 2s, test
		TIME_LAPES=>10, -- 10ms, real environment
		TIME_BASE=>1_000)  -- unit as ms for simulation

		-- Simulation
--		TIME_LAPES=>1, -- 1 us
--		TIME_BASE=>1_000_000)  -- unit as us for simulation
	port map(clk=>clk, rst_n=>rst_n, sw=>BTN(1), db=>btnPressed);

	tbm: entity work.m_mod_counter
	generic map(	 
		-- for FPGA HW baudrate
			M=>651	-- for baudrate of simulation, CLK_MOD set as 5
		-- M=>2  -- one baudrate tick in 5 clocks
	)
	port map(
		clk=>clk, 
		rst_n=>rst_n, 
		tick=>baud_tick	  -- 16 mtick sampling 1 bit
	);	  				

	--uart_tx: entity work.uart_transmitter 	
	--	port map(rst=>rst, clk=>clk, data=>data2, wr_en => tx_en, empty => tx_ready, tx => UART_TXD);	
	uart_tx: entity work.uart_transmitter 	
		--generic map(
		
			-- use in simulation; comments for hw 9600
			-- CLK_MOD => 5
		--)
		port map(
			rst_n => rst_n, 
			clk => clk,	 
			baud_tick => baud_tick,
			din => data, 
			start => tx_en,
			empty => tx_ready, 
			tx => UART_TXD
		);		
	
	-- circuit to control read ROM which drived by BTN(1); then Send to UART TX
	process(clk, rst_n, btnPressed)
	begin
		if(rst_n = '0') then  
			led_blink_r <= '0';
			chr_index <= (others => '0');
		elsif(rising_edge(clk)) then
			if(btnPressed = '1') then 
				tx_en <= '0';
				LED(7) <= '0';
				if(tx_ready = '1') then
					if(chr_index = 15) then
						chr_index <= (others => '0');
					else
						chr_index <= chr_index+1;
					end if;	
					tx_en <= '1'; -- start TX
				else
					LED(7) <= '0'; -- if Transmitter is busy, turn alert on
				end if;	
			end if;
		end if;
	end process;
	
		
	-- circuit to control read ROM which drived by SW(0)
	process(clk, rst_n, second_tick)
	begin
		if(rst_n = '0') then  
			led_blink_r <= '0';
--			chr_index <= (others => '0');
		elsif(rising_edge(clk)) then
			if(second_tick = '1') then
				led_blink_r <= not led_blink_r;
--				if(chr_index = 15) then
--					chr_index <= (others => '0');
--				else
--					chr_index <= chr_index+1;
--				end if;	
			end if;
		end if;
	end process;
	
	-- test delay and its tick directly
	-- LED(0) <= led_blink_r;
	-- LED(1) <= second_tick;	 	   
	
	-- test	ROM read
	LED <= data;
	
	
	-- another delay and toggle TX
--	process(clk, rst)
--	begin		
--		if(rst = '1') then
--			read_cnt <= 0;
--			chr_index <= (others=> '0');
--			tx_en <= '0';
--		elsif(rising_edge(clk)) then
--			if(second_tick ='1') then
--				if(read_cnt = 2) then
--					read_cnt <= 0;
--					chr_index <= chr_index +1; -- another char
--					tx_en <= not tx_en;
--				else 
--					read_cnt <= read_cnt +1;
--				end if;
--			end if;
--		end if;	
--	end process;
	

end architecture;
