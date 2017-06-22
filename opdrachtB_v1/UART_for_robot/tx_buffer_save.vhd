-- Buffer register with flag flip-flop
-- used as interface buffer between UART and main system

library ieee;
use ieee.std_logic_1164.all;

entity txb_save is
	port(	clk		: in	std_logic;
		reset		: in	std_logic;
      		clr_flag	: in	std_logic;
		set_flag	: in	std_logic;
		set_flag_e	: in	std_logic;
      		ena_e		: in	std_logic; 
      		din		: in	std_logic_vector(7 downto 0);
      		din_e		: in	std_logic_vector(7 downto 0);
      		dout		: out	std_logic_vector(7 downto 0);
      		flag		: out	std_logic
	);
end txb_save;

architecture arch of txb_save is
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
	process(b_reg, flag_reg, set_flag, clr_flag, din, set_flag_e, din_e, ena_e)
   	begin
		b_next <= b_reg;
		flag_next <= flag_reg;
		if (ena_e = '1') then
			if (set_flag_e='1') then 
				b_next <= din_e;
				flag_next <= '1'; -- data will be written into register
			elsif (clr_flag='1') then
				flag_next <= '0';
			end if;
		else
			if (set_flag='1') then 
				b_next <= din;
				flag_next <= '1'; -- data will be written into register
			elsif (clr_flag='1') then
				flag_next <= '0';
			end if;
		end if;
	end process;
   -- output logic
   dout <= b_reg;
   flag <= flag_reg;
end arch;
