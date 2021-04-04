-- test FIFO buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity fifo_tb is
end fifo_tb;


architecture tb_beh of fifo_tb is	 

constant FIFO_DEPTH: integer := 2; -- 2: 2 bits as address, eg, FIFO depth 4;

signal clk: std_logic := '0';
signal rst_n: std_logic;

signal wr, rd, full, empty: std_logic;
signal wdata, rdata: std_logic_vector(7 downto 0);
--signal waddr, raddr: integer range 0 to 4;

begin
	fifo_comp: entity work.fifo 
		generic map(
			WORD_BIT => 8,
			ADDR_BIT => FIFO_DEPTH
		)
		port map(
			rst_n => rst_n,
			clk => clk,
			wr => wr,
			rd => rd,
			w_data => wdata,
			r_data => rdata,
			full => full,
			empty => empty
		);
		
	rst_n <= '0', '1' after 10 ns;
	clk <= not clk after 5 ns;
	
	-- read/write FIFO 
	-- simulation: no sensitivity list, so this process always run, like signal is assigned in this process, 
	-- not the delta delay after end of this process  
	-- so wdata 0xAA 0xAB 0xAC 0xAD 0xAE --> 0xAA 0xAB 0xAC 0xAD 0xAE 
	wr_proc: process				 
	begin			   		
		rd <= '0';	-- if rd is not assigned, then rd is 'X', then op is not "10", instead it's "0X" in fifo
		wdata <= "10101010";				  
		-- test write and full signal
		for i in 0 to 2**FIFO_DEPTH +1 loop
			wr <= '0';
			wait for 5 ns;
			-- wait until full = '0';
			wdata <= wdata + 1;
			wr <= '1';
			wait for 8 ns; -- 10 ns, one period for write
			wr <= '0';
			wait for 5 ns;
		end loop;	
		
		wait for 20 ns;	 
		
		-- test read and empty signal after write, and test the read out result
		for i in 0 to 2**FIFO_DEPTH+2 loop
			rd <= '1';
			wait for 8 ns;
			rd <= '0';
			wait for 5 ns;
		end loop;

		
	end process wr_proc;		
		-- wait until full = '1'; -- is full now

	--rd_proc: process
	--begin
	--	for i in 0 to FIFO_DEPTH+1 loop
	--		rd <= '1';
	--		wait for 10 ns;
	--		rd <= '0';
	--		wait for 5 ns;
	--	end loop;
		
		-- wait until empty = '1';
		
		-- indicate end now
		-- wdata <= X"FF";
		-- rdata <= X"FF";
		-- wait;
		
	--end process rd_proc;
	

end architecture;
	