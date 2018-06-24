library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_validate is
	port(	clk		: in	std_logic;
		reset		: in	std_logic;
		data_in		: in	std_logic_vector(7 downto 0);
		flag_in		: in	std_logic;
		s_clk		: in	std_logic;

		data_out	: out	std_logic_vector(7 downto 0);
		set_dflag	: out	std_logic;
		instr_out	: out	std_logic_vector(7 downto 0);
		set_iflag	: out	std_logic;
		en_instr	: out	std_logic
	);
end entity data_validate;

architecture behav of data_validate is
type fsm_state is (	empty,
			one,
			two,
			three);

signal state, next_state: fsm_state;
signal all_instr_reg, all_instr_next: std_logic_vector(23 downto 0);
signal flag_in_n, flag_in_l: std_logic;
signal send_instr: std_logic;
signal s_reg, s_next: unsigned(11 downto 0);

begin
process (clk) is
variable send_instr_cnt: integer range 0 to 5:= 0;
begin
	if rising_edge(clk) then
		if reset = '1' then
			state <= empty;
			all_instr_reg <= (others => '0');
			s_reg <= (others => '0');
		else
			state <= next_state;
			all_instr_reg <= all_instr_next;
			s_reg <= s_next;
			flag_in_n <= flag_in;
			flag_in_l <= flag_in_n;

			if (send_instr_cnt > 0) then
				en_instr <= '1';
				if (send_instr_cnt > 1) then
					set_iflag <= '1';	
					send_instr_cnt := send_instr_cnt + 1;
				elsif (send_instr_cnt > 3) then 				
					send_instr_cnt := 0;				
				else
					send_instr_cnt := send_instr_cnt + 1;
				end if;
			else 
				set_iflag <= '0';
				en_instr <= '0';
				if(send_instr = '1') then
					send_instr_cnt := 1;
				else
					send_instr_cnt := 0;
				end if;
			end if;
		end if;
	end if;
end process;

process(state, all_instr_reg, flag_in_n, flag_in_l, data_in, s_reg, s_clk) is
begin
	all_instr_next <= all_instr_reg;
	s_next <= s_reg;
	send_instr <= '0';
	set_dflag <= '0';
	case state is
		when empty =>
			if ((flag_in_n = '1') and (flag_in_l = '0')) then
				next_state <= one;
				all_instr_next <= data_in & all_instr_reg(23 downto 8);
				s_next <= (others => '0');
			else
				next_state <= empty;
			end if;
		when one =>
			if ((flag_in_n = '1') and (flag_in_l = '0')) then
				next_state <= two;
				all_instr_next <= data_in & all_instr_reg(23 downto 8);
			else
				if(s_clk = '1') then
					s_next <= s_reg + 1;
				end if;
				next_state <= one;
			end if;
		when two =>
			if ((flag_in_n = '1') and (flag_in_l = '0')) then
				next_state <= three;
				all_instr_next <= data_in & all_instr_reg(23 downto 8);
			else
				if(s_clk = '1') then
					s_next <= s_reg + 1;
				end if;
				next_state <= two;
			end if;
		when three =>
			if ((all_instr_reg(7 downto 0) = all_instr_reg(23 downto 16)) and (all_instr_reg(7 downto 0) = all_instr_reg(15 downto 8))) then
				set_dflag <= '1';
				next_state <= empty;
			else
				all_instr_next <= (others => '0');
				s_next <= (others => '0');
				send_instr <= '1';
				next_state <= empty;
			end if;
	end case;

end process;

data_out <= all_instr_reg(7 downto 0);
instr_out <= "00000100";

end architecture behav;




