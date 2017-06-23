library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity inputbuffer is										--3 bit buffer
	port (	clk		: in	std_logic;
		reset		: in	std_logic;

		sensor_l_in	: in	std_logic;	--from "sensors"
		sensor_m_in	: in	std_logic;
		sensor_r_in	: in	std_logic;

		sensors_out		: out	std_logic_vector(2 downto 0) --to controller
	);
end entity inputbuffer;


architecture structural of inputbuffer is
  
component d_FF is
	port(	clk 	: in std_logic;
    		reset	: in std_logic;
    		D	: in std_logic_vector(2 downto 0);
    		Q	: out std_logic_vector(2 downto 0)
	);
end component d_FF;

signal sensors_in, sensors_thru : std_logic_vector(2 downto 0);

begin
sensors_in <= sensor_l_in & sensor_m_in & sensor_r_in;
  
FF1: 	d_FF 	port map(	clk 	=> clk,
				reset 	=> reset,
				D 	=> sensors_in,
				Q	=> sensors_thru
		);

FF2:	d_FF	port map(	clk 	=> clk,
				reset 	=> reset,
				D 	=> sensors_thru,
				Q	=> sensors_out
		);


            
  end architecture structural;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity inputbuffer_mine is						--1 bit buffer
	port (	clk		: in	std_logic;
		reset		: in	std_logic;
		buf_in		: in	std_logic;
		buf_out		: out	std_logic
	);
end entity inputbuffer_mine;


architecture structural of inputbuffer_mine is
  
component d_FF_1 is
	port(	clk 	: in std_logic;
    		reset	: in std_logic;
    		D	: in std_logic;
    		Q	: out std_logic
	);
end component d_FF_1;

signal buf_thru : std_logic;

begin
  
FF1: 	d_FF_1 	port map(	clk 	=> clk,
				reset 	=> reset,
				D 	=> buf_in,
				Q	=> buf_thru
		);

FF2:	d_FF_1	port map(	clk 	=> clk,
				reset 	=> reset,
				D 	=> buf_thru,
				Q	=> buf_out
		);
            
  end architecture structural;