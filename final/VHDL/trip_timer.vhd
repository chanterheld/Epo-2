library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all_fnc.all;

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
				if(sub_counter >= 50000000) then		--elke seconde
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

	process(minutes_v, tens_v, seconds_v, hold)				-- next state logic
	begin
		if (hold = '1') then						-- timer hold=> next state gelijk aan current state
			n_minutes_v <= minutes_v;
			n_tens_v <= tens_v;
			n_seconds_v <= seconds_v;
		else
			if (to_integer(seconds_v) = 9) then			-- na elke 9de seconden tiende seconde plus 1 en secondes naar 0
				n_seconds_v <= (others =>  '0');
				if (to_integer(tens_v) = 5) then		-- na elke 5de tiende seconde minuten +1 en tiende naar 0
					n_tens_v <= (others =>  '0');
					if (to_integer(minutes_v) = 9) then	-- ook minuten op 9 => timer hold
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

		case to_integer(minutes_v) is			--register waardes naar bijbehorende 7 segment vectors
			when 0 =>
				minutes <= seg(zero);
			when 1 =>
				minutes <= seg(one);
			when 2 =>
				minutes <= seg(two);
			when 3 =>
				minutes <= seg(three);
			when 4 =>
				minutes <= seg(four);
			when 5 =>
				minutes <= seg(five);
			when 6 =>
				minutes <= seg(six);
			when 7 =>
				minutes <= seg(seven);
			when 8 =>
				minutes <= seg(eight);
			when 9 =>
				minutes <= seg(nine);
			when others =>
				minutes <= "10010001"; 
		end case;

		case to_integer(tens_v) is
			when 0 =>
				tens <= seg(zero);
			when 1 =>
				tens <= seg(one);
			when 2 =>
				tens <= seg(two);
			when 3 =>
				tens <= seg(three);
			when 4 =>
				tens <= seg(four);
			when 5 =>
				tens <= seg(five);
			when others =>
				tens <= "10010001";
		end case;

		case to_integer(seconds_v) is
			when 0 =>
				seconds <= seg(zero);
			when 1 =>
				seconds <= seg(one);
			when 2 =>
				seconds <= seg(two);
			when 3 =>
				seconds <= seg(three);
			when 4 =>
				seconds <= seg(four);
			when 5 =>
				seconds <= seg(five);
			when 6 =>
				seconds <= seg(six);
			when 7 =>
				seconds <= seg(seven);
			when 8 =>
  				seconds <= seg(eight);
			when 9 =>
				seconds <= seg(nine);
			when others =>
				seconds <= "10010001"; 
		end case;
	end process;

end architecture behav;

