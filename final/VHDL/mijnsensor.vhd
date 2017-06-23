library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mine_deco is
	port(	clk	: in	std_logic;
		reset	: in	std_logic;
		sensor	: in	std_logic;
		mine	: out	std_logic
	);
end entity mine_deco;

architecture behav of mine_deco is
signal count, new_count, counted_ticks: unsigned(15 downto 0);
signal last_sensor_state: std_logic;

begin
	couting: process (clk)
	begin
		if (rising_edge (clk)) then
			if (reset = '1') then
				count <= (others =>  '0');
				counted_ticks <= (others => '0');
			elsif ((sensor = '1') and (last_sensor_state = '0')) then	--rising edge sinds laatste klok tick
				counted_ticks <= count;					--schrijft aantal klok tick in 1 periode(rising edge -> rising edge) naar variable
				count <= (others => '0');
			else
				count <= new_count;
			end if;
			last_sensor_state <= sensor;
		end if;
	end process;

	comparing: process(counted_ticks)
	constant critical_value: integer := 5650;
	begin
		if  counted_ticks >= critical_value then				--variable wordt getest tegenover grenswaarde
			mine <= '1';
		else
			mine <= '0';
		end if;
	end process;

	new_count <= count + 1;
end architecture behav;