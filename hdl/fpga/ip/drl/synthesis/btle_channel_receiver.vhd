library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_complex.all;
use work.btle_common.all;
--use work.btle_delay_line.all;

entity btle_channel_receiver is
	generic(
		samples_per_bit : natural := 2
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;

		in_real:		in signed(15 downto 0);
		in_imag:		in signed(15 downto 0);
		in_valid:       in std_logic;

		out_real:		out signed(15 downto 0);
		out_imag:		out signed(15 downto 0);
		out_valid:      out std_logic
	);
end btle_channel_receiver;


architecture rtl of btle_channel_receiver is

	signal demod_real:	signed(15 downto 0) := (others => '0');
	signal demod_imag: signed(15 downto 0) := (others => '0');
	signal demod_valid: std_logic := '0';

    signal bits: std_logic := '0';
    signal bits_valid: std_logic := '0';
    signal detection : std_logic := '0';

	type sample_array_type is array (851 downto 0) of complex_i16;

begin

	demod: 
	entity work.btle_demod_matched 
	port map(
    	clock => clock,
    	reset => reset,
        in_real => demod_real,
        in_imag => demod_imag,
        in_valid => demod_valid,
        out_bit => bits,
        out_valid => bits_valid
  	);

   	detect: 
   	entity work.btle_aa_detector 
   	port map(
    	clock => clock,
    	reset => reset,
		in_bit => bits,
		in_valid => bits_valid,
		out_detect => detection
	);

	receiver: 
	process(clock, reset) is

		variable sample_memory: sample_array_type;
		variable new_sample : complex_i16;
		
		begin
			if reset = '1' then
			
				out_real <= (others => '0');
				out_imag <= (others => '0');
				out_valid <= '0';

				demod_real <= (others => '0');
				demod_imag <= (others => '0');
				demod_valid <= '0';
				
			elsif rising_edge(clock) then

				out_valid <= '0';
				demod_valid <= '1';
				
				if in_valid = '1' then		

					-- 'low' (index [0]) is the oldest sample
					-- 'high' is the newest sample
					out_real <= to_signed(sample_memory(sample_memory'low).real, 16);
  					out_imag <= to_signed(sample_memory(sample_memory'low).imag, 16);

					demod_real <= to_signed(sample_memory(65).real, 16);
					demod_imag <= to_signed(sample_memory(65).imag, 16);				
			
  					new_sample := (to_integer(in_real), to_integer(in_imag));	
  					sample_memory := new_sample & sample_memory(sample_memory'high downto 1);

  					out_valid <= '1';
  					
				end if;
			end if;
		end 
	process;
end rtl;




