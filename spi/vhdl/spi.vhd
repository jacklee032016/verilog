
--
-- Basic design:
--   * Tranafering a bit in 2*T (where 2*T=1/data_rate)
--    * at 0: master shifts out data bit to MOSI  
--      * at T: master samples the incoming it from MISO 
--      * at 2*T: repeats for next bit 
--   * Trasferring a byte with cpha (SPI clock phase) = 0;
--      * starting transferring first bit immediately 
--      * repeats 8 times 
--   * Trasferring a byte with cpha (SPI clock phase) = 1;
--      * wait for T (i.e., 180-degree phase)
--      * transferng first bit 
--      * repeats 8 times 
--   * Generate spi clock (SCK) according to bit trnasfer with cpol=0
--      * 1st half: 0-T; 2nd half: T-2*T
--      * cpha=0: sck 1st half low; 2nd half high    
--      * cpha=1: sck 1st half high; 2nd half low    
--   * Generate spi clock (SCK) according to bit trnasfer with cpol=1
--      * invert sck with cpol=0
-- Note:
--   * cpol, cpha, dvsr cannot change during the operation;
--     Add additional registers if necessary
--   * SS (slave select) 
--      * not part of the design 
--      * to be added in top-level circuit 
--      * must be properly asserted/deasserted by top-level controller 
-- To do: reverse oreder


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SpiCtrl is
   port(
      clk, reset    : in  std_logic;
      din           : in  std_logic_vector(7 downto 0);
      dvsr          : in  std_logic_vector(15 downto 0); -- freq divider
      start         : in  std_logic;
      cpol, cpha    : in  std_logic;
      dout          : out std_logic_vector(7 downto 0);
      spi_done_tick : out std_logic;
      ready         : out std_logic; 
	  
	  -- spi
      sclk          : out std_logic;
      miso          : in  std_logic;
      mosi          : out std_logic
   );
end SpiCtrl;

architecture arch of SpiCtrl is
   type statetype is (S_IDLE, S_P0, S_P1);
   signal state_reg       : statetype;
   signal state_next      : statetype;
   
   signal p_clk           : std_logic;
   signal c_reg, c_next   : unsigned(15 downto 0);
   
   signal spi_clk_next    : std_logic;
   signal spi_clk_reg     : std_logic;
   
   signal n_reg, n_next   : unsigned(2 downto 0);
   
   signal si_reg, si_next : std_logic_vector(7 downto 0);
   signal so_reg, so_next : std_logic_vector(7 downto 0);
begin
   
	-- registers
   process(clk, reset)
   begin
      if reset = '1' then
         state_reg   <= S_IDLE;
         si_reg      <= (others => '0');
         so_reg      <= (others => '0');
         n_reg       <= (others => '0');
         c_reg       <= (others => '0');
         spi_clk_reg <= '0';
      elsif (clk'event and clk = '1') then
         state_reg   <= state_next;
         si_reg      <= si_next;
         so_reg      <= so_next;
         n_reg       <= n_next;
         c_reg       <= c_next;
         spi_clk_reg <= spi_clk_next;
      end if;
   end process;
   
   
   -- next-state logic and data path
   process(state_reg,si_reg,so_reg,n_reg,c_reg,din,dvsr,start,cpha,miso)  -- in signals in port
   begin
      state_next    <= state_reg;
      ready         <= '0';	-- ready is out signal in port; synthesized as wire here; also only update at clock
      spi_done_tick <= '0';
      si_next       <= si_reg;
      so_next       <= so_reg;
      n_next        <= n_reg;
      c_next        <= c_reg;
      case state_reg is
         when S_IDLE =>
            ready <= '1';
            if start = '1' then
               so_next    <= din;
               n_next     <= (others => '0');
               c_next     <= (others => '0');
               state_next <= S_P0;
            end if;
			
         when S_P0 =>
            if c_reg = unsigned(dvsr) then -- phase-0: first edge of sclk
               state_next <= S_P1;
			   
               si_next    <= si_reg(6 downto 0) & miso;	 -- input sampled at the rising edge 
               c_next     <= (others => '0');
            else
               c_next <= c_reg + 1;
            end if;
			
         when S_P1 =>
            if c_reg = unsigned(dvsr) then -- phase-1: second edge of sclk
               if n_reg = 7 then -- 8 bits in one byte
                  spi_done_tick <= '1';
                  state_next    <= S_IDLE;
               else
                  so_next    <= so_reg(6 downto 0) & '0'; -- output at the falling edge
                  state_next <= S_P0;
                  n_next     <= n_reg + 1;
                  c_next     <= (others => '0');
               end if;
            else
               c_next <= c_reg + 1;
            end if;
      end case;
   end process;
   
   
	-- lookahead output decoding			
	-- CPHA=0: data is in the first PCLK edge; CPHA=1: data is in the second PCLK edge
	p_clk <= '1' when ((state_next = S_P1 and cpha = '0') or (state_next = S_P0 and cpha = '1')) 
		else '0'; -- IDLE state or other 2 types 

	-- cpol=0: PCLK=0 when state is IDLE; cpol=1: PCLK=1 when state is IDLE
	spi_clk_next <= p_clk when (cpol = '0') else
		not p_clk;
	   
   -- output
   dout  <= si_reg;
   mosi  <= so_reg(7);
   sclk  <= spi_clk_reg;
end arch;

