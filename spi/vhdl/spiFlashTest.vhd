
-- test circuit of QSPI flash controller

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity SpiFlashTest is	 
	generic 
	(
		DELAY_BITS: integer range 2 to 23 :=	20
	);
	port
	(			
		-- system interface
		CLK	: in std_logic;
		BTN	: in std_logic_vector(4 downto 0);
		LED	: out std_logic_vector(7 downto 0);
		
		-- SPI Flash interface
		spi_cs : out std_logic;
		spi_clk : buffer std_logic;
		spi_din : in std_logic;
		spi_dout : out std_logic;
		
		spi_wp_n: out std_logic;
		spi_hold_n: out std_logic

	);
end SpiFlashTest;


architecture test_arch of SpiFlashTest is
--	signal CLK		: std_logic;
	signal reset	: std_logic;   
	signal wr, rd	: std_logic;
	signal addr_r, addr_n: std_logic_vector(31 downto 0);
	signal din, dout	: std_logic_vector(7 downto 0);
	signal fin			: std_logic;
	
	signal led_r, led_n: std_logic_vector(7 downto 0);
	signal debs: std_logic_vector(1 downto 0);
	
	type STATE is (S_IDLE, S_READ, S_DONE);
	signal state_r, state_n: STATE;
	
	
begin		

	deb_comp: entity work.debouncer
	    Generic map
		(				   
			DEBNC_CLOCKS	=> DELAY_BITS,
			PORT_WIDTH 		=> 2
		)
	    Port map
		(
			SIGNAL_I	=> BTN(1 downto 0),
			CLK_I 		=> CLK,
			SIGNAL_O	=> debs
		);

	reset <= debs(0);
		
	-- disable USPI/QSPI
	spi_wp_n <= '1';
	spi_hold_n <= '1';

	
	spi_flash_comp: entity  work.SpiFlash
		port map
		(
			CLK		=> CLK,
			reset	=> reset,
			
			wr		=> wr,
			rd		=> rd,
			addr	=> addr_r,
			din		=> din,
			dout	=> dout,
		
			fin		=> fin,
	
			spi_cs	=> spi_cs,
			spi_clk	=> spi_clk,
			spi_din => spi_din,
			spi_dout	=> spi_dout
		);
	
    iStartUp : STARTUPE2
        generic map (
            PROG_USR => "FALSE", -- Activate program event security feature. Requires encrypted bitstreams.
            SIM_CCLK_FREQ => 0.0 -- Set the Configuration Clock Frequency(ns) for simulation.
        )
    
        port map (
            CFGCLK => open,        -- 1-bit output: Configuration main clock output
            CFGMCLK => open,       -- 1-bit output: Configuration internal oscillator clock output
            EOS => open,    -- 1-bit output: Active high output signal indicating the End Of Startup.
            PREQ => open,          -- 1-bit output: PROGRAM request to fabric output
            CLK => CLK,            -- 1-bit input: User start-up clock input
            GSR => '0',            -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
            GTS => '0',            -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
            KEYCLEARB => '0',      -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
            PACK => '0',           -- 1-bit input: PROGRAM acknowledge input
            USRCCLKO => spi_clk,    -- 1-bit input: User CCLK input
            USRCCLKTS => '0',      -- 1-bit input: User CCLK 3-state enable input
            USRDONEO => '1',       -- 1-bit input: User DONE pin output control
            USRDONETS => '0'       -- 1-bit input: User DONE 3-state enable output
        );

	fsm_proc:process(CLK, reset)
	begin	 
		if(rising_edge(CLK)) then
			if(reset = '1') then
				state_r <= S_IDLE;
				led_r <= X"01";
				addr_r <= X"00000080";
			else
				state_r <= state_n;
				led_r <= led_n;	
				addr_r <= addr_n;
			end if;
		end if;		
	end process fsm_proc;

	next_state_proc: process(state_r, debs, fin )
	begin		
		-- default value to avoid registered
		state_n <= state_r;
		led_n <= led_r;	
		rd <= '0';
		wr <= '0';	
		addr_n <= addr_r;
		
		case state_r is
			when S_IDLE => 
				-- led_n <= (others=> '0');
				if(debs(1) = '1') then
					state_n <= S_READ;
					-- addr_n <= addr_r + 1; 
					rd <= '1';
					-- led_n <= "00000010";
				end if;	
			
			when S_READ =>
--				led_n <= "00000110";
				if(fin = '1') then
--					rd <= '0';
					state_n <= S_DONE;
					-- led_n <= dout;
--					led_n <= "00001110";
					rd <= '0';
				end if;	
			
			when S_DONE => 	  
				led_n <= dout;
				-- led_n(7) <= '1';
				state_n <= S_IDLE;
			
			when others=>
				null;
		end case;
		
	end process next_state_proc;

	LED <= led_r;
	
end test_arch;
