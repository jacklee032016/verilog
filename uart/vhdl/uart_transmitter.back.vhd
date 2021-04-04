library ieee;
use ieee.std_logic_1164.all;

entity uart_transmitter is
	generic(
		DATA_BIT: integer := 8; -- 7: 8 bits per byte
		OVER_SAMPLE : integer := 15;
		STOP_BIT: integer := 2;
		CLK_MOD: integer := 651  -- 651 for baudrate 9600, eg. oversample rate
	);
	
	port(
		rst_n, clk: in std_logic;
		data: in std_logic_vector(7 downto 0);
		wr_en: in std_logic;
		empty: out std_logic;
		tx: out std_logic
	);
end uart_transmitter;


architecture fsm_utx of uart_transmitter is

type STATE is (S_IDLE, S_START, S_TX, S_PARITY, S_STOP);
signal state_r, state_next: STATE;		

signal cnt_bit_r, cnt_bit_next: integer range 0 to DATA_BIT;
signal cnt_tick_r, cnt_tick_next: integer range 0 to OVER_SAMPLE*STOP_BIT;
signal data_r, data_next: std_logic_vector(7 downto 0);

signal mtick: std_logic;
signal tx_bit_r, tx_bit_next, empty_r, empty_next: std_logic;

-- clock 100MHz
-- 9600  x 16 = 153,600; 100x10**6/153,600 = 651	   (651x153,600=99,993,600)

begin
	-- clock of baudrate: one tick at the baudrate
	tbm: entity work.m_mod_counter
		generic map(	 
			-- for FPGA HW baudrate
			M=>CLK_MOD	-- for baudrate of simulation, CLK_MOD set as 5
--			M=>5  -- one baudrate tick in 5 clocks
		)
		port map(
			clk=>clk, 
			rst_n=>rst_n, 
			tick=>mtick	  -- 16 mtick sampling 1 bit
		);	  
		
	-- here, clk must be used, not mtick; otherwise, wr_en must be missed	
	process(rst_n, clk) -- clk
	begin
		if(rst_n = '0') then
			state_r <= S_IDLE;
			cnt_bit_r <= 0;
			cnt_tick_r <= 0;
			data_r <= (others=> '0');
			empty_r <= '1';
			tx_bit_r <= '1'; -- IDLE is high
		elsif (clk'event and clk = '1') then  -- no matter mtick is provided or not, here clk always is used
			state_r <= state_next;
			cnt_bit_r <= cnt_bit_next;
			cnt_tick_r <= cnt_tick_next;
			data_r <= data_next;
			
			empty_r <= empty_next;  -- registered output
			tx_bit_r <= tx_bit_next;
		end if;
	end process;
		
	
	process(state_r, wr_en, cnt_tick_r, cnt_bit_r, data_r, mtick) ---		 
	-- variable var_cnt_bit: integer range 0 to DATA_BIT;	
	-- variable var_cnt_tick: integer range 0 to OVER_SAMPLE*STOP_BIT;
	begin
		state_next <= state_r;

		cnt_bit_next <= cnt_bit_r;
		cnt_tick_next <= cnt_tick_r;
		-- var_cnt_bit := cnt_bit_r;
		
		data_next <= data_r;
		empty_next <= empty_r;
		tx_bit_next <= tx_bit_r; 
		
		case state_r is
			when S_IDLE =>			  
			-- wr_en can arrive at any time and at length of one tick;
			-- if wr_en is less than one tick, state_next will be reset to IDLE before it is set to S_START in next tick
				if(wr_en ='1' ) then  
					empty_next <= '0';
					tx_bit_next <= '0';	-- tx=0 means start bit
					data_next <= data;
					
					state_next <= S_START;					   
				end if;			
			
			when S_START =>   
				if(mtick = '1') then -- only op on state when mtick=1
					if(cnt_tick_r >= OVER_SAMPLE) then
						state_next <= S_TX;
						cnt_tick_next <= 0;
						cnt_bit_next <= 0; 
						
						-- enter TX state, so start first LSB bit
						tx_bit_next <= data_r(0);
						data_next <= '1' & data_r(7 downto 1) ; -- tx from LSB, pading 1, because 1 is also stop bit
	--					data_next <= data_r(6 downto 0) & data_r(7);
					else
						cnt_tick_next <= cnt_tick_r + 1;   -- drived by mtick now, not clock
					end if;				 
				end if;
			
			when S_TX =>
				--if(cnt_bit_r = DATA_BIT) then	-- this mode will add one more tick before beginning of stop bits
				--	cnt_bit_next <= 0;
				--	cnt_tick_next <= 0;	 
					
				--	state_next <= S_STOP; 
				--	tx_bit_next <= '1'; -- send high in STOP state

				--els 
				if(mtick = '1') then
				if(cnt_tick_r = OVER_SAMPLE) then
					data_next <= '1' & data_r(7 downto 1); -- padding 1 is better, for stop bit
--					data_next <= data_r(6 downto 0) & data_r(7);
					tx_bit_next <= data_r(0);
					cnt_tick_next <= 0;
					
					cnt_bit_next <= cnt_bit_r + 1;
					if(cnt_bit_r = DATA_BIT-1)  then
						cnt_bit_next <= 0;
						cnt_tick_next <= 0;	 
					
						state_next <= S_STOP; 
						tx_bit_next <= '1'; -- send high in STOP state	
					end if;
						
				else
					cnt_tick_next <= cnt_tick_r +1;
				end if;		
				end if;
			
			when S_PARITY => null;
			
			when S_STOP =>	
				if(mtick = '1') then
				if(cnt_tick_r = OVER_SAMPLE*STOP_BIT) then
					cnt_tick_next <= 0;
					empty_next <= '1';
					state_next <= S_IDLE;
				else
					cnt_tick_next <= cnt_tick_r + 1;
				end if;			
				
				end if;
				
			when others=> null;
			
		end case;
		
		
	end process;  
	
	empty <= empty_r;
	tx <= tx_bit_r;
	

	
end architecture;
