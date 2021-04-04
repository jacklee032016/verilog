--
-- CPHA(Clock PHAse): 
--                   0: send data in phase 0, ie. the first edge of clock cycle
--                   1: send data in phase 1, ie. the second edge of clock cycle
-- CPOL(Clock POLarity): 
--                   0: PCLK is low when CS=0, ie. PCLK is low when idle
--                   1: PCLK is high when CS=0, ie. PCLK is high when idle
-- Normally slave is 00 or 11; SPI Flash and OLED all are "11"


library ieee;
use ieee.std_logic_1164.all;


entity SpiFlash is
	port
	( 
		clk, reset: in std_logic;
		wr			: in std_logic;
		rd			: in std_logic;
		addr		: in std_logic_vector(31 downto 0);
		din			: in std_logic_vector(7 downto 0);
		dout		: out std_logic_vector(7 downto 0);										
		
		fin			: out std_logic;
	
		spi_cs		: out std_logic;
		spi_clk		: out std_logic;
		spi_din		: in std_logic;
		spi_dout	: out std_logic
	);
end SpiFlash;	


architecture rtl_arc of SpiFlash is

-- FLASH commands
constant NOP			: std_logic_vector (7 downto 0) := x"FF";  -- no cmd to execute
constant WR_EN			: std_logic_vector (7 downto 0) := x"06";  -- write enable
constant WR_DI			: std_logic_vector (7 downto 0) := x"04";  -- write disable
constant RD_SR			: std_logic_vector (7 downto 0) := x"05";  -- read status reg
constant WR_SR			: std_logic_vector (7 downto 0) := x"01";  -- write stat. reg	 

constant RD_CMD			: std_logic_vector (7 downto 0) := x"03";  -- read data
constant FAST_RD		: std_logic_vector (7 downto 0) := x"0B";  -- fast read data
constant PAGE_PRO		:   std_logic_vector (7 downto 0) := x"02";  -- page program
constant SEC_ERASE		:   std_logic_vector (7 downto 0) := x"D8";  -- sector erase
constant BLOCK_ERASE	:   std_logic_vector (7 downto 0) := x"C7";  -- bulk erase
constant DEEP_DOWN		:   std_logic_vector (7 downto 0) := x"B9";  -- deep power down
constant READ_SIG		:  std_logic_vector (7 downto 0) := x"AB";  -- read signature

	type STATE	is (
		S_IDLE, 
		S_CMD, 
		S_WAIT_CMD, 
		S_ADDR_4, S_WAIT_ADDR4,
		S_ADDR_H, S_WAIT_ADDR_H,
		S_ADDR_M, S_WAIT_ADDR_M,
		S_ADDR_L, S_WAIT_ADDR_L,
--		S_ADDR_WAIT, 
		S_READ, 
		S_DONE
	);
	signal state_r, state_n: STATE;
	signal cs_n_r, cs_n_n: std_logic;
	
	signal spi_start: std_logic;
	signal spi_done: std_logic;
	signal spi_in_data, spi_out_data : std_logic_vector(7 downto 0);		
	
	signal dvsr  : std_logic_vector(15 downto 0) := X"0003"; -- 25MHz spi clock	   
	
	signal addr_r, addr_n	: std_logic_vector(31 downto 0); 
	
	
begin
	spi_ctl: entity work.SpiCtrl
		port map
		(
			clk				=> clk,
			reset			=> reset,
			din     		=> spi_in_data,
			dvsr    		=> dvsr,
			start			=> spi_start,
			
			cpol			=> '0',
			cpha			=> '0',
			dout    		=> spi_out_data,
			spi_done_tick	=> spi_done,
			ready         	=> open,
			
			-- spi
			sclk          	=> spi_clk,
			miso          	=> spi_din,
			mosi          	=> spi_dout
		);	   
		
		
	fsm_proc: process(clk, reset)	
	begin	  
		if(rising_edge(clk)) then
			if(reset = '1') then
				state_r <= S_IDLE;
				cs_n_r <= '1';
			else  
				state_r <= state_n;
				cs_n_r <= cs_n_n;
			end if;
		end if;	
	end process fsm_proc;


	-- next state
	next_state_proc: process(state_r, rd, wr, spi_done )
	begin
			state_n <= state_r;
			
			case state_r is
				when S_IDLE =>
					if(rd = '1') then 
						state_n <= S_CMD;
					end if;
				
				when S_CMD =>
					if(spi_done = '1') then
						state_n <= S_WAIT_CMD;
					end if;
				
				when S_WAIT_CMD =>
					state_n <= S_ADDR_H;
				
				when S_ADDR_4 => 
				
				when S_ADDR_H => 
					if(spi_done = '1') then
						state_n <= S_WAIT_ADDR_H;
					end if;						  
				
				when S_WAIT_ADDR_H =>
					state_n <= S_ADDR_M;
				
				when S_ADDR_M => 
					if(spi_done = '1') then
						state_n <= S_WAIT_ADDR_M;
					end if;
				
				when S_WAIT_ADDR_M =>
					state_n <= S_ADDR_L;
				
				when S_ADDR_L => 
					if(spi_done = '1') then -- read data
						state_n <= S_WAIT_ADDR_L;
					end if;
				
				when S_WAIT_ADDR_L =>
					state_n <= S_READ;
				
--				when S_ADDR_WAIT => 	  
--					state_n <= S_READ; 
					
				when S_READ => 
					if(spi_done = '1') then -- wait data ready and read it
						state_n <= S_DONE;
					end if;	
				
				when S_DONE => 
					if(rd = '0' and wr='0') then
						state_n <= S_IDLE;
					end if;
				
				when others =>
					null;
			end case;	
	end process next_state_proc;
	
	
	-- operations in different states
	ops_in_state_proc: process(state_r, addr_r )
	begin
		--if(rising_edge(clk)) then
			
			cs_n_n <= cs_n_r;
			
			case state_r is
				when S_IDLE =>
					cs_n_n <= '1';
				
				when S_CMD =>
					cs_n_n <= '0';
					spi_start <= '1';
					spi_in_data <= RD_CMD;
				
				-- when S_WAIT_CMD =>
				--	spi_start <= '0';
				--	spi_in_data <= addr_r(23 downto 16);
				
				when S_ADDR_4 => 
				
				when S_ADDR_H => 
					spi_start <= '1';
					spi_in_data <= addr_r(23 downto 16);
				
				when S_ADDR_M => 
					spi_start <= '1';
					spi_in_data <= addr_r(15 downto 8);
				
				when S_ADDR_L => 
					spi_start <= '1';
					spi_in_data <= addr_r(7 downto 0);
				
--				when S_ADDR_WAIT => 	  
--					null;
				
				when S_READ => 
					spi_start <= '1';	-- start read
				
				when S_DONE => 
					spi_start <= '0';	-- stop spi controller
					cs_n_n <= '1';

				
				when others =>
				null;
			end case;	
			
		--end if;				
	end process ops_in_state_proc;
	
	-- register the addr
	addr_n <= addr;	
	
	process(clk, reset)
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				addr_r <= (others => '0');
			else
				addr_r <= addr_n;
			end if;			
		end if;
	end process;


--	process(clk, reset)
--	begin
--		if(rising_edge(clk)) then
--			if(reset = '1') then
--				dout <= (others => '1');
--			else
--				dout <= spi_out_data;
--			end if;			
--		end if;
--	end process;
	
-- output 		   

dout <= spi_out_data;

fin <= '1' when state_r = S_DONE else
	'0';
	
spi_cs <= cs_n_r;
	
end rtl_arc;
