LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity motorcontrol is
	port (	clk		: in	std_logic;
		reset		: in	std_logic; 	--from controller
		direction	: in	std_logic;
		count_in	: in	std_logic_vector (19 downto 0);	--from timebase

		pwm		: out	std_logic	--to "servo L/R"
	);
end entity motorcontrol;

architecture behavioural of motorcontrol is

	type	motor_controller_state is (	pulse_low,
						pulse_high,
						rest);
	signal state, next_state : motor_controller_state;

begin
	process (clk)
	begin
		if(rising_edge(clk)) then
			if (reset = '1') then
				state <= pulse_low;
			else
				state <= next_state;
			end if;
		end if;
	end process;

	process(state, count_in, direction)
	begin
	next_state <= state;
		case state is
			when pulse_low =>				--na reset
				pwm <= '0';
				if(unsigned(count_in) <= 5) then
					next_state <= pulse_high;
				end if;

			when pulse_high =>
				pwm <= '1';
				if (direction = '0') then		--naar low afhankelijk van richting en lengte puls
					if(unsigned(count_in) > 50000) then
						next_state <= rest;
					end if;
				else
					if(unsigned(count_in) > 100000) then
						next_state <= rest;
					end if;
				
				end if;

			when rest =>
				pwm <= '0';
		end case;
	end process;

end architecture behavioural;




