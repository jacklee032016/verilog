-- debouncer implemented with FSM

library ieee;
use ieee.std_logic_1164.all;   
use ieee.numeric_std.all;	-- for signed and unsigned ops

entity debouncer is
	generic (
		FREQ: integer := 100_000_000;  -- 100MHz
		N: integer := 19;		-- bits of counter
		TIME_LAPES: integer := 10; -- time duration in time, default 10ms
		TIME_BASE: integer := 1000 -- time unit; 1000: ms; 1_000_000: us
		); -- 19, 10ms;
	port(
		clk, rst_n: in std_logic;
		sw: in std_logic;
		db: out std_logic
	);
end debouncer;


architecture debouncer_fsm of debouncer is

signal counter_r, next_counter : unsigned (N downto 0); -- integer range 0 to N_COUNT :=0;
signal mclk: std_logic := '0';														

type STATE is (S_0, S_WAIT_1_0, S_WAIT_1_1, S_WAIT_1_2, S_1, S_WAIT_0_0, S_WAIT_0_1, S_WAIT_0_2);
signal state_r, state_next: STATE;										   
signal qdb_r, qdb_next: std_logic;

begin					 
	-- registers
	mtimer: process(clk, rst_n)
	begin
		if(rst_n = '0') then
			counter_r <= (others=> '0');
		elsif(rising_edge(clk)) then
			counter_r <= next_counter;
		end if;
	end process mtimer;		
	
	-- next state register
	-- important: can't use following:  there is a combinatorial feedback loop 
	-- next_counter <= next_counter +1;
	next_counter <= counter_r +1; -- although concurrent statement, but counter_r is only updated in process, only when ridge edge
	-- so next_counter is only updated new value when rising edge
	
	-- output logic
	-- error: concurrent statement, assign itself, so loop back of circuit
	-- xx <= not xx: only can be used in process, which sequential 	
	-- mmclk <= not mmclk when counter_r =0;	
	mclk <= '1' when counter_r=0 else
		'0';
		
	-- state register	
	process(mclk, rst_n)	 
	begin
		if(rst_n = '0') then
			state_r <= S_0;
			qdb_r <= '0';
		elsif (rising_edge(mclk)) then
			state_r <= state_next;
			qdb_r <= qdb_next;
		end if;
	end process;
	
	-- FSM: next state
	process(state_r, sw)
	begin
		state_next <= state_r;
		qdb_next <= qdb_r;
		
		case state_r is
			when S_0 =>    
				qdb_next <= '0';
				if(sw ='1') then
					state_next <= S_WAIT_1_0;
				end if;	
			
			when S_WAIT_1_0 =>
			if(sw = '1') then 
				state_next <= S_WAIT_1_1;
			else
				state_next <= S_0;
			end if;			
			
			when S_WAIT_1_1 =>
			if(sw = '1') then
				state_next <= S_WAIT_1_2;
			else 
				state_next <= S_0;
			end if;			
			
			when S_WAIT_1_2 =>
			if(sw = '1') then
				state_next <= S_1;
			else
				state_next <= S_0;
			end if;
			
			
			when S_1 => 
			qdb_next <= '1';
			if(sw = '0') then
				state_next <= S_WAIT_0_0;
			end if;
						
			when S_WAIT_0_0 =>
			if(sw = '0') then
				state_next <= S_WAIT_0_1;
			else
				state_next <= S_1;
			end if;			
			
			when S_WAIT_0_1 =>
			if(sw='0') then
				state_next <= S_WAIT_0_2;
			else
				state_next <= S_1;
			end if;			
			
			when S_WAIT_0_2 =>
			if( sw='0') then
				state_next <= S_0;
			else
				state_next <= S_1;
			end if;			
			
			when others=> null;		 
		end case;
			
			
	end process;
	
	db <= qdb_r; -- registered output
	
end architecture;


-- refer to https://www.digikey.com/eewiki/pages/viewpage.action?pageId=4980758
architecture logic of debouncer is
signal delay_ff_r: std_logic_vector (1 downto 0);
signal count_clear: std_logic;
begin												 
	process(clk, rst_n, sw)
		variable counter: integer range 0 to FREQ/TIME_BASE*TIME_LAPES:=0;	
	begin
		
		if(rst_n = '0') then
			delay_ff_r <= (others=> '0');
			db <= '0';
			counter := 0;
		elsif(rising_edge(clk))	 then
			delay_ff_r(0) <= sw;
			delay_ff_r(1) <= delay_ff_r(0);	 
			
			-- all these ops must be synchronized with clock
			if(count_clear ='1') then  -- clear count, then from beginning once sw changes
				counter := 0;
			elsif(counter < FREQ/TIME_BASE*TIME_LAPES)	 then	   -- FREQ/1000: 100_000 pulses in one ms; FREQ/1000/1000: 100 pulses in one us
				counter := counter +1;
			else	
				-- db <= delay_ff_r(0); 
				db <= delay_ff_r(1);
			end if;
			
		end if;
		
		
	end process;
	
	-- count_clear <= (not delay_ff_r(1)) and delay_ff_r(0);	   
	count_clear <= delay_ff_r(0) xor delay_ff_r(1);
	
end logic;

