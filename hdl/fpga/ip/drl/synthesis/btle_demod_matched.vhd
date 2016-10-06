--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_complex.all;

entity btle_demod_matched is
	generic(
		samples_per_bit : natural := 2
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;

		-- input signal
		in_real:		in signed(15 downto 0);
		in_imag:		in signed(15 downto 0);
		in_valid:       in std_logic;

		-- output bits
		out_bit:		out std_logic := '0';
		out_valid:		out std_logic := '0'
	);
end btle_demod_matched;


architecture rtl of btle_demod_matched is

	type filter_ref_type is record
		f_upper: complex_i16;
		f_lower: complex_i16;
	end record;
	
	type filter_ref_array_type is array (natural range <>) of
		filter_ref_type;

	constant FILTER_REF: filter_ref_array_type := (
    	( (8192,    0), (8192,     0) ),
		( (5792, 5792), (5792, -5792) )    	
	);


begin
	matched_filter: 
	process(clock, reset) is

		variable phase : natural range 0 to samples_per_bit;
		variable new_sample : complex_i16;

		variable sum_lower : complex_i32;
		variable sum_upper : complex_i32;

		variable upper_sq : uint32;
		variable lower_sq : uint32;

		begin
			if reset = '1' then
			
				phase := 0;
				sum_upper := (0, 0);
				sum_lower := (0, 0);

				out_bit <= '0';
				out_valid <= '0';
				
			elsif rising_edge(clock) then

				if in_valid = '1' then
				
					new_sample := (to_integer(in_real), to_integer(in_imag));			
					sum_upper := sum_upper + mul(new_sample, FILTER_REF(phase).f_upper, 13);
					sum_lower := sum_lower + mul(new_sample, FILTER_REF(phase).f_lower, 13);

					phase := phase + 1;
					
					out_valid <= '0';
					
					if phase = samples_per_bit then

						upper_sq := sum_upper.real * sum_upper.real + sum_upper.imag * sum_upper.imag;
						lower_sq := sum_lower.real * sum_lower.real + sum_lower.imag * sum_lower.imag;

						out_bit <= '0';
						
						if(upper_sq < lower_sq) then
							out_bit <= '1';
						end if;

						out_valid <= '1';

						phase := 0;
						sum_upper := (0, 0);
						sum_lower := (0, 0);	
					end if;
				end if;
			end if;
		end 
	process;
end rtl;

