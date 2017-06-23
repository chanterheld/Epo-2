library IEEE;
use IEEE.std_logic_1164.all;

entity d_FF is								--3 bit FF met synchrone reset
	port(	clk 	: in std_logic;
    		reset	: in std_logic;
    		D	: in std_logic_vector(2 downto 0);
    		Q	: out std_logic_vector(2 downto 0)
	);
end entity d_FF;

architecture behavioural of d_FF is
begin
	process (clk)
	begin
		if(rising_edge(clk)) then
			if (reset = '1') then 
				Q <= (others => '1');
			else
				Q <= D;
			end if;
		end if;
	end process;
end architecture behavioural;

library IEEE;
use IEEE.std_logic_1164.all;

entity d_FF_1 is							--1 bit FF met synchrone reset
	port(	clk 	: in std_logic;
    		reset	: in std_logic;
    		D	: in std_logic;
    		Q	: out std_logic
	);
end entity d_FF_1;

architecture behavioural of d_FF_1 is
begin
	process (clk)
	begin
		if(rising_edge(clk)) then
			if (reset = '1') then 
				Q <= '1';
			else
				Q <= D;
			end if;
		end if;
	end process;
end architecture behavioural;
