library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity lijnvolger_tb is
end entity lijnvolger_tb;

architecture structural of lijnvolger_tb is

component FPGA is
	port (	clk		: in	std_logic;
		reset		: in	std_logic;

		rx		: in	std_logic; --data out from arduino
		tx		: out 	std_logic; --data in to arduino

		sensor_l_in	: in	std_logic;
		sensor_m_in	: in	std_logic;
		sensor_r_in	: in	std_logic;

		pwm_l		: out	std_logic;
		pwm_r		: out	std_logic
		
	);
end component FPGA;

signal clk, reset, pwm_l, pwm_r : std_logic;
signal sensors: std_logic_vector(2 downto 0);

begin
clk 	<= 	'1' after 0 ns,
         	'0' after 10 ns when clk /= '0' else '1' after 10 ns;

reset	<= 	'1' after 0 ns,
            	'0'  after 40 ms; 

sensors <= 	"111" after 0 ns,
		"110" after 45 ms,
		"100" after 85 ms,
		"101" after 105 ms,
		"001" after 125 ms,
		"011" after 145 ms,
		"111" after 165 ms,
		"101" after 185 ms,
		"100" after 205 ms,
		"110" after 225 ms,
		"111" after 245 ms,
		"101" after 265 ms,
		"111" after 285 ms;

L1: FPGA 	port map(	clk		=> clk,
				reset		=> reset,

				sensor_l_in	=> sensors(2),
				sensor_m_in	=> sensors(1),
				sensor_r_in	=> sensors(0),

				pwm_l		=> pwm_l,
				pwm_r		=> pwm_r
				
		);

end architecture structural;
