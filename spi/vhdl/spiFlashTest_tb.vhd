library ieee;
use ieee.std_logic_1164.all;

entity SpiFlashTest_tb is
end SpiFlashTest_tb;


architecture tb_arch of SpiFlashTest_tb is
	signal	BTN		: std_logic_vector(4 downto 0);
	signal	LED		: std_logic_vector(7 downto 0);
	signal	CLK		: std_logic;

	signal	spi_cs, spi_clk, spi_din, spi_dout: std_logic; 
	-- signal	spi_wp_n, spi_hold_n	: std_logic;
	
begin		
	-- reset <= BTN(0);
	
	spi_flash_comp: entity  work.SpiFlashTest  
		generic map
		(
			DELAY_BITS	=> 2
		)
		port map
		(
			CLK		=> CLK,
			BTN		=> BTN,
			LED		=> LED,
		
			spi_cs	=> spi_cs,
			spi_clk	=> spi_clk,
			spi_din => spi_din,
			spi_dout	=> spi_dout,
		
			spi_wp_n	=> open,
			spi_hold_n	=> open
			
		);
	
	process is
	begin
		CLK <= '0'; wait for 5 ns;
		CLK <= '1'; wait for 5 ns;
	end process;

	process is
	begin	 
		BTN(0) <= '0'; wait for 25 ns;
		BTN(0) <= '1'; wait for 25 ns;
		BTN(0) <= '0';
		
		wait for 100 ns;	
		BTN(1) <= '0'; wait for 20 ns;
		BTN(1) <= '1'; wait for 20 ns;
		BTN(1) <= '0';
		
		-- reset <= '1'; wait for 25 ns;  
		-- reset <= '0'; wait for 500 ns;
		-- spi_din <= '1'; wait for 1335 ns;
		-- spi_din <= '0';
		wait;
	end process;
	
	-- fill data from flash
	process is
	begin
		spi_din <= '0'; -- will read "dummy" zeros;
		wait for 2725 ns;
		wait for 80 ns;
		spi_din <= '1';

		wait for 80 ns;
		spi_din <= '0';

		wait for 80 ns;
		spi_din <= '1';

		wait for 80 ns;
		spi_din <= '0';

		wait for 80 ns;
		spi_din <= '1';

		wait for 80 ns;
		spi_din <= '0';

	end process;
	
	
end tb_arch;
