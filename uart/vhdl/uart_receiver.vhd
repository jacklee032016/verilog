-- UART Receiver
-- baudrate from outside

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_receiver is
	generic(
		DATA_BIT: integer :=8;
		STOP_BIT: integer :=2;
		OVER_SAMPLE: integer :=16 );
	port(
		rst_n, clk: in std_logic;
		baud_tick: in std_logic;	-- oversample, 16xbaudrate; strict one tick of clock
		rx: in std_logic;
		dout: out std_logic_vector(7 downto 0);		-- continue only for STOP_BIT period
		done: out std_logic
	);
end uart_receiver;


architecture uart_rx of uart_receiver is
-- states
type STATE is (S_IDLE, S_START, S_DATA, S_STOP);
signal state_r, state_next: STATE;

-- counter
signal baud_count_r, baud_count_next: integer range 0 to STOP_BIT*OVER_SAMPLE -1 + 7;
signal bit_count_r, bit_count_next: integer range 0 to DATA_BIT -1;

-- registered output
signal buf_r, buf_next: std_logic_vector(7 downto 0);  
signal rdy_r, rdy_next: std_logic;

begin
	reg_pro: process(rst_n, clk)
	begin
		if(rst_n ='0' ) then
			state_r <= S_IDLE;
			baud_count_r <= 0;
			bit_count_r <= 0;	  
			
			buf_r <= (others=> '0');
			rdy_r <= '0';
		elsif(rising_edge(clk) ) then
			state_r <= state_next;
			baud_count_r <= baud_count_next;
			bit_count_r <= bit_count_next;
			
			buf_r <= buf_next;
			rdy_r <= rdy_next;
		end if;
	end process reg_pro;

	-- every signal must be added into this sensitivity list. 
	-- For example,rdy_r is not check, but assign to rdy_next; if it is not in list, 
	-- rdy_next will keep its default value 'X' after reset rdy_r to '0';
	
	-- other signals, such as state_r, rdy_r, are also in list. Maybe they make the count
	-- step more faster than just baud_clk????
	-- yes. so add baud_clk checking when try to update the counts; and baud_clk must strictly be one tick
	state_pro: process(state_r, baud_count_r, bit_count_r, rdy_r, baud_tick, rx)
	begin					   
		state_next <= state_r;				
		baud_count_next <= baud_count_r;
		bit_count_next <= bit_count_r;
		
		buf_next <= buf_r;
		-- rdy_next <= rdy_r; -- change like following, so ready can keep one period of clock
		
		-- rdy_next <= '0';
				
		case state_r is
			when S_IDLE =>
				rdy_next <= '0'; -- here, make ready signal keep one period of baudrate, for test
				if(rx = '0') then
					state_next <= S_START;
					baud_count_next <= 0;
				end if;
			
			when S_START =>		 
			if(baud_tick = '1' ) then
				if(rx = '0') then -- first low level in state of IDLE, so baud_tick is not checked
					if(baud_count_r =(OVER_SAMPLE/2-1)) then
						--baud_count_next <= 0;
						state_next <= S_DATA;
						bit_count_next <= 0;
						-- baud_count_next <= baud_count_r +1;	 
						baud_count_next <= 0;	-- restart count to 15 
						-- rdy_next <= '1'; test FSM
					else
						baud_count_next <= baud_count_r +1;
					end if;
				else
					state_next <= S_IDLE;
				end if;				  
			end if;	
			
			when S_DATA => 	   
			if(baud_tick = '1') then
				if(baud_count_r = OVER_SAMPLE-1) then -- sample at the middle point of OVER_SAMPLE period
					-- buf_next <= buf_r(6 downto 0) & rx;	-- send LSB first
					buf_next <= rx & buf_r(7 downto 1); -- at TX, LSB first; at RX, right shift
					if(bit_count_r = DATA_BIT -1 )	then 
						state_next <= S_STOP;
						
						-- rdy_next <= '1';  -- ready will be earlier about half period ??
					else
						bit_count_next <= bit_count_r +1;					
					end if;
					baud_count_next <= 0; --sampled, then from begin
				else
					baud_count_next <= baud_count_r + 1;
				end if;
			end if;

			when S_STOP =>
			if(baud_tick = '1')	then
				if(baud_count_r = STOP_BIT*OVER_SAMPLE-1 + 7) then
					state_next <= S_IDLE;
					rdy_next <= '1'; -- after stop bit, then one period of clock
				else
					baud_count_next <= baud_count_r + 1;
				end if;	
			end if;
			
			when others => null;
			
		end case;	
		
	end process state_pro;

dout <= buf_r when rdy_r = '1' else
	(others=> '0');			
	
done <= rdy_r;

end architecture;
