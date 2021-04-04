library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_str is
	generic(DEPTH: integer := 16;
	WIDTH: integer := 8);
	port(rst_n, clk: in std_logic;
	addr: in std_logic_vector(3 downto 0);
	data: out std_logic_vector(WIDTH-1 downto 0));
end rom_str;


-- in block memory ??
architecture beh_str of rom_str is
type ROM is array(0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);

constant str_table: ROM := (
	"01000001",	 -- 0x41, A
	"01000010",	 -- 0x42, B
	"01000011",	 -- 0x43, C
	"01000100",	 -- 0x44, D
	
	"01000101",	 -- 0x45, E
	"01000110",	 -- 0x46, F
	"01000111",	 -- 0x47, G
	"01001000",	 -- 0x48, H	
	
	"01001001",	 -- 0x49, I
	"01001010",	 -- 0x4A, J
	"01001011",	 -- 0x4B, K
	"01001100",	 -- 0x4C, L
	
	"01001101",	 -- 0x4D, M
	"01001110",	 -- 0x4E, N
	"01001111",	 -- 0x4F, O
	"01010000"	 -- 0x50, P
);


begin
	read: process(rst_n, clk, addr)
	begin
		if(rst_n = '0') then
			data <= (others=> '0');
		elsif(rising_edge(clk))	then
			data <= str_table(to_integer(unsigned(addr)));
		end if;
		
	end process read;
end architecture;	 

-- synthesized as distributed ram by concurrent statement
architecture dram_concurrent of rom_str is
begin								
	data <= (others => '0') when rst_n = '0' else
		"00000000" when addr = "0000" else
		"00000001" when addr = "0001" else
		"00000010" when addr = "0010" else
		"00000100" when addr = "0011" else 
			
		"00001000" when addr = "0100" else
		"00010000" when addr = "0101" else
		"00100000" when addr = "0110" else
		"01000000" when addr = "0111" else
			
		"10000000" when addr = "1000" else
		"10000001" when addr = "1001" else
		"10000010" when addr = "1010" else
		"10000100" when addr = "1011" else
			
		"10001000" when addr = "1100" else
		"10010000" when addr = "1101" else
		"10100000" when addr = "1110" else
		"11000000" ;
	
end architecture;	

-- synthesized as distributed ram by sequential statement
architecture dram_sequen of rom_str is
begin			
	process(addr)
	begin
		case addr is
			when "0000" => data <= "00000000";
			when "0001" => data <= "10000000";
			when "0010" => data <= "01000000";
			when "0011" => data <= "00100000";
			when "0100" => data <= "00010000";
			when "0101" => data <= "00001000";
			when "0110" => data <= "00000100";
			when "0111" => data <= "00000010";
			when "1000" => data <= "00000001";
			when "1001" => data <= "10000001";
			when "1010" => data <= "01000001";
			when "1011" => data <= "00100001";
			when "1100" => data <= "00010001";
			when "1101" => data <= "00001001";
			when "1110" => data <= "00000101";
			when others => data <= "00000011";
		end case;
	end process;
	
	
end architecture;	

