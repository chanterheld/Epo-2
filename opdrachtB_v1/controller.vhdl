     library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.all_fnc.all;

entity controller is
	port (	clk			: in	std_logic;
		reset			: in	std_logic;

		sensors			: in	std_logic_vector(2 downto 0);	--from inputbuffer

		instr_in		: in	std_logic_vector(7 downto 0);
		instr_rdy		: in	std_logic;
		clr_instr		: out	std_logic;

		instr_out		: out 	std_logic_vector(7 downto 0);
		send_instr		: out 	std_logic;

		count_in		: in	std_logic_vector (19 downto 0);	--from/to timebase
		count_reset		: out	std_logic;

		motor_l_reset		: out	std_logic;	--to motorcontrollerL
		motor_l_direction	: out	std_logic;

		motor_r_reset		: out	std_logic;	--to motorcontrollerR
		motor_r_direction	: out	std_logic;

		drive_timer_reset_1	: out 	std_logic;
		drive_timer_load_1	: out	std_logic;
		drive_timer_ttl_1	: out	std_logic_vector(11 downto 0);
		drive_timer_cnt_1	: in 	std_logic_vector(11 downto 0);

		drive_timer_reset_2	: out 	std_logic;
		drive_timer_load_2	: out	std_logic;
		drive_timer_ttl_2	: out	std_logic_vector(11 downto 0);
		drive_timer_cnt_2	: in 	std_logic_vector(11 downto 0);

		mine			: in	std_logic;

		seg_1			: out	std_logic_vector(7 downto 0);
		seg_2			: out	std_logic_vector(7 downto 0);
		seg_3			: out	std_logic_vector(7 downto 0);
		seg_4			: out	std_logic_vector(7 downto 0);

		reset_trip_timer	: out	std_logic;
		hold_trip_timer		: out	std_logic;
		lcd_select		: out	std_logic
		--timer_lcd		: in	std_logic_vector(1 downto 0)
	);
end entity controller;

architecture behavioural of controller is

	type motor_controller_state is(	reset_state,		-- --
					wait_for_instr_1,	-- -1
					wait_for_instr_2,	-- -2
					gestopt,		-- -F	

					first_part,		-- 00
					third_part,		-- 05
					vooruit_scherp,		-- 0A
					vooruit_chk,		-- 0F

					achteruit,		-- 10		
					van_naar_cp,		-- 15

					linksaf,		-- 20
					linksaf_pt2,		-- 25
					linksaf_pt3,		-- 2A
					linksaf_pt4,		-- 2F

					rechtsaf,		-- 30
					rechtsaf_pt2,		-- 35
					rechtsaf_pt3,		-- 3A
					rechtsaf_pt4,		-- 3F

					draai_linksom,		-- 40
					draai_linksom_pt2,	-- 45

					draai_rechtsom,		-- 50
					draai_rechtsom_pt2,	-- 55

					omdraaien,		-- 60
					omdraaien_pt2);		-- 65

	type message is(	dont_care,
				instr_used,
				mijn,
				geen_mijn,
				error);

	
	type motor_status is(	vooruit,
				bocht_lv,
				bocht_rv,
				draai_l,
				draai_r,
				gestopt,
				achteruit); 



signal state, next_state: motor_controller_state;
signal motor_l_hreset, motor_r_hreset: std_logic;
signal send_instr_next, clr_instr_next: std_logic;
signal instr_next: std_logic_vector(7 downto 0);
signal drive_time_reg, drive_time_next: unsigned(11 downto 0):= (others => '1');

signal sseg_1: std_logic_vector(7 downto 0) := (others => '1');
signal sseg_2: std_logic_vector(7 downto 0) := (others => '1');
signal sseg_3: std_logic_vector(7 downto 0) := (others => '1');
signal sseg_4: std_logic_vector(7 downto 0) := (others => '1');

attribute clock_signal : string;
attribute clock_signal of motor_l_direction : signal is "yes";
attribute clock_signal of motor_r_direction : signal is "yes";

signal rechtdoor_c, linksom_c, rechtsom_c, achteruit_c, afsnijden_c, one_8ty_c, instr, mine_c, cp_c : boolean;

