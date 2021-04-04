-- FIFO with circular buffer


-- debug is_empty is not cleared after writing data: because rd is not assigned, it is 'X', not '0';


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

--use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all;

entity fifo is 
	generic(
	WORD_BIT: integer := 8;
	ADDR_BIT: integer := 4
	);				  
	port(
		rst_n, clk: in std_logic;
		wr: in std_logic;
		w_data: in std_logic_vector(WORD_BIT-1 downto 0);
		rd: in std_logic;
		r_data: out std_logic_vector(WORD_BIT-1 downto 0);
		full, empty: out std_logic
	);
end fifo;

architecture beh_fifo of fifo is						

subtype FIFO_WORD is std_logic_vector(WORD_BIT-1 downto 0);
type FIFO_BUF is array(0 to 2**ADDR_BIT-1) of FIFO_WORD;

signal buf: FIFO_BUF;
signal is_full_r, is_empty_r, is_full_next, is_empty_next: std_logic;

--- all use std_logic_vector
-- signal rd_index_r, wr_index_r, rd_index_next, wr_index_next : integer range 0 to DEPTH-1;
-- signal rd_index_succ, wr_index_succ: integer range 0 to DEPTH-1;   
signal rd_index_r, wr_index_r, rd_index_next, wr_index_next: std_logic_vector(ADDR_BIT-1 downto 0);
signal rd_index_succ, wr_index_succ: std_logic_vector(ADDR_BIT-1 downto 0);

signal ops: std_logic_vector(1 downto 0);

begin

	-- register file: input/output data, also synchronized with clock
	reg_file_proc: process(rst_n, clk)				   
	begin
		if(rst_n = '0') then
			buf <= (others=> (others=>'0'));
		elsif(rising_edge(clk)) then
			if(wr ='1' and is_full_r /= '1') then
				buf(to_integer(unsigned(wr_index_r)) ) <= w_data;
			end if;
		end if;	
	end process reg_file_proc;
	
	-- out of FIFO data
 	-- read at any time when rd='1' and is_empty_r = '0', not related to the rising edge of clock
	--r_data <= X"00"	when rd = '0' or is_empty_r = '1' else 
	--	buf(to_integer(unsigned(rd_index_r)));-- read from current location							  
	
	-- registered output, always happens at rising_edge of clock and keep on except address is changed	
	-- always has data output even when rd='0';
	r_data <= buf(to_integer(unsigned(rd_index_r))); 
	

	-- registered ops
	fifo_ctrl_proc: process(rst_n, clk)
	begin
		if(rst_n = '0') then
			is_full_r <= '0';
			is_empty_r <= '1';
			rd_index_r <= (others=>'0');							   			
			wr_index_r <= (others=>'0');							   
			
			-- buf <= (others=> X"00"); -- let it assigned in same process
		elsif(rising_edge(clk))	then					 
			is_full_r <= is_full_next;
			is_empty_r <= is_empty_next;
			
			rd_index_r <= rd_index_next;
			wr_index_r <= wr_index_next;
		end if;
	end process fifo_ctrl_proc;	 
	
	
	ops <= wr & rd;
	rd_index_succ <= std_logic_vector(unsigned(rd_index_r) + 1); -- these 2 signals reflect next position, so can check in process without using variables
	wr_index_succ <= std_logic_vector(unsigned(wr_index_r) + 1);
	
	-- how to keep this process or its update ops synchronized with clock
	-- update temp value of full, empty and read/write indx when rw op happens; 
	-- real update happens in other process which is synchronized with clock
	-- read/write ops 
	next_pos_proc: process(ops, wr_index_r, rd_index_r, is_full_r, is_empty_r)	 -- wr ,rd not synchronized with clock tick
	begin									 
		is_full_next <= is_full_r;
		is_empty_next <= is_empty_r;
		
		rd_index_next <= rd_index_r;
		wr_index_next <= wr_index_r;
	
		case ops is
			when "11" => -- read/write at the same time, in same clock
				rd_index_next <= rd_index_succ;
				wr_index_next <= rd_index_succ;
				
			when "01" => -- read happening at somewhere else
				if(is_empty_r /= '1') then -- success read
					is_full_next <= '0';
					
					if(rd_index_succ = wr_index_r) then
						is_empty_next <= '1';
					end if;
					rd_index_next <= rd_index_succ;
				end if;	
				
			when "10" => -- write happening at somewhere else
				if(is_full_r /= '1') then -- write happened
					is_empty_next <= '0';
				
					if(wr_index_succ = rd_index_r) then
						is_full_next <= '1';
					end if;						   
					
					wr_index_next <= wr_index_succ;
				end if;
				
			when others => null; -- "00" => null; -- no op;
				
		end case;	
		
	end process next_pos_proc;

	
full <= is_full_r;
empty <= is_empty_r;
	
end architecture;

	