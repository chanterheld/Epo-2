library IEEE;
use IEEE.std_logic_1164.all;

package all_fnc is
type hex is ( bar, zero, one, two, three, four, five, six, seven, eight, nine, aa, bb, cc, dd, ee, ff);

FUNCTIOn seg (l:hex) RETURN std_logic_vector;
end all_fnc;

package body all_fnc is
type seg_table is ARRAY(hex) of std_logic_vector(7 downto 0);

constant conv_table: seg_table := (
"11111101",	-- -
"00000011",	-- 0
"11110011",	-- 1
"00100101",	-- 2
"00001101",	-- 3
"10011001",	-- 4
"01001001",	-- 5
"01000001",	-- 6
"00011111",	-- 7
"00000001",	-- 8
"00001001",	-- 9
"00010001",	-- A
"11000001",	-- B
"01100011",	-- C
"10000011",	-- D
"01100001",	-- E
"01110001");	-- F

FUNCTIOn seg (l:hex) RETURN std_logic_vector is
begin
 RETURN(conv_table(l));
end seg;

end all_fnc;