begin	
	--Functie bepaalt boolean waardes aan te hand van instructie.
	--Voordeel is het makkelijk veranderen van plaats en betekenis van instructie
	instruction_decoder: process(instr_rdy, instr_in, mine)
	begin
		instr <= instr_rdy = '1';
		achteruit_c <= instr_in(7) = '1';
		rechtdoor_c <= instr_in(6 downto 5) = "00";
		linksom_c <= instr_in(6 downto 5) = "01";
		rechtsom_c <= instr_in(6 downto 5) = "10";
		one_8ty_c <= instr_in(6 downto 5) = "11";
		afsnijden_c <= instr_in(4) = '1';
		cp_c <= instr_in(3) = '1';
		mine_c <= mine = '1';
	end process;

	update_state: process (clk, reset)
	variable send_instr_cnt: integer range 0 to 3:= 0;
	begin
		if(rising_edge(clk)) then
			if (reset = '1') then
				count_reset <= '1';
				state <= reset_state;
	
				motor_r_reset <= '1';
				motor_l_reset <= '1';

				clr_instr <= '0';
				send_instr <= '0';	
			else
				if(unsigned(count_in) > 1000000) then
					count_reset 	<= '1';
					motor_l_reset 	<= '1';
					motor_r_reset 	<= '1';
				else
					count_reset 	<= '0';					
					motor_r_reset 	<= motor_r_hreset;
					motor_l_reset 	<= motor_l_hreset;
				end if;	

				if (send_instr_cnt > 0) then
					send_instr <= '1';
					if (send_instr_cnt > 2) then
						send_instr_cnt := 0;						
					else
						send_instr_cnt := send_instr_cnt + 1;
					end if;
				else 
					send_instr <= '0';
					instr_out <= instr_next;

					if(send_instr_next = '1') then
						send_instr_cnt := 1;
					else
						send_instr_cnt := 0;
					end if;
				end if;
				clr_instr <= clr_instr_next;
				state <= next_state;
				drive_time_reg <= drive_time_next;
			end if;			
		end if;
	end process;	
	
	next_state_logic: process(state, sensors, instr, rechtdoor_c, linksom_c, rechtsom_c, drive_timer_cnt_1, drive_timer_cnt_2, afsnijden_c, one_8ty_c, achteruit_c, mine_c, cp_c, drive_time_reg)
	
	procedure send_clear_instr(sort : in message) is
	begin
		case sort is
			when dont_care =>
				send_instr_next <= '0';
				clr_instr_next <= '0';
				instr_next <= "--------";

			when instr_used =>
				clr_instr_next <= '1';
				send_instr_next <= '1';
				instr_next <= "00000001";			--01

			when mijn =>
				clr_instr_next <= '1';
				send_instr_next <= '1';
				instr_next <= "00000011";			--03

			when geen_mijn =>
				clr_instr_next <= '1';
				send_instr_next <= '1';
				instr_next <= "00000010";			--02

			when error =>
				clr_instr_next <= '1';
				send_instr_next <= '1';
				instr_next <= "11111110";			--FE
		end case;
	end procedure;

	procedure robot_direction (sort : in motor_status) is
	begin
		case sort is
			when vooruit =>
				motor_l_direction <= '1';
				motor_r_direction <= '0';
				motor_l_hreset 	<= '0';	
				motor_r_hreset 	<= '0';

			when bocht_lv =>
				motor_l_direction <= '-';
				motor_r_direction <= '0';
				motor_l_hreset 	<= '1';	
				motor_r_hreset 	<= '0';

			when bocht_rv =>
				motor_l_direction <= '1';
				motor_r_direction <= '-';
				motor_l_hreset 	<= '0';	
				motor_r_hreset 	<= '1';

			when draai_l =>
				motor_l_direction <= '0';
				motor_r_direction <= '0';
				motor_l_hreset 	<= '0';	
				motor_r_hreset 	<= '0';

			when draai_r =>
				motor_l_direction <= '1';
				motor_r_direction <= '1';
				motor_l_hreset 	<= '0';	
				motor_r_hreset 	<= '0';

			when gestopt =>
				motor_l_direction <= '-';
				motor_r_direction <= '-';
				motor_l_hreset 	<= '1';
				motor_r_hreset 	<= '1';	

			when achteruit =>
				motor_l_direction <= '0';
				motor_r_direction <= '1';
				motor_l_hreset 	<= '0';
				motor_r_hreset 	<= '0';			
		end case;
	end procedure;

	begin
		send_clear_instr(dont_care);
		next_state <= state;
		drive_time_next <= drive_time_reg;

		reset_trip_timer <= '0';
		hold_trip_timer <= '0';
		lcd_select <= '0';

		drive_timer_reset_1 <= '1';
		drive_timer_load_1 <= '0';
		drive_timer_ttl_1 <= "------------";

		drive_timer_reset_2 <= '1';
		drive_timer_load_2 <= '0';
		drive_timer_ttl_2 <= "------------";

		case state is
			when reset_state =>					--wachten op eerste instructie
				robot_direction(gestopt);
				reset_trip_timer <= '1';
				sseg_1 <= seg(bar);
				sseg_2 <= seg(bar);				
				
				if instr then
					next_state <= third_part;
				end if;

			when wait_for_instr_1 =>				--tussen mijn en volgende kruispunt => afsnijden of niet
				robot_direction(gestopt);
				sseg_1 <= seg(bar);
				sseg_2 <= seg(one);
				
				if instr then
					if afsnijden_c then
						if rechtdoor_c then
							next_state <= third_part;
						elsif linksom_c then
							next_state <= linksaf;
							send_clear_instr(instr_used);
						elsif rechtsom_c then
							next_state <= rechtsaf;
							send_clear_instr(instr_used);
						else
							send_clear_instr(error);
						end if;
					else
						next_state <= third_part;
					end if;
				end if;	

			when wait_for_instr_2 =>				--wielen op zwart
				robot_direction(gestopt);
				sseg_1 <= seg(bar);
				sseg_2 <= seg(two);
				
				if instr then
					if linksom_c then
						next_state <= draai_linksom;
					elsif rechtsom_c then
						next_state <= draai_rechtsom;
					elsif rechtdoor_c then
						if cp_c then
							send_clear_instr(instr_used);
							next_state <= van_naar_cp;
						elsif afsnijden_c then
							send_clear_instr(instr_used);
							next_state <= first_part;
						else
							next_state <= vooruit_chk;
						end if;
					elsif one_8ty_c then
						next_state <= omdraaien;					
					else
						send_clear_instr(error);
					end if;
				end if;	


			when gestopt =>					--false sensor value / or unexpected all white
				robot_direction(gestopt);
				hold_trip_timer	<= '1';
				lcd_select <= '1';			
				sseg_1 <= seg(bar);
				sseg_2 <= seg(ff);

			when first_part =>					
				robot_direction(vooruit);
				drive_timer_reset_1 <= '0';				
				sseg_1 <= seg(zero);
				sseg_2 <= seg(zero);

					if (unsigned(drive_timer_cnt_1) > 2070) then
						if instr then
							if afsnijden_c then
								if rechtdoor_c then
									next_state <= third_part;
								elsif linksom_c then
									next_state <= linksaf;
									send_clear_instr(instr_used);
								elsif rechtsom_c then
									next_state <= rechtsaf;
									send_clear_instr(instr_used);
								else
									send_clear_instr(error);
									next_state <= wait_for_instr_1;
								end if;
							else
								next_state <= third_part;
							end if;
						else
							next_state <= wait_for_instr_1;
						end if;
					else
						case sensors is
							when "101" | "010" =>
								robot_direction(vooruit);
							when "000" =>
								robot_direction(vooruit);
								drive_timer_load_1 <= '1';
								drive_timer_ttl_1 <= std_logic_vector(to_unsigned(1470,12));
							when "100" |"110" =>
								robot_direction(bocht_rv);
							when "001" | "011" =>
								robot_direction(bocht_lv);
							when others =>
								next_state <= gestopt;
						
						end case;
					end if;		

			when third_part =>					--vooruit tot sensors op zwart		
				sseg_1 <= seg(zero);
				sseg_2 <= seg(five);

				case sensors is
					when "101" | "010" =>
						robot_direction(vooruit);
					when "000" =>
						robot_direction(vooruit);
						next_state <= vooruit_scherp;
					when "100" |"110" =>
						robot_direction(bocht_rv);
					when "001" | "011" =>
						robot_direction(bocht_lv);
					when others =>
						robot_direction(gestopt);
						next_state <= gestopt;
				end case;

