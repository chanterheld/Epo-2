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
	);
end entity controller;

architecture behavioural of controller is
								-- LCD code
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
					counter_steer,		-- 4A

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

constant turn_offset: integer := 30;

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
		case sort is							-- procedure voor verzenden informatie en clearing instr flag
			when dont_care =>					-- hex code
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
		case sort is							-- procedure voor motor aansturing
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

					if (unsigned(drive_timer_cnt_1) > (2070 + turn_offset)) then
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
								elsif one_8ty_c then
									next_state <= third_part;
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
								drive_timer_ttl_1 <= std_logic_vector(to_unsigned(1470 + turn_offset,12));
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

			when vooruit_chk =>				--vooruit mijn check
				robot_direction(vooruit);
				drive_timer_reset_1 <= '0';
				drive_time_next <= unsigned(drive_timer_cnt_1);
				sseg_1 <= seg(zero);
				sseg_2 <= seg(ff);

				if(unsigned(drive_timer_cnt_1) >=  (550 + turn_offset)) then
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
			when vooruit_scherp =>								--vooruit van sensors over de lijn naar wielen op de lijn
				robot_direction(vooruit);
				drive_timer_reset_2 <= '0';
				sseg_1 <= seg(zero);
				sseg_2 <= seg(aa);

				if (unsigned(drive_timer_cnt_2) >=  310) then
					if linksom_c then
						next_state <= draai_linksom;
					elsif rechtsom_c then
						next_state <= draai_rechtsom;
					elsif rechtdoor_c then
						drive_timer_reset_1 <= '0';
						drive_timer_load_1 <= '1';
						drive_timer_ttl_1 <= std_logic_vector(to_unsigned(turn_offset,12));
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
				
				if((unsigned(drive_timer_cnt_2)) >= (drive_time_reg - turn_offset))then	
					if instr then
						if linksom_c then
							next_state <= draai_linksom;
						elsif rechtdoor_c then
							drive_timer_reset_1 <= '0';
							drive_timer_load_1 <= '1';
							drive_timer_ttl_1 <= std_logic_vector(to_unsigned(turn_offset,12));
							if cp_c then
								send_clear_instr(instr_used);
								next_state <= van_naar_cp;
							elsif afsnijden_c then
								send_clear_instr(instr_used);
								next_state <= first_part;
							else
								next_state <= vooruit_chk;
							end if;
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
		
				if(unsigned(drive_timer_cnt_1) >=  (800 + turn_offset))then
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
				elsif(unsigned(drive_timer_cnt_1) >= (400 + turn_offset))then
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

			when linksaf =>									-- naar links afsnijden manouvre
				robot_direction(draai_l);						-- 1) van de lijn afdraaien 
				drive_timer_reset_2 <= '0';						-- 2) rechdoor rijden over wit
				sseg_1 <= seg(two);							-- 3) over de lijn heen rijden
				sseg_2 <= seg(zero);							-- 4) op de lijn sturen als de sensoren er voorbij zijn
	
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

			when rechtsaf =>								-- naar rechts afnijden mouvre zie: linksaf
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
				

			when draai_linksom =>									--linkom draaien manouvre
				robot_direction(draai_l);							-- 1) van de huidige lijn afdraaien
				sseg_1 <= seg(four);								-- 2) tot op de nieuwe lijn sturen
				sseg_2 <= seg(zero);

					if(sensors = "111") then
						next_state <= draai_linksom_pt2;
					end if;


			when draai_linksom_pt2 =>
				robot_direction(draai_l);
				sseg_1 <= seg(four);
				sseg_2 <= seg(five);

					if((sensors = "101") or (sensors = "100") or (sensors = "001"))then
						next_state <= counter_steer;
					end if;

			when counter_steer =>
				robot_direction(draai_r);
				drive_timer_reset_2 <= '0';
				sseg_1 <= seg(four);
				sseg_2 <= seg(aa);

					if(unsigned(drive_timer_cnt_2) > 20)then
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

			when draai_rechtsom =>									--rechtsom draaien manouvre, zie: linksom
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

					if((sensors = "101") or (sensors = "001")or (sensors = "100"))then		
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

			when omdraaien =>									--omdraaien manouvre => 2x rechtsom manouvre
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
	end process;

	seg_1 <= sseg_1;
	seg_2 <= sseg_2;
	seg_3 <= sseg_3;
	seg_4 <= sseg_4;

end architecture behavioural;
