-- interface circuit with FPGA board
library ieee;
use ieee.std_logic_1164.all;

-- operator for std_logic_vector + 1
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity uart_ctrl is
	port(
		BTN: in std_logic_vector(4 downto 0);
		SW: in std_logic_vector(7 downto 0);
		LED: out std_logic_vector(7 downto 0);
		CLK: in std_logic;
		UART_TXD: out std_logic);
end uart_ctrl;


architecture test_circuit of uart_ctrl is					

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

--signal uart_tx: std_logic;
signal fake_rst : std_logic := '0';

begin

    -- LED <= SW;
	
	rst_n <= not BTN(0); -- BTN: unpressed: low level; pressed: high
	
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
	
	btnAdd <= btnDff(0) xor btnDff(1);
	
	test_db: process(clk, rst_n, btnPressed )
	begin	 
		if(rst_n = '0' ) then
			btnCount <= 8; -- (others=>'0'); 
			led_r <= (others => '1'); -- reset: all LEDs ON
			-- btnPressed <= (others=>'0');
		elsif(rising_edge(clk) )	then  
			--if(btnPoress)		  
			--led_loop: for i in 0 to 7	loop
			--	LED(i) <= '0';
			--end loop led_loop;   
			if(btnCount = 8) then
 				led_r <= (others => '0'); -- turn all LED off	 
				btnCount <= 0; 
			end if;	 

			
			btnDff(0) <= btnPressed;
			btnDff(1) <= btnDff(0);
			if(btnAdd = '1') then	
				-- LED(conv_integer(unsigned(btnCount))) <= '1';   
				
				led_r <= (others => '0'); -- turn all LED off
				if(btnCount < 7) then 	   
					btnCount <= btnCount + 1;
				else
					btnCount <= 0; -- (others=>'0');
				end if;	
				
				led_r(btnCount) <= '1';  -- one LED is on when button toggled
			end if;
		end if;
			
	end process test_db;
	
	--led_off: for i in 0 to 7 generate
	--	LED(i) <= '0';
	-- end generate led_off;
	
	-- LED(conv_integer(unsigned(btnCount))) <= '1';
	LED <= led_r;
	
	
	
	
	--deb: entity work.debouncer(logic)
	--port(clk => CLK, rst => : in std_logic;
	--	sw: in std_logic;
	--	db: out std_logic
	--);
    -- rst <= BTN(0);
--    uart_tx <= UART_TXD;
    
	-- delay_timer: entity work.delay(beh_rest)
--		generic map(COUNT_DELAY=>1000) -- 1000ms
--	port map(clk => clk, rst=>rst, en => tick_en,
--	tick=>second_tick);	
	--LED(0) <= second_tick;					
	
	-- read char
	--char_rom: entity work.rom_str
	--	port map(rst=>rst, clk=>clk, addr=>chr_index, data=>data);
		
	--uart_transmit: entity work.uart_transmitter 	
	--	port map(rst=>rst, clk=>clk, data=>data2, wr_en => tx_en, empty => tx_ready, tx => UART_TXD);	
	
		
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