--			when vooruit_chk =>					--for switch
--				robot_direction(vooruit);
--				drive_timer_reset_1 <= '0';
--				drive_time_next <= unsigned(drive_timer_cnt_1);
--				sseg_1 <= seg(zero);
--				sseg_2 <= seg(ff);
--
--				if(unsigned(drive_timer_cnt_1) >=  900) then
--					if mine_c then
--						next_state <= achteruit;
--						send_clear_instr(mijn);
--					else
--						send_clear_instr(geen_mijn);
--						if achteruit_c then
--							next_state <= achteruit;
--						else
--							next_state <= first_part;
--						end if;
--					end if;
--				else
--					case sensors is
--						when "101" | "010" =>
--							robot_direction(vooruit);
--						when "000" =>
--							robot_direction(vooruit);
--						when "100" |"110" =>
--							robot_direction(bocht_rv);
--						when "001" | "011" =>
--							robot_direction(bocht_lv);
--						when others =>
--							next_state <= gestopt;
--					end case;
--				end if;

			when vooruit_chk =>				--with sensor
				robot_direction(vooruit);
				drive_timer_reset_1 <= '0';
				drive_time_next <= unsigned(drive_timer_cnt_1);
				sseg_1 <= seg(zero);
				sseg_2 <= seg(ff);

				if(unsigned(drive_timer_cnt_1) >=  550) then
					send_clear_instr(geen_mijn);
					if achteruit_c then
						next_state <= achteruit;
					else
						next_state <= first_part;
					end if;
				else
					
					if mine_c then
						next_state <= achteruit;
						send_clear_instr(mijn);
					else
						case sensors is
							when "101" | "010" =>
								robot_direction(vooruit);
							when "000" =>
								robot_direction(vooruit);
							when "100" |"110" =>
								robot_direction(bocht_rv);
							when "001" | "011" =>
								robot_direction(bocht_lv);
							when others =>
								next_state <= gestopt;
						end case;
					end if;
				end if;
