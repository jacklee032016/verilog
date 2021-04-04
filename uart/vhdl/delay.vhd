-- delay output a tick which last for one period of clock

library ieee;
use ieee.std_logic_1164.all;

-- delay time is COUNTER_PER_MS*COUNT_DELAY*period of clock
entity delay is
	generic(
		COUNT_PER_MS: integer := 100_1000;	-- clock count per ms when 100MHz
		COUNT_DELAY: integer := 100
	); -- count of ms								 
	port(
		clk, rst_n: in std_logic;
		en: in std_logic;
		tick: out std_logic
	); -- one tick for one clock period 
end delay;


architecture beh_two_counter of delay is
signal count_ms_r: integer :=0;
signal count_delay_r: integer :=0;
signal mtick: std_logic := '0';
signal ms_done : std_logic := '0';

begin							  
	timer_ms: process(clk, rst_n, en)   
	begin						   
		-- one signal can be assigned in 2 or more processes, so rst is not
		--if(rst_n = '0') then
		--	mtick <= '0';
		--	ms_done <= '0';
		--	count_ms_r <= 0;
		--	count_delay_r <= 0;
		--els
		if(rising_edge(clk) ) then
			if(en = '1') then
				if(count_ms_r = COUNT_PER_MS) then
					ms_done <= '1';
					count_ms_r <= 0;
				else							
					ms_done <= '0';
					count_ms_r <= count_ms_r +1;
				end if;
			end if;
		end if;
			
	end process timer_ms;	   
	
	timer_delay:process(clk)
	begin				   
		if(rising_edge(clk)) then
			if(count_delay_r = COUNT_DELAY) then
				mtick <= '1';
				count_delay_r <= 0;
--				count_ms_r <= 0;
			else
				mtick <= '0';
				count_delay_r <= count_delay_r + 1;
			end if;
		end if;
		
	end process timer_delay;
	
	tick <= mtick;
end;


architecture beh_one_counter of delay is
signal counter: integer range 0 to COUNT_PER_MS*COUNT_DELAY-1;
signal mtick: std_logic := '0';
begin						   
	delay_pro:process(rst_n, clk, en)
	begin
		if(rst_n = '0') then
			mtick <= '0';
			counter <= 0;
		elsif(rising_edge(clk))	then
			mtick <= '0';  -- clear to 0 for one click no matter what 'en' is
				
			if(en = '1') then
				if( counter = COUNT_PER_MS*COUNT_DELAY-1) then
					counter <= 0;
					mtick <= '1';
				else
					counter <= counter +1;
				end if;
			end if;
		end if;		
	
	end process delay_pro;
	
	tick <= mtick;
	
end architecture;

	
