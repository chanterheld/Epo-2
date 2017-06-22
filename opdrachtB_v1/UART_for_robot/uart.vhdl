library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
	port (
		clk		: in 	std_logic; 
		reset		: in 	std_logic;
		rx		: in 	std_logic; --input bit stream
		tx		: out 	std_logic; --output bit stream
		D_transmit	: in 	std_logic_vector(7 downto 0); --byte to be sent
		D_received	: out 	std_logic_vector(7 downto 0); --received byte
		send_data	: in 	std_logic; --write to transmitter buffer 
		data_read	: in 	std_logic; --read from receiver buffer 
		data_rdy	: out	std_logic
	);
end uart;

architecture structural of uart is

component baud_gen is
  	generic(M		: integer	:= 326 -- baud rate divisor M = 50M/(16*9600)
	);
   	
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		s_tick		: out 	std_logic -- sampling tick
   	);
end component baud_gen;

component buf_reg is
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		clr_flag	: in 	std_logic;
		set_flag	: in 	std_logic; 
      		din		: in 	std_logic_vector(7 downto 0);
      		dout		: out	std_logic_vector(7 downto 0);
      		flag		: out 	std_logic
   	);
end component buf_reg;

component uart_rx is
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		rx		: in 	std_logic; -- icoming serial bit stream
      		s_tick		: in 	std_logic; -- sampling tick from baud rate generator
      		rx_done_tick	: out	std_logic; -- data frame completion tick
      		dout		: out	std_logic_vector(7 downto 0) -- data byte
   	);
end component uart_rx ;

component uart_tx is
 	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		tx_start	: in 	std_logic; -- if '1' transmission starts
      		s_tick		: in 	std_logic; -- sampling tick from baud rate generator
      		din		: in 	std_logic_vector(7 downto 0); -- incoming data byte
      		tx_done_tick	: out 	std_logic; -- data frame completion tick 
      		tx		: out 	std_logic -- outcoming bit stream
   	);
end component uart_tx ;

signal s_tick : std_logic;
signal rx_done_tick, tx_done_tick, tx_start : std_logic;
signal rx_dout, tx_din : std_logic_vector(7 downto 0);
 
begin
baud_gen1:	baud_gen	port map(	clk		=>clk,
						reset		=>reset,
      						s_tick		=>s_tick
				);

buf_reg_rx:	buf_reg 	port map(	clk		=>clk,
						reset		=>reset,
      						clr_flag	=>data_read,
						set_flag	=>rx_done_tick,
      						din		=>rx_dout,
      						dout		=>D_received,
      						flag		=>data_rdy
   				);

buf_reg_tx:	buf_reg 	port map(	clk		=>clk,
						reset		=>reset,
      						clr_flag	=>tx_done_tick,
						set_flag	=>send_data,
      						din		=>D_transmit,
      						dout		=>tx_din,
      						flag		=>tx_start
   				);

uart_rx1:	uart_rx		port map(	clk		=>clk,
						reset		=>reset,
      						rx		=>rx,
      						s_tick		=>s_tick,
      						rx_done_tick	=>rx_done_tick,
   				   		dout		=>rx_dout
   				);

uart_tx1:	uart_tx		port map(	clk		=>clk,
						reset		=>reset,
      						tx_start	=>tx_start,
      						s_tick		=>s_tick,   
						din		=>tx_din,
      						tx_done_tick	=>tx_done_tick, 
      						tx		=>tx
   				);


end architecture structural;

architecture structural_save of uart is

component baud_gen is
  	generic(M		: integer	:= 326 
	);
   	
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		s_tick		: out 	std_logic  
   	);
end component baud_gen;

component buf_reg is
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		clr_flag	: in 	std_logic;
		set_flag	: in 	std_logic; 
      		din		: in 	std_logic_vector(7 downto 0);
      		dout		: out	std_logic_vector(7 downto 0);
      		flag		: out 	std_logic
   	);
end component buf_reg;

component txb_save is
	port(	clk		: in	std_logic;
		reset		: in	std_logic;
      		clr_flag	: in	std_logic;
		set_flag	: in	std_logic;
		set_flag_e	: in	std_logic;
      		ena_e		: in	std_logic; 
      		din		: in	std_logic_vector(7 downto 0);
      		din_e		: in	std_logic_vector(7 downto 0);
      		dout		: out	std_logic_vector(7 downto 0);
      		flag		: out	std_logic
	);
end component txb_save;

component data_validate is
	port(	clk		: in	std_logic;
		reset		: in	std_logic;
		data_in		: in	std_logic_vector(7 downto 0);
		flag_in		: in	std_logic;
		s_clk		: in	std_logic;

		data_out	: out	std_logic_vector(7 downto 0);
		set_dflag	: out	std_logic;
		instr_out	: out	std_logic_vector(7 downto 0);
		set_iflag	: out	std_logic;
		en_instr	: out	std_logic
	);
end component data_validate;

component uart_rx is
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		rx		: in 	std_logic;  
      		s_tick		: in 	std_logic;  
      		rx_done_tick	: out	std_logic;  
      		dout		: out	std_logic_vector(7 downto 0)  
   	);
end component uart_rx ;

component uart_tx is
 	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		tx_start	: in 	std_logic;  
      		s_tick		: in 	std_logic;  
      		din		: in 	std_logic_vector(7 downto 0);  
      		tx_done_tick	: out 	std_logic;  
      		tx		: out 	std_logic  
   	);
