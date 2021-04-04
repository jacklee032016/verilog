library ieee;
use ieee.std_logic_1164.all;

entity SpiFlash_tb is
	port(
--		CLK	: in std_logic;
		BTN	: in std_logic_vector(4 downto 0);
		LED	: out std_logic_vector(7 downto 0)
	);
end SpiFlash_tb;


architecture tb_arch of SpiFlash_tb is
	signal CLK		: std_logic;
	signal reset	: std_logic;   
	signal wr, rd	: std_logic;
	signal	addr: std_logic_vector(31 downto 0);
	signal din, dout	: std_logic_vector(7 downto 0);
	signal fin			: std_logic;
	
	signal	spi_cs, spi_clk, spi_din, spi_dout: std_logic;
	
begin		
	-- reset <= BTN(0);
	
	spi_flash_comp: entity  work.SpiFlash
		port map
		(
			CLK		=> CLK,
			reset	=> reset,
			
			wr		=> wr,
			rd		=> rd,
			addr	=> addr,
			din		=> din,
			dout	=> dout,
		
			fin		=> fin,
	
			spi_cs	=> spi_cs,
			spi_clk	=> spi_clk,
			spi_din => spi_din,
			spi_dout	=> spi_dout
		);
	
--	BTN(0) = '1', '0'  after 55 ns;
	process is
	begin
		CLK <= '0'; wait for 5 ns;
		CLK <= '1'; wait for 5 ns;
	end process;

	process is
	begin	 
		spi_din <= '0'; -- will read "dummy" zeros;
		reset <= '0'; wait for 25 ns;
		reset <= '1'; wait for 25 ns;
		reset <= '0'; 
		rd <= '1';
		addr <= X"0055AA66";
		wait for 100 ns;	
		rd <= '0';
		wr <= '0';
		wait until fin = '1';
		
		-- reset <= '1'; wait for 25 ns;  
		-- reset <= '0'; wait for 500 ns;
		-- spi_din <= '1'; wait for 1335 ns;
		-- spi_din <= '0';
		wait;
	end process;
		
	
end tb_arch;
