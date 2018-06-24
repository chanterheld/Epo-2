USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FPGA is
	port (	clk		: in	std_logic;
		reset		: in	std_logic;

		rx		: in	std_logic; --data out from xbee
		tx		: out 	std_logic; --data in to xbee

		sensor_l_in	: in	std_logic;
		sensor_m_in	: in	std_logic;
		sensor_r_in	: in	std_logic;

		pwm_l		: out	std_logic;
		pwm_r		: out	std_logic;

		mine_sensor	: in	std_logic;

		seg		: out	std_logic_vector(7 downto 0);
		an		: out 	std_logic_vector(3 downto 0);
		led		: out 	std_logic_vector(7 downto 0)		
	);
end entity FPGA;

architecture structural of FPGA is
	
	component timebase is
	port (	clk		: in	std_logic;
		reset		: in	std_logic;

		count_out	: out	std_logic_vector (19 downto 0)
	);
	end component timebase;

	component motorcontrol is
	port (	clk		: in	std_logic;
		reset		: in	std_logic;
		direction	: in	std_logic;
		count_in	: in	std_logic_vector (19 downto 0);

		pwm		: out	std_logic
	);
	end component motorcontrol;

	component inputbuffer is
	port (	clk		: in	std_logic;
		reset		: in	std_logic;

		sensor_l_in	: in	std_logic;
		sensor_m_in	: in	std_logic;
		sensor_r_in	: in	std_logic;

		sensors_out	: out 	std_logic_vector(2 downto 0)
	);
	end component inputbuffer;

	component controller is
	port (	clk			: in	std_logic;
		reset			: in	std_logic;

		sensors			: in	std_logic_vector(2 downto 0);

		instr_in		: in	std_logic_vector(7 downto 0);
		instr_rdy		: in	std_logic;
		clr_instr		: out	std_logic;

		instr_out		: out 	std_logic_vector(7 downto 0);
		send_instr		: out 	std_logic;

		count_in		: in	std_logic_vector (19 downto 0);
		count_reset		: out	std_logic;

		motor_l_reset		: out	std_logic;
		motor_l_direction	: out	std_logic;

		motor_r_reset		: out	std_logic;
		motor_r_direction	: out	std_logic;

		drive_timer_reset_1	: out 	std_logic;
		drive_timer_load_1	: out	std_logic;
		drive_timer_ttl_1	: out	std_logic_vector(11 downto 0);
		drive_timer_cnt_1	: in 	std_logic_vector(11 downto 0);

		drive_timer_reset_2	: out 	std_logic;
		drive_timer_load_2	: out	std_logic;
		drive_timer_ttl_2	: out	std_logic_vector(11 downto 0);
		drive_timer_cnt_2	: in 	std_logic_vector(11 downto 0);

		mine			: in 	std_logic;

		seg_1			: out	std_logic_vector(7 downto 0);
		seg_2			: out	std_logic_vector(7 downto 0);
		seg_3			: out	std_logic_vector(7 downto 0);
		seg_4			: out	std_logic_vector(7 downto 0);

		reset_trip_timer	: out	std_logic;
		hold_trip_timer		: out	std_logic;
		lcd_select		: out	std_logic
	);
	end component controller;

	component uart is
		port (
			clk		: in 	std_logic; 
			reset		: in 	std_logic;
			rx		: in 	std_logic; 
			tx		: out 	std_logic;
			D_transmit	: in 	std_logic_vector(7 downto 0); 
			D_received	: out 	std_logic_vector(7 downto 0);
			send_data	: in 	std_logic; 
			data_read	: in 	std_logic;
			data_rdy	: out	std_logic
		);
	end component uart;

	component multiplexer is
		port(	clk		: in	std_logic;
			reset		: in 	std_logic;
			lcd_select	: in	std_logic;

			seg_1		: in	std_logic_vector(7 downto 0);
			seg_2		: in	std_logic_vector(7 downto 0);
			seg_3		: in	std_logic_vector(7 downto 0);
			seg_4		: in	std_logic_vector(7 downto 0);

			seg_5		: in	std_logic_vector(7 downto 0);
			seg_7		: in	std_logic_vector(7 downto 0);
			seg_8		: in	std_logic_vector(7 downto 0);

			mine		: in	std_logic;

			seg		: out 	std_logic_vector(7 downto 0);
			an		: out	std_logic_vector(3 downto 0)
		);
	end component multiplexer;

	component drive_timer is
		port(	clk		: in	std_logic;
			reset		: in	std_logic;
			load		: in	std_logic;

			time_loaded	: in	std_logic_vector(11 downto 0);
			count_out	: out	std_logic_vector(11 downto 0)

		);
	end component drive_timer;

	component mine_deco is
		port(	clk	: in	std_logic;
			reset	: in	std_logic;
			sensor	: in	std_logic;
			mine	: out	std_logic
		);
	end component mine_deco;

	component trip_timer is
		port(	clk		: in	std_logic;
			reset		: in	std_logic;
			hold		: in	std_logic;

			minutes		: out	std_logic_vector(7 downto 0);
			tens		: out	std_logic_vector(7 downto 0);
			seconds		: out	std_logic_vector(7 downto 0)
		);
	end component trip_timer;

	component inputbuffer_mine is
		port (	clk		: in	std_logic;
			reset		: in	std_logic;
			buf_in		: in	std_logic;
			buf_out		: out	std_logic
		);
	end component inputbuffer_mine;

	for UART1:uart use entity work.uart(structural);
	--for UART1:uart use entity work.uart(structural_save);
	--for UART1:uart use entity work.uart(structural_save_2);

	for controller1:controller use entity work.controller(behavioural);

	for mijn_sensor1:mine_deco use entity work.mine_deco(behav);

	

	signal sensors_thru: std_logic_vector(2 downto 0); 

	signal motor_l_reset, motor_r_reset, motor_l_direction, motor_r_direction : std_logic;

	signal count_reset: std_logic;
	signal count : std_logic_vector (19 downto 0);

	signal instr_in, instr_out: std_logic_vector (7 downto 0);
	signal send_instr, clr_instr, instr_rdy: std_logic;

	signal seg_1, seg_2, seg_3, seg_4: std_logic_vector(7 downto 0);
	signal minutes, tens, seconds: std_logic_vector(7 downto 0);
	signal reset_trip_timer, hold_trip_timer, lcd_select: std_logic;

	signal drive_timer_reset_1, drive_timer_load_1: std_logic;
	signal drive_timer_cnt_1, drive_timer_ttl_1: std_logic_vector(11 downto 0);

	signal drive_timer_reset_2, drive_timer_load_2: std_logic;
	signal drive_timer_cnt_2, drive_timer_ttl_2: std_logic_vector(11 downto 0);

	signal deco_out, buffered_mine_sensor: std_logic;