end component uart_tx ;

signal s_tick : std_logic;
signal rx_done_tick, tx_done_tick, tx_start, val_done_tick : std_logic;
signal rx_dout, tx_din, instr_val, val_out: std_logic_vector(7 downto 0);
signal enable, flag_val: std_logic;
 
begin
baud_gen1:	baud_gen	port map(	clk		=>clk,
						reset		=>reset,
      						s_tick		=>s_tick
				);

buf_reg_rx:	buf_reg 	port map(	clk		=>clk,
						reset		=>reset,
      						clr_flag	=>data_read,
						set_flag	=>val_done_tick,
      						din		=>val_out,
      						dout		=>D_received,
      						flag		=>data_rdy
   				);

buf_reg_tx:	 txb_save	port map(	clk		=>clk,
						reset		=>reset,
      						clr_flag	=>tx_done_tick,
						set_flag	=>send_data,
      						din		=>D_transmit,
      						dout		=>tx_din,
      						flag		=>tx_start,
						set_flag_e	=>flag_val,
						din_e		=>instr_val,
						ena_e		=>enable
   				);

data_validate1: data_validate	port map(	clk		=> clk,
						reset		=> reset,
						data_in		=> rx_dout,
						flag_in		=> rx_done_tick,
						s_clk		=> s_tick,

						data_out	=> val_out,
						set_dflag	=> val_done_tick,
						instr_out	=> instr_val,
						set_iflag	=> flag_val,
						en_instr	=> enable
				);	

uart_rx1:	uart_rx		port map(	clk		=>clk,
						reset		=>reset,
      						rx		=>rx,
      						s_tick		=>s_tick,
      						rx_done_tick	=>rx_done_tick,
   				   		dout		=>rx_dout
   				);

uart_tx1:	uart_tx		port map(	clk		=>clk,
						reset		=>reset,
      						tx_start	=>tx_start,
      						s_tick		=>s_tick,   
						din		=>tx_din,
      						tx_done_tick	=>tx_done_tick, 
      						tx		=>tx
   				);


end architecture structural_save;

architecture structural_save_2 of uart is

component baud_gen is
  	generic(M		: integer	:= 326 -- baud rate divisor M = 50M/(16*9600)
	);
   	
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		s_tick		: out 	std_logic -- sampling tick
   	);
end component baud_gen;

component buf_reg is
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		clr_flag	: in 	std_logic;
		set_flag	: in 	std_logic; 
      		din		: in 	std_logic_vector(7 downto 0);
      		dout		: out	std_logic_vector(7 downto 0);
      		flag		: out 	std_logic
   	);
end component buf_reg;

component buf_reg_tx is
   	port(
     		clk, reset: in std_logic;
      		clr_flag, set_flag: in std_logic; 
      		din: in std_logic_vector(7 downto 0);
      		dout: out std_logic_vector(7 downto 0);
      		flag: out std_logic
   	);
end component buf_reg_tx;

component uart_rx is
	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		rx		: in 	std_logic; -- icoming serial bit stream
      		s_tick		: in 	std_logic; -- sampling tick from baud rate generator
      		rx_done_tick	: out	std_logic; -- data frame completion tick
      		dout		: out	std_logic_vector(7 downto 0) -- data byte
   	);
end component uart_rx ;

component uart_tx is
 	port(	clk		: in	std_logic;
		reset		: in 	std_logic;
      		tx_start	: in 	std_logic; -- if '1' transmission starts
      		s_tick		: in 	std_logic; -- sampling tick from baud rate generator
      		din		: in 	std_logic_vector(7 downto 0); -- incoming data byte
      		tx_done_tick	: out 	std_logic; -- data frame completion tick 
      		tx		: out 	std_logic -- outcoming bit stream
   	);
end component uart_tx ;

signal s_tick : std_logic;
signal rx_done_tick, tx_done_tick, tx_start : std_logic;
signal rx_dout, tx_din : std_logic_vector(7 downto 0);
 
begin
baud_gen1:	baud_gen	port map(	clk		=>clk,
						reset		=>reset,
      						s_tick		=>s_tick
				);

buf_reg_rx:	buf_reg 	port map(	clk		=>clk,
						reset		=>reset,
      						clr_flag	=>data_read,
						set_flag	=>rx_done_tick,
      						din		=>rx_dout,
      						dout		=>D_received,
      						flag		=>data_rdy
   				);

buf_reg_tx_lbl:	buf_reg_tx 	port map(	clk		=>clk,
						reset		=>reset,
      						clr_flag	=>tx_done_tick,
						set_flag	=>send_data,
      						din		=>D_transmit,
      						dout		=>tx_din,
      						flag		=>tx_start
   				);

uart_rx1:	uart_rx		port map(	clk		=>clk,
						reset		=>reset,
      						rx		=>rx,
      						s_tick		=>s_tick,
      						rx_done_tick	=>rx_done_tick,
   				   		dout		=>rx_dout
   				);

uart_tx1:	uart_tx		port map(	clk		=>clk,
						reset		=>reset,
      						tx_start	=>tx_start,
      						s_tick		=>s_tick,   
						din		=>tx_din,
      						tx_done_tick	=>tx_done_tick, 
      						tx		=>tx
   				);


end architecture structural_save_2;