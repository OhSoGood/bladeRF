library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_complex.all;
use work.btle_common.all;


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

		out_detected:   out std_logic;
		out_real:		out signed(15 downto 0);
		out_imag:		out signed(15 downto 0);
		out_valid:      out std_logic
	);
end btle_channel_receiver;


architecture rtl of btle_channel_receiver is

	signal newest_sample : std_logic_vector(31 downto 0) := (others => '0');
	signal oldest_sample : std_logic_vector(31 downto 0);

	signal demod_real:	signed(15 downto 0) := (others => '0');
	signal demod_imag: signed(15 downto 0) := (others => '0');
	signal demod_valid: std_logic := '0';

    signal bits: std_logic := '0';
    signal bits_valid: std_logic := '0';
    signal detection : std_logic := '0';

	type sample_array_type is array (851 downto 0) of complex_i16;

begin



	delay:
	entity work.btle_delay_line
	generic map( W => 32, L => 852 )
	--generic map( W => 32, L => 8 )
	port map (
		clock => clock,
		sync_reset => reset,
		in_data => newest_sample,
		out_data => oldest_sample
	);

	demod: 
	entity work.btle_demod_matched 
	port map (
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
   	port map (
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

				newest_sample <= (others => '0');

				out_real <= (others => '0');
				out_imag <= (others => '0');
				out_valid <= '0';
				out_detected <= '0';

				demod_real <= (others => '0');
				demod_imag <= (others => '0');
				demod_valid <= '0';
				
			elsif rising_edge(clock) then

				out_valid <= '0';
				demod_valid <= '0';
				
				if in_valid = '1' then		
							
  					newest_sample <=  std_logic_vector(in_imag & in_real);	

					demod_real <= signed(oldest_sample(15 downto 0));
					demod_imag <= signed(oldest_sample(31 downto 16));
	
					out_real <= signed(oldest_sample(15 downto 0));
					out_imag <= signed(oldest_sample(31 downto 16));

					demod_valid <= '1';
  					out_valid <= '1';

					out_detected <= out_detected xor detection;
  					
				end if;
			end if;
		end 
	process;
end rtl;




