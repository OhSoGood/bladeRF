--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity btle_iq_tracer is

    generic(
        INPUT_WIDTH : positive := 16;
        OUTPUT_WIDTH: positive := 16
 	);

	port(
		clock:			in std_logic;
		reset:			in std_logic;

		in_real:		in signed(INPUT_WIDTH - 1 downto 0);
		in_imag:		in signed(INPUT_WIDTH - 1 downto 0);
		in_valid:		in std_logic;

		out_real:		out signed(OUTPUT_WIDTH - 1 downto 0);
		out_imag:		out signed(OUTPUT_WIDTH - 1 downto 0);
		out_valid:      out std_logic
	);
end btle_iq_tracer;



architecture rtl of btle_iq_tracer is
begin
	tracer:
	process(clock, reset) is

    	variable c: integer;
	
		begin
			if reset = '1' then

				out_real <= to_signed(0, OUTPUT_WIDTH); 
				out_imag <= to_signed(0, OUTPUT_WIDTH);
				out_valid <= '0';

				c := 0;
			elsif rising_edge(clock) then

				out_valid <= '0';

				if in_valid = '1' then

					c := c + 1;
				
					if c = 16 then
						out_real <= to_signed(43690, OUTPUT_WIDTH);
						out_imag <= to_signed(21845, OUTPUT_WIDTH);
						c := 0;
					else
						out_real <= in_real;
						out_imag <= in_imag;
					end if;

					out_valid <= '1';
					
				end if;
			end if;
		end
	process;
end rtl ;

