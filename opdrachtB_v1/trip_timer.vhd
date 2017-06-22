library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trip_timer is
	port(	clk		: in	std_logic;
		reset		: in	std_logic;
		hold		: in	std_logic;

		minutes		: out	std_logic_vector(7 downto 0);
		tens		: out	std_logic_vector(7 downto 0);
		seconds		: out	std_logic_vector(7 downto 0)
	);
end entity trip_timer;

architecture behav of trip_timer is
signal minutes_v, n_minutes_v, seconds_v, n_seconds_v: unsigned(3 downto 0);
signal tens_v, n_tens_v: unsigned(2 downto 0);
begin
	process(clk)
	variable sub_counter: integer range 0 to 50000001 := 0;
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				sub_counter := 0;
				minutes_v <= (others =>  '0');
				tens_v <= (others =>  '0');
				seconds_v <= (others =>  '0');
			else
				if(sub_counter >= 50000000) then
					sub_counter := 1;
					minutes_v <= n_minutes_v;
					tens_v <= n_tens_v;
					seconds_v <= n_seconds_v;
				else
					sub_counter := sub_counter + 1;
				end if;
			end if;
		end if;
	end process;

	process(minutes_v, tens_v, seconds_v, hold)
	begin
		if (hold = '1') then
			n_minutes_v <= minutes_v;
			n_tens_v <= tens_v;
			n_seconds_v <= seconds_v;
		else
			if (to_integer(seconds_v) = 9) then
				n_seconds_v <= (others =>  '0');
				if (to_integer(tens_v) = 5) then
					n_tens_v <= (others =>  '0');
					if (to_integer(minutes_v) = 9) then
						n_minutes_v <= minutes_v;
						n_tens_v <= tens_v;
						n_seconds_v <= seconds_v;
					else
						n_minutes_v <= minutes_v + 1;
					end if;
				else
					n_minutes_v <= minutes_v;
					n_tens_v <= tens_v + 1;
				end if;
			else
				n_minutes_v <= minutes_v;
				n_tens_v <= tens_v;
				n_seconds_v <= seconds_v + 1;
			end if;
		end if;

		case to_integer(minutes_v) is
			when 0 =>
				minutes <= "00000011";
			when 1 =>
				minutes <= "10011111";
			when 2 =>
				minutes <= "00100101";
			when 3 =>
				minutes <= "00001101";
			when 4 =>
				minutes <= "10011001";
			when 5 =>
				minutes <= "01001001";
			when 6 =>
				minutes <= "01000001";
			when 7 =>
				minutes <= "00011111";
			when 8 =>
				minutes <= "00000001";
			when 9 =>
				minutes <= "00011001";
			when others =>
				minutes <= "10010001"; 
		end case;

		case to_integer(tens_v) is
			when 0 =>
				tens <= "00000011";
			when 1 =>
				tens <= "10011111";
			when 2 =>
				tens <= "00100101";
			when 3 =>
				tens <= "00001101";
			when 4 =>
				tens <= "10011001";
			when 5 =>
				tens <= "01001001";
			when others =>
				tens <= "10010001";
		end case;

		case to_integer(seconds_v) is
			when 0 =>
				seconds <= "00000011";
			when 1 =>
				seconds <= "10011111";
			when 2 =>
				seconds <= "00100101";
			when 3 =>
				seconds <= "00001101";
			when 4 =>
				seconds <= "10011001";
			when 5 =>
				seconds <= "01001001";
			when 6 =>
				seconds <= "01000001";
			when 7 =>
				seconds <= "00011111";
			when 8 =>
  				seconds <= "00000001";
			when 9 =>
				seconds <= "00011001";
			when others =>
				seconds <= "10010001"; 
		end case;
	end process;

end architecture behav;

