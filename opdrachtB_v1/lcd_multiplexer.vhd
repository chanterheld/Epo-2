library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity multiplexer is
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
		lcd_select	: in	std_logic;

		seg_1		: in	std_logic_vector(7 downto 0);
		seg_2		: in	std_logic_vector(7 downto 0);
		seg_3		: in	std_logic_vector(7 downto 0);
		seg_4		: in	std_logic_vector(7 downto 0);

		seg_5		: in	std_logic_vector(7 downto 0);
		seg_7		: in	std_logic_vector(7 downto 0);
		seg_8		: in	std_logic_vector(7 downto 0);

		mine		: in	std_logic;

		seg		: out 	std_logic_vector(7 downto 0);
		an		: out	std_logic_vector(3 downto 0)
	);
end entity multiplexer;

architecture behav of multiplexer is

type lcd_state is (	state_1,
			state_2,
			state_3,
			state_4);
signal state: lcd_state;
signal sseg_1, sseg_2, sseg_3, sseg_4: std_logic_vector(7 downto 0);

begin

process (seg_1, seg_2, seg_3, seg_4, seg_5, seg_7, seg_8, lcd_select)
begin
	if (lcd_select = '1') then
		sseg_1 <= seg_5;
		sseg_2 <= "11111110";
		sseg_3 <= seg_7;
		sseg_4 <= seg_8;
	else
		sseg_1 <= seg_1;
		sseg_2 <= seg_2;
		sseg_3 <= seg_3;
		sseg_4 <= seg_4;
	end if;
end process;

process(clk)
variable counter: integer := 0;
begin	
	if(rising_edge(clk)) then
		if(reset = '1') then
			an <= "1111";
			counter := 0;
		else
			an <= "1111";
			case state is
				when state_1 =>
					seg <= sseg_1(7 downto 1) & not(mine);
					an(3) <= '0';
					if(counter > 250000) then
						state <= state_2;
						counter := 0;
					else
						counter := counter + 1;
					end if;
				when state_2 =>
					seg <= sseg_2(7 downto 1)& not(mine);
					an(2) <= '0';
					if(counter > 250000) then
						state <= state_3;
						counter := 0;
					else
						counter := counter + 1;
					end if;
				when state_3 =>
					seg <= sseg_3(7 downto 1) & not(mine);
					an(1) <= '0';
					if(counter > 250000) then
						state <= state_4;
						counter := 0;
					else
						counter := counter + 1;
					end if;
				when state_4 =>
					seg<= sseg_4(7 downto 1) & not(mine);
					an(0) <= '0';
					if(counter > 250000) then
						state <= state_1;
						counter := 0;
					else
						counter := counter + 1;
					end if;
			end case;
		end if;
	end if;	
end process;

end architecture behav;