--
			when vooruit_scherp =>								--vooruit timer van sensors over de lijn naar wielen op de lijn
				robot_direction(vooruit);
				drive_timer_reset_2 <= '0';
				sseg_1 <= seg(zero);
				sseg_2 <= seg(aa);

				if (unsigned(drive_timer_cnt_2) >=  330) then
					if linksom_c then
						next_state <= draai_linksom;
					elsif rechtsom_c then
						next_state <= draai_rechtsom;
					elsif rechtdoor_c then
						if cp_c then
							send_clear_instr(instr_used);
							next_state <= van_naar_cp;
						elsif afsnijden_c then
							send_clear_instr(instr_used);
							next_state <= first_part;
						else
							next_state <= vooruit_chk;
						end if;
					elsif one_8ty_c then
						next_state <= omdraaien;					
					else
						send_clear_instr(error);
						next_state <= wait_for_instr_2;
					end if;
				else
					case sensors is
						when "101" | "010" | "111" =>
							robot_direction(vooruit);
						when "000" =>
							robot_direction(vooruit);
 							drive_timer_reset_2 <= '1';
						when "100" |"110" =>
							robot_direction(bocht_rv);
						when "001" | "011" =>
							robot_direction(bocht_lv);
						when others =>
							next_state <= gestopt;
					end case;
				end if;

			when achteruit =>							--achteruit tot tot wielen op de lijn dmv timer
				robot_direction(achteruit);
				drive_timer_reset_2 <= '0';
				sseg_1 <= seg(one);
				sseg_2 <= seg(zero);
				
				if((unsigned(drive_timer_cnt_2)) >= drive_time_reg)then			-- >= drive_time_reg*(8/9)
					if instr then
						if linksom_c then
							next_state <= draai_linksom;
						elsif rechtsom_c then
							next_state <= draai_rechtsom;
						elsif one_8ty_c then
							next_state <= omdraaien;					
						else
							send_clear_instr(error);
							next_state <= wait_for_instr_2;
						end if;
					else
						next_state <= wait_for_instr_2;
					end if;
				end if;	

			when van_naar_cp =>								--van en naar cp.
				drive_timer_reset_1 <= '0';
				sseg_1 <= seg(one);
				sseg_2 <= seg(five);
		
				if(unsigned(drive_timer_cnt_1) >=  800)then
					robot_direction(gestopt);
					if instr then
						if linksom_c then
							next_state <= draai_linksom;
						elsif rechtsom_c then
							next_state <= draai_rechtsom;
						elsif one_8ty_c then
							next_state <= omdraaien;					
						else
							send_clear_instr(error);
							next_state <= wait_for_instr_2;
						end if;
					else
						next_state <= wait_for_instr_2;
					end if;
				elsif(unsigned(drive_timer_cnt_1) >= 400)then
					robot_direction(achteruit);
				else
					case sensors is
						when "101" | "010" =>
							robot_direction(vooruit);
						when "100" |"110" =>
							robot_direction(bocht_rv);
						when "001" | "011" =>
							robot_direction(bocht_lv);
						when others =>
							robot_direction(gestopt);
							next_state <= gestopt;
					end case;
				end if;

			when linksaf =>
				robot_direction(draai_l);
				drive_timer_reset_2 <= '0';
				sseg_1 <= seg(two);
				sseg_2 <= seg(zero);
	
				if ((unsigned(drive_timer_cnt_2) > 400) and (sensors = "111")) then
					next_state <= linksaf_pt2;
				end if;

			when linksaf_pt2 =>
				robot_direction(vooruit);
				sseg_1 <= seg(two);
				sseg_2 <= seg(five);
		
				if (sensors /= "111") then
					next_state <= linksaf_pt3;
				end if;
		
			when linksaf_pt3 =>
				robot_direction(vooruit);
				sseg_1 <= seg(two);
				sseg_2 <= seg(aa);

				if (sensors = "111")then
					next_state <= linksaf_pt4;
				end if;

			when linksaf_pt4 =>
				robot_direction(draai_l);
				drive_timer_reset_1 <= '0';
				drive_timer_load_1 <= '1';
				drive_timer_ttl_1 <= std_logic_vector(to_unsigned(1330,12));
				sseg_1 <= seg(two);
				sseg_2 <= seg(ff);

				if ((sensors = "101") or (sensors = "100"))then
					next_state <= first_part;
				end if;				

			when rechtsaf =>
				robot_direction(draai_r);
				drive_timer_reset_2 <= '0';
				sseg_1 <= seg(three);
				sseg_2 <= seg(zero);

				if ((unsigned(drive_timer_cnt_2) > 400) and (sensors = "111")) then
					next_state <= rechtsaf_pt2;
				end if;

			when rechtsaf_pt2 =>
				robot_direction(vooruit);
				sseg_1 <= seg(three);
				sseg_2 <= seg(five);

				if (sensors /= "111") then
					next_state <= rechtsaf_pt3;
				end if;

			when rechtsaf_pt3 =>
				robot_direction(vooruit);
				sseg_1 <= seg(three);
				sseg_2 <= seg(aa);

				if (sensors = "111")then
					next_state <= rechtsaf_pt4;
				end if;

			when rechtsaf_pt4 =>
				robot_direction(draai_r);
				drive_timer_reset_1 <= '0';
				drive_timer_load_1 <= '1';
				drive_timer_ttl_1 <= std_logic_vector(to_unsigned(1330,12));
				sseg_1 <= seg(three);
				sseg_2 <= seg(ff);

				if (sensors = "101") or (sensors = "001")then
					next_state <= first_part;
				end if;
				

			when draai_linksom =>
				robot_direction(draai_l);
				sseg_1 <= seg(four);
				sseg_2 <= seg(zero);

					if(sensors = "111") then
						next_state <= draai_linksom_pt2;
					end if;


			when draai_linksom_pt2 =>
				robot_direction(draai_l);
				sseg_1 <= seg(four);
				sseg_2 <= seg(five);

					if((sensors = "101") or (sensors = "100") or (sensors = "001"))then
						robot_direction(vooruit);
						if cp_c then
							send_clear_instr(instr_used);
							next_state <= van_naar_cp;
						elsif afsnijden_c then
							send_clear_instr(instr_used);
							next_state <= first_part;
						else
							next_state <= vooruit_chk;
						end if;
					end if;

			when draai_rechtsom =>
				robot_direction(draai_r);
				sseg_1 <= seg(five);
				sseg_2 <= seg(zero);

					if(sensors = "111") then
						next_state <= draai_rechtsom_pt2;
					end if;


			when draai_rechtsom_pt2 =>
				robot_direction(draai_r);
				sseg_1 <= seg(five);
				sseg_2 <= seg(five);

					if((sensors = "101") or (sensors = "001") or (sensors = "100"))then
						robot_direction(vooruit);
						if cp_c then
							send_clear_instr(instr_used);
							next_state <= van_naar_cp;
						elsif afsnijden_c then
							send_clear_instr(instr_used);
							next_state <= first_part;
						else
							next_state <= vooruit_chk;
						end if;
					end if;

			when omdraaien =>
				robot_direction(draai_r);
				sseg_1 <= seg(six);
				sseg_2 <= seg(zero);

				if(sensors = "111") then
					next_state <= omdraaien_pt2;
				end if;

			when omdraaien_pt2 =>
				robot_direction(draai_r);
				sseg_1 <= seg(six);
				sseg_2 <= seg(five);

				if(sensors /= "111") then
					next_state <= draai_rechtsom;
				end if;	

		end case;

