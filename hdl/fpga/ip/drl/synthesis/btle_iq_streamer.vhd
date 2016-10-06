--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity btle_iq_streamer is
	generic(filepath : string);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		enable:			in std_logic;

		-- output iq signal
		iq_real:		out signed(15 downto 0);
		iq_imag:		out signed(15 downto 0);
		iq_valid:       out std_logic;
		iq_done:   	    out std_logic
	);
end btle_iq_streamer;


architecture testbench of btle_iq_streamer is
begin
	iq_streamer:
	process(clock, reset) is

    	file tx_samples: text open read_mode is filepath;
    	variable current_line : line;
    	variable sample_i: integer;
    	variable sample_q: integer;
	
		begin
			if reset = '1' then

				iq_real <= to_signed(0, 16); 
				iq_imag <= to_signed(0, 16);
				iq_valid <= '0';
				iq_done <= '0';

			elsif rising_edge(clock) then

				iq_valid <= '0';

				if enable = '1' then
					if not endfile(tx_samples) then
						readline(tx_samples, current_line);
						read(current_line, sample_i);
						read(current_line, sample_q);
				
						iq_real <= to_signed(sample_i, 16);
						iq_imag <= to_signed(sample_q, 16);
						iq_valid <= '1';
					else
						iq_done <= '1';
					end if;
				end if;
			end if;
		end
	process;
end testbench ;