begin
	
	buffer1:	inputbuffer	port map (	clk		=> clk,
							reset		=> reset,

							sensor_l_in	=> sensor_l_in,
							sensor_m_in	=> sensor_m_in,
							sensor_r_in	=> sensor_r_in,

							sensors_out	=> sensors_thru
					);	

	controller1:	controller 	port map(	clk		=> clk,
							reset		=> reset,
	
							sensors		=> sensors_thru,

							instr_in	=> instr_in,
							instr_rdy	=> instr_rdy,
							clr_instr	=> clr_instr,

							instr_out	=> instr_out,
							send_instr	=> send_instr,
							
							count_in	=> count,
							count_reset	=> count_reset,
	
							motor_l_reset	=> motor_l_reset,
							motor_l_direction	=> motor_l_direction,

							motor_r_reset	=> motor_r_reset,
							motor_r_direction	=> motor_r_direction,

							drive_timer_reset_1	=> drive_timer_reset_1,
							drive_timer_load_1	=> drive_timer_load_1,
							drive_timer_ttl_1	=> drive_timer_ttl_1,
							drive_timer_cnt_1	=> drive_timer_cnt_1,

							drive_timer_reset_2	=> drive_timer_reset_2,
							drive_timer_load_2	=> drive_timer_load_2,
							drive_timer_ttl_2	=> drive_timer_ttl_2,
							drive_timer_cnt_2	=> drive_timer_cnt_2,

							mine		=> deco_out,

							seg_1		=> seg_1,
							seg_2		=> seg_2,
							seg_3		=> seg_3,
							seg_4		=> seg_4,

							reset_trip_timer	=> reset_trip_timer,
							hold_trip_timer		=> hold_trip_timer,
							lcd_select		=> lcd_select
					);

	timebase1:	timebase	port map(	clk		=> clk,
							reset		=> count_reset,

							count_out	=> count
					);

	motorcrl_L:	motorcontrol 	port map(	clk		=> clk,
							reset		=> motor_l_reset,
							direction	=> motor_l_direction,
							count_in	=> count,

							pwm		=> pwm_l
					);

	motorcrl_R:	motorcontrol 	port map(	clk		=> clk,
							reset		=> motor_r_reset,
							direction	=> motor_r_direction,
							count_in	=> count,

							pwm		=> pwm_r
					);

	UART1:		uart		port map(	clk		=> clk,
							reset		=> reset,
							rx		=> rx, 
							tx		=> tx,
							D_transmit	=> instr_out,
							D_received	=> instr_in,
							send_data	=> send_instr, 
							data_read	=> clr_instr,
							data_rdy	=> instr_rdy
					);

	multplx1:	multiplexer	port map(	clk		=> clk,
							reset		=> reset,
							lcd_select	=> lcd_select,

							seg_1		=> seg_1,
							seg_2		=> seg_2,
							seg_3		=> seg_3,
							seg_4		=> seg_4,

							seg_5		=> minutes,
							seg_7		=> tens,
							seg_8		=> seconds,

							mine		=> deco_out,

							seg		=> seg,
							an		=> an
					);


	drive_tmr1:	drive_timer	port map(	clk		=> clk,
							reset		=> drive_timer_reset_1,
							load		=> drive_timer_load_1,

							time_loaded	=> drive_timer_ttl_1,
							count_out	=> drive_timer_cnt_1

					);

	drive_tmr2:	drive_timer	port map(	clk		=> clk,
							reset		=> drive_timer_reset_2,
							load		=> drive_timer_load_2,

							time_loaded	=> drive_timer_ttl_2,
							count_out	=> drive_timer_cnt_2

					);


	mijn_sensor1:	mine_deco	port map(	clk		=> clk,
							reset		=> reset,
							sensor		=> buffered_mine_sensor,
							mine		=> deco_out
						);

	trip_timer1:	trip_timer	port map(	clk		=>clk,
							reset		=>reset_trip_timer,
							hold		=>hold_trip_timer,

							minutes		=>minutes,
							tens		=>tens,
							seconds		=>seconds
					);

	buf_mine1:	inputbuffer_mine port map (	clk		=> clk,
							reset		=> reset,
							buf_in		=> mine_sensor,
							buf_out		=> buffered_mine_sensor
					);

	led <= instr_in;

end architecture structural;
