-- Buffer register with flag flip-flop
-- used as interface buffer between UART and main system

library ieee;
use ieee.std_logic_1164.all;
entity buf_reg is
   port(
      clk, reset: in std_logic;
      clr_flag, set_flag: in std_logic; 
      din: in std_logic_vector(7 downto 0);
      dout: out std_logic_vector(7 downto 0);
      flag: out std_logic
   );
end buf_reg;

architecture arch of buf_reg is
   signal b_reg, b_next: std_logic_vector(7 downto 0); -- data register
   signal flag_reg, flag_next: std_logic; -- flag FF
begin
   -- FF & register
   process(clk,reset)
   begin
      if reset='1' then
         b_reg <= (others=>'0');
         flag_reg <= '0';
      elsif (clk'event and clk='1') then
         b_reg <= b_next;
         flag_reg <= flag_next;
      end if;
   end process;
   -- next-state logic
   process(b_reg, flag_reg, set_flag, clr_flag, din)
   begin
      b_next <= b_reg;
      flag_next <= flag_reg;
      if (set_flag='1') then 
         b_next <= din;
         flag_next <= '1'; -- data will be written into register
      elsif (clr_flag='1') then
         flag_next <= '0';
      end if;
   end process;
   -- output logic
   dout <= b_reg;
   flag <= flag_reg;
end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buf_reg_tx is
   port(
      clk, reset: in std_logic;
      clr_flag, set_flag: in std_logic; 
      din: in std_logic_vector(7 downto 0);
      dout: out std_logic_vector(7 downto 0);
      flag: out std_logic
   );
end buf_reg_tx;

architecture arch of buf_reg_tx is
	signal b_reg, b_next: std_logic_vector(7 downto 0); -- data register
	signal flag_reg, flag_next: std_logic; -- flag FF
	signal nos_reg, nos_next: unsigned(3 downto 0);
begin
   	-- FF & register
	process(clk,reset)
   	begin
      		if reset='1' then
         		b_reg <= (others=>'0');
         		flag_reg <= '0';
			nos_reg <= (others=>'0');
      		elsif (clk'event and clk='1') then
        		b_reg <= b_next;
         		flag_reg <= flag_next;
			nos_reg <= nos_next;
      		end if;
   	end process;
   	-- next-state logic
   	process(b_reg, flag_reg, nos_reg, set_flag, clr_flag, din)
   	begin
      		b_next <= b_reg;
      		flag_next <= flag_reg;
		nos_next <= nos_reg;
      		if (set_flag='1') then 
         		b_next <= din;
         		flag_next <= '1'; -- data will be written into register
			nos_next <= to_unsigned(4,4);
      		elsif (clr_flag='1') then
         		flag_next <= '0';
		elsif ((flag_reg = '0') and (to_integer(nos_reg) > 0)) then --if not sending and last message is send less then 5 times it sends it again;
			flag_next <= '1';
			nos_next <= nos_reg - 1;
      		end if;
   	end process;
   	-- output logic
   	dout <= b_reg;
   	flag <= flag_reg;
end arch;
