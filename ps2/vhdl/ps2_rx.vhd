-- PS2 receiver circuit	  
-- Dec.14, 2020, Jack Lee

-- protocol:
-- receive one package, eg. one byte
-- PS2 protocol: start bit + data bits(8) + odd parity bit + stop bit: 11 bits
-- ps2_clock: 10KHz ~ 16.7KHz, eg. 60 ~100us
-- sample at falling_edge of ps2_clock

-- design:
-- debouncer ps2_data and ps2_clk, eg. 4us debouncer
-- idle cycle: debounce, half period of STOP bit(or ps2_clock), ie. 30us	
-- falling edge detect: out one tick after detecting falling edge


library ieee;
use ieee.std_logic_1164.all;


entity ps2_rx is
	-- generic(
	--	PS2_CLK_DEB_LIMIT: integer := 600; -- 600 cycles of clock, 6us; specs: 5us ~ 25us
	--	PS2_IDLE_DEB_LIMIT: integer := 4000 -- 4000 cycles, 4000x10ns = 40us; specs: 30~50us
	-- );									
	-- it is better to add one port of rx_en for duplex ps2 connection
	port(
		rst_n, clk: in std_logic;
		ps2d: in std_logic;
		ps2clk: in std_logic;
		ps2en: in std_logic;	   -- refuse more data if need
		dout: out std_logic_vector(7 downto 0);	
		dready: out std_logic;

		fall: out std_logic
	);
end ps2_rx;


architecture arch of ps2_rx is

-- about falling edge detect of PS2 clock signal
signal filted_clk_r, filted_clk_n: std_logic_vector(7 downto 0);
signal fall_edge_r, fall_edge_n: std_logic;
signal fall_edge: std_logic;

-- debounce signal
-- signal deb_ps2_clk, deb_ps2_data: std_logic;


-- FSM of RX
type STATE is (S_IDLE, S_START, S_DATA, S_READY);
signal state_r, state_n: STATE;		
signal rx_bits_r, rx_bits_n: integer range 0 to 9;
signal rx_data_r, rx_data_n: std_logic_vector(8 downto 0); -- total 9 bits (one bit fir parity(odd) ) for one package
signal rx_data_ready_r, rx_data_ready_n: std_logic;
	
begin						   
	
	-- RX FSM
	-- register of FSM
	state_reg_proc: process(rst_n, clk)
	begin
		if(rst_n = '0') then
			state_r <= S_IDLE;
			rx_bits_r <= 0;
			rx_data_ready_r <= '0';
			rx_data_r <= (others=> '0');
		elsif(rising_edge(clk)) then
			state_r <= state_n;
			rx_bits_r <= rx_bits_n;
			rx_data_ready_r <= rx_data_ready_n;
			rx_data_r <= rx_data_n;
		end if;		
	end process state_reg_proc;
	
	-- next state in FSM		--		   deb_ps2_clk, 
	state_next_proc: process(state_r, fall_edge)--, rx_data_ready_r) -- rx_bits_r: add this in sensitivity list make sample faster twice
	begin			 
		state_n <= state_r;
		rx_bits_n <= rx_bits_r;
		rx_data_ready_n <= rx_data_ready_r;
		rx_data_n <= rx_data_r;
		
		case state_r is 
			when S_IDLE => 						  
				rx_data_ready_n <= '0'; -- one tick for data ready
				-- change state when ps2_data is low and ps2_clk fall edge
				if(fall_edge = '1' and ps2en = '1' ) then -- indicate start bit 					
					state_n <= S_DATA; -- sample data at next falling edge of ps2 clock , so no start state is needed
				end if;				
			
			when S_START => 
				if( fall_edge = '1') then
					state_n <= S_DATA;
				end if;			
			
			when S_DATA => 
				if( fall_edge = '1') then
					if(rx_bits_r = 9) then -- sample from 0 to 8, total 9 bit (1 bit for odd parity)
						state_n <= S_IDLE;
						rx_data_ready_n <= '1'; -- one tick for data ready	
						rx_bits_n <= 0;	
					else
						rx_bits_n <= rx_bits_r +1;
						rx_data_n	<= ps2d & rx_data_r(8 downto 1);
					end if;
					-- rx_bits_ 
				end if;	
			
			when S_READY =>	 --
				if( fall_edge = '1') then -- No.9 falling edege, in the middle of stop bit
					state_n <= S_IDLE;
					rx_data_ready_n <= '1'; -- one tick for data ready
				end if;	
			
			when others => null;	 
		end case;
		
	end process state_next_proc;

	-- registered output for one tick												 -- now it is registered output, so no rx_data_ready_r check is needed
dout <= rx_data_r(7 downto 0) when rx_data_ready_r = '1' else
		 (others => '0');

dready <= rx_data_ready_r;

	
	-- detect fall_edge, out one tick
	fall_edge_proc: process(clk, rst_n)
	begin				   
		if(rst_n = '0') then  
			filted_clk_r <= (others => '0');
			fall_edge_r <= '0';			   
		elsif(rising_edge(clk)) then
			filted_clk_r <= filted_clk_n;
			fall_edge_r <= fall_edge_n;
		end if;
	end process fall_edge_proc;

	-- tick will delay 8 cycle of clock only when the signal keeps 8 cycle
	filted_clk_n <= ps2clk & filted_clk_r(7 downto 1); -- if all 1s, keep output 1; so only one tick output
	fall_edge_n <= '1' when filted_clk_r = "11111111" else
		'0' when filted_clk_r = "00000000" else
		fall_edge_r;
		
	-- fall_edge is a signal, not register, but fall_edge_r is registered, so output is registered 	
	fall_edge <= fall_edge_r and (not fall_edge_n); -- detect falling edge 
	

	-- output for test
fall <= fall_edge;	
	

end architecture;	
