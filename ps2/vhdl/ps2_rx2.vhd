library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	

entity ps2_rx2 is
   port (
      clk, rst_n: in  std_logic;
      ps2d, ps2clk: in  std_logic;  -- key data, key clock
      ps2en: in std_logic;
      dready: out  std_logic;
      dout: out std_logic_vector(7 downto 0)
--	  ;  fall: out std_logic

	  );
end ps2_rx2;

architecture arch of ps2_rx2 is
   type statetype is (idle, dps, load);
   signal state_reg, state_next: statetype;
   signal filter_reg, filter_next:
          std_logic_vector(7 downto 0);
   signal f_ps2c_reg,f_ps2c_next: std_logic;
   signal b_reg, b_next: std_logic_vector(10 downto 0);
   signal n_reg,n_next: unsigned(3 downto 0);
   signal fall_edge: std_logic;
begin
   --=================================================
   -- filter and falling edge tick generation for ps2c
   --=================================================
   process (clk, rst_n)
   begin
      if rst_n ='0' then
         filter_reg <= (others=>'0');
         f_ps2c_reg <= '0';
      elsif (clk'event and clk='1') then
         filter_reg <= filter_next;
         f_ps2c_reg <= f_ps2c_next;
      end if;
   end process;

   filter_next <= ps2clk & filter_reg(7 downto 1);
   f_ps2c_next <= '1' when filter_reg="11111111" else
                  '0' when filter_reg="00000000" else
                  f_ps2c_reg;
   fall_edge <= f_ps2c_reg and (not f_ps2c_next);
--   fall <= fall_edge;

   --=================================================
   -- fsmd to extract the 8-bit data
   --=================================================
   -- registers
   process (clk, rst_n)
   begin
      if rst_n='0' then
         state_reg <= idle;
         n_reg  <= (others=>'0');
         b_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
         n_reg <= n_next;
         b_reg <= b_next;
      end if;
   end process;
   -- next-state logic
   process(state_reg,n_reg,b_reg,fall_edge, ps2en, ps2d)
   begin
      dready <='0';
      state_next <= state_reg;
      n_next <= n_reg;
      b_next <= b_reg;
      case state_reg is
         when idle =>
            if fall_edge='1' and ps2en='1' then
               -- shift in start bit
               b_next <= ps2d & b_reg(10 downto 1);
               n_next <= "1001";
               state_next <= dps;
            end if;
         when dps =>  -- 8 data + 1 pairty + 1 stop
            if fall_edge='1' then
            b_next <= ps2d & b_reg(10 downto 1);
               if n_reg = 0 then
                   state_next <=load;
               else
                   n_next <= n_reg - 1;
               end if;
            end if;
         when load =>
            -- 1 extra clock to complete the last shift
            state_next <= idle;
            dready <='1';
      end case;
   end process;
   -- output
   dout <= b_reg(8 downto 1); -- data bits
end arch;