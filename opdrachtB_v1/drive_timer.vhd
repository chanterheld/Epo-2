library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity drive_timer is
	port(	clk		: in	std_logic;
		reset		: in	std_logic;
		load		: in	std_logic;

		time_loaded	: in	std_logic_vector(11 downto 0);
		count_out	: out	std_logic_vector(11 downto 0)

	);
end entity drive_timer;

architecture behav of drive_timer is
signal count, new_count : unsigned (11 downto 0);
begin
	process(clk)
	variable sub_counter: integer range 0 to 50050 := 0;
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				sub_counter := 0;
				count <= (others =>  '0');
			elsif(load = '1') then
				sub_counter := 0;
				count <= unsigned(time_loaded);
			else
				if(sub_counter >= 50000) then			-- elke miliseconde
					sub_counter := 0;
					count <= new_count;
				else
					sub_counter := sub_counter + 1;
				end if;
			end if;
		end if;
	end process;

	process(count)
	begin
		if (count >= 4001) then
			new_count <= count;
		else
			new_count <= count + 1;
		end if;
	end process;

	count_out <= std_logic_vector(count);

end architecture behav;