--		if(timer_lcd = "01") then
--			if (unsigned(drive_timer_cnt_1) >=3000) then sseg_3 <= seg(three); sseg_4 <= seg(zero);
--			elsif (unsigned(drive_timer_cnt_1) >=2900) then sseg_3 <= seg(two); sseg_4 <= seg(nine);
--			elsif (unsigned(drive_timer_cnt_1) >=2800) then sseg_3 <= seg(two); sseg_4 <= seg(eight);
--			elsif (unsigned(drive_timer_cnt_1) >=2700) then sseg_3 <= seg(two); sseg_4 <= seg(seven);
--			elsif (unsigned(drive_timer_cnt_1) >=2600) then sseg_3 <= seg(two); sseg_4 <= seg(six);
--			elsif (unsigned(drive_timer_cnt_1) >=2500) then sseg_3 <= seg(two); sseg_4 <= seg(five);
--			elsif (unsigned(drive_timer_cnt_1) >=2400) then sseg_3 <= seg(two); sseg_4 <= seg(four);
--			elsif (unsigned(drive_timer_cnt_1) >=2300) then sseg_3 <= seg(two); sseg_4 <= seg(three);
--			elsif (unsigned(drive_timer_cnt_1) >=2200) then sseg_3 <= seg(two); sseg_4 <= seg(two);
--			elsif (unsigned(drive_timer_cnt_1) >=2100) then sseg_3 <= seg(two); sseg_4 <= seg(one);
--			elsif (unsigned(drive_timer_cnt_1) >=2000) then sseg_3 <= seg(two); sseg_4 <= seg(zero);
--			elsif (unsigned(drive_timer_cnt_1) >=1900) then sseg_3 <= seg(one); sseg_4 <= seg(nine);
--			elsif (unsigned(drive_timer_cnt_1) >=1800) then sseg_3 <= seg(one); sseg_4 <= seg(eight);
--			elsif (unsigned(drive_timer_cnt_1) >=1700) then sseg_3 <= seg(one); sseg_4 <= seg(seven);
--			elsif (unsigned(drive_timer_cnt_1) >=1600) then sseg_3 <= seg(one); sseg_4 <= seg(six);
--			elsif (unsigned(drive_timer_cnt_1) >=1500) then sseg_3 <= seg(one); sseg_4 <= seg(five);
--			elsif (unsigned(drive_timer_cnt_1) >=1400) then sseg_3 <= seg(one); sseg_4 <= seg(four);
--			elsif (unsigned(drive_timer_cnt_1) >=1300) then sseg_3 <= seg(one); sseg_4 <= seg(three);
--			elsif (unsigned(drive_timer_cnt_1) >=1200) then sseg_3 <= seg(one); sseg_4 <= seg(two);
--			elsif (unsigned(drive_timer_cnt_1) >=1100) then  sseg_3 <= seg(one); sseg_4 <= seg(one);
--			elsif (unsigned(drive_timer_cnt_1) >=1000) then sseg_3 <= seg(one); sseg_4 <= seg(zero);
--			elsif (unsigned(drive_timer_cnt_1) >=900) then sseg_3 <= seg(zero); sseg_4 <= seg(nine);
--			elsif (unsigned(drive_timer_cnt_1) >=800) then sseg_3 <= seg(zero); sseg_4 <= seg(eight);
--			elsif (unsigned(drive_timer_cnt_1) >=700) then sseg_3 <= seg(zero); sseg_4 <= seg(seven);
--			elsif (unsigned(drive_timer_cnt_1) >=600) then  sseg_3 <= seg(zero); sseg_4 <= seg(six);
--			elsif (unsigned(drive_timer_cnt_1) >=500) then  sseg_3 <= seg(zero); sseg_4 <= seg(five);
--			elsif (unsigned(drive_timer_cnt_1) >=400) then sseg_3 <= seg(zero); sseg_4 <= seg(four);
--			elsif (unsigned(drive_timer_cnt_1) >=300) then  sseg_3 <= seg(zero); sseg_4 <= seg(three);
--			elsif (unsigned(drive_timer_cnt_1) >=200) then  sseg_3 <= seg(zero); sseg_4 <= seg(two);
--			elsif (unsigned(drive_timer_cnt_1) >=100) then  sseg_3 <= seg(zero); sseg_4 <= seg(one);
--			else sseg_3 <= seg(zero); sseg_4 <= seg(zero);
--			end if;	
--		elsif(timer_lcd = "10") then
--			if (unsigned(drive_timer_cnt_2) >=3000) then sseg_3 <= seg(three); sseg_4 <= seg(zero);
--			elsif (unsigned(drive_timer_cnt_2) >=2900) then sseg_3 <= seg(two); sseg_4 <= seg(nine);
--			elsif (unsigned(drive_timer_cnt_2) >=2800) then sseg_3 <= seg(two); sseg_4 <= seg(eight);
--			elsif (unsigned(drive_timer_cnt_2) >=2700) then sseg_3 <= seg(two); sseg_4 <= seg(seven);
--			elsif (unsigned(drive_timer_cnt_2) >=2600) then sseg_3 <= seg(two); sseg_4 <= seg(six);
--			elsif (unsigned(drive_timer_cnt_2) >=2500) then sseg_3 <= seg(two); sseg_4 <= seg(five);
--			elsif (unsigned(drive_timer_cnt_2) >=2400) then sseg_3 <= seg(two); sseg_4 <= seg(four);
--			elsif (unsigned(drive_timer_cnt_2) >=2300) then sseg_3 <= seg(two); sseg_4 <= seg(three);
--			elsif (unsigned(drive_timer_cnt_2) >=2200) then sseg_3 <= seg(two); sseg_4 <= seg(two);
--			elsif (unsigned(drive_timer_cnt_2) >=2100) then sseg_3 <= seg(two); sseg_4 <= seg(one);
--			elsif (unsigned(drive_timer_cnt_2) >=2000) then sseg_3 <= seg(two); sseg_4 <= seg(zero);
--			elsif (unsigned(drive_timer_cnt_2) >=1900) then sseg_3 <= seg(one); sseg_4 <= seg(nine);
--			elsif (unsigned(drive_timer_cnt_2) >=1800) then sseg_3 <= seg(one); sseg_4 <= seg(eight);
--			elsif (unsigned(drive_timer_cnt_2) >=1700) then sseg_3 <= seg(one); sseg_4 <= seg(seven);
--			elsif (unsigned(drive_timer_cnt_2) >=1600) then sseg_3 <= seg(one); sseg_4 <= seg(six);
--			elsif (unsigned(drive_timer_cnt_2) >=1500) then sseg_3 <= seg(one); sseg_4 <= seg(five);
--			elsif (unsigned(drive_timer_cnt_2) >=1400) then sseg_3 <= seg(one); sseg_4 <= seg(four);
--			elsif (unsigned(drive_timer_cnt_2) >=1300) then sseg_3 <= seg(one); sseg_4 <= seg(three);
--			elsif (unsigned(drive_timer_cnt_2) >=1200) then sseg_3 <= seg(one); sseg_4 <= seg(two);
--			elsif (unsigned(drive_timer_cnt_2) >=1100) then  sseg_3 <= seg(one); sseg_4 <= seg(one);
--			elsif (unsigned(drive_timer_cnt_2) >=1000) then sseg_3 <= seg(one); sseg_4 <= seg(zero);
--			elsif (unsigned(drive_timer_cnt_2) >=900) then sseg_3 <= seg(zero); sseg_4 <= seg(nine);
--			elsif (unsigned(drive_timer_cnt_2) >=800) then sseg_3 <= seg(zero); sseg_4 <= seg(eight);
--			elsif (unsigned(drive_timer_cnt_2) >=700) then sseg_3 <= seg(zero); sseg_4 <= seg(seven);
--			elsif (unsigned(drive_timer_cnt_2) >=600) then  sseg_3 <= seg(zero); sseg_4 <= seg(six);
--			elsif (unsigned(drive_timer_cnt_2) >=500) then  sseg_3 <= seg(zero); sseg_4 <= seg(five);
--			elsif (unsigned(drive_timer_cnt_2) >=400) then sseg_3 <= seg(zero); sseg_4 <= seg(four);
--			elsif (unsigned(drive_timer_cnt_2) >=300) then  sseg_3 <= seg(zero); sseg_4 <= seg(three);
--			elsif (unsigned(drive_timer_cnt_2) >=200) then  sseg_3 <= seg(zero); sseg_4 <= seg(two);
--			elsif (unsigned(drive_timer_cnt_2) >=100) then  sseg_3 <= seg(zero); sseg_4 <= seg(one);
--			else sseg_3 <= seg(zero); sseg_4 <= seg(zero);
--			end if;	
--		else
			if (unsigned(drive_timer_cnt_2) >=3000) then sseg_3 <= seg(three); sseg_4 <= seg(zero);
			elsif (drive_time_reg >=2900) then sseg_3 <= seg(two); sseg_4 <= seg(nine);
			elsif (drive_time_reg >=2800) then sseg_3 <= seg(two); sseg_4 <= seg(eight);
			elsif (drive_time_reg >=2700) then sseg_3 <= seg(two); sseg_4 <= seg(seven);
			elsif (drive_time_reg >=2600) then sseg_3 <= seg(two); sseg_4 <= seg(six);
			elsif (drive_time_reg >=2500) then sseg_3 <= seg(two); sseg_4 <= seg(five);
			elsif (drive_time_reg >=2400) then sseg_3 <= seg(two); sseg_4 <= seg(four);
			elsif (drive_time_reg >=2300) then sseg_3 <= seg(two); sseg_4 <= seg(three);
			elsif (drive_time_reg >=2200) then sseg_3 <= seg(two); sseg_4 <= seg(two);
			elsif (drive_time_reg >=2100) then sseg_3 <= seg(two); sseg_4 <= seg(one);
			elsif (drive_time_reg >=2000) then sseg_3 <= seg(two); sseg_4 <= seg(zero);
			elsif (drive_time_reg >=1900) then sseg_3 <= seg(one); sseg_4 <= seg(nine);
			elsif (drive_time_reg >=1800) then sseg_3 <= seg(one); sseg_4 <= seg(eight);
			elsif (drive_time_reg >=1700) then sseg_3 <= seg(one); sseg_4 <= seg(seven);
			elsif (drive_time_reg >=1600) then sseg_3 <= seg(one); sseg_4 <= seg(six);
			elsif (drive_time_reg >=1500) then sseg_3 <= seg(one); sseg_4 <= seg(five);
			elsif (drive_time_reg >=1400) then sseg_3 <= seg(one); sseg_4 <= seg(four);
			elsif (drive_time_reg >=1300) then sseg_3 <= seg(one); sseg_4 <= seg(three);
			elsif (drive_time_reg >=1200) then sseg_3 <= seg(one); sseg_4 <= seg(two);
			elsif (drive_time_reg >=1100) then  sseg_3 <= seg(one); sseg_4 <= seg(one);
			elsif (drive_time_reg >=1000) then sseg_3 <= seg(one); sseg_4 <= seg(zero);
			elsif (drive_time_reg >=900) then sseg_3 <= seg(zero); sseg_4 <= seg(nine);
			elsif (drive_time_reg >=800) then sseg_3 <= seg(zero); sseg_4 <= seg(eight);
			elsif (drive_time_reg >=700) then sseg_3 <= seg(zero); sseg_4 <= seg(seven);
			elsif (drive_time_reg >=600) then  sseg_3 <= seg(zero); sseg_4 <= seg(six);
			elsif (drive_time_reg >=500) then  sseg_3 <= seg(zero); sseg_4 <= seg(five);
			elsif (drive_time_reg >=400) then sseg_3 <= seg(zero); sseg_4 <= seg(four);
			elsif (drive_time_reg >=300) then  sseg_3 <= seg(zero); sseg_4 <= seg(three);
			elsif (drive_time_reg >=200) then  sseg_3 <= seg(zero); sseg_4 <= seg(two);
			elsif (drive_time_reg >=100) then  sseg_3 <= seg(zero); sseg_4 <= seg(one);
			else sseg_3 <= seg(zero); sseg_4 <= seg(zero);
			end if;	

--		end if;

	end process;

	seg_1 <= sseg_1;
	seg_2 <= sseg_2;
	seg_3 <= sseg_3;
	seg_4 <= sseg_4;

end architecture behavioural;



