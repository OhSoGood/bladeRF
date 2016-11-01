--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

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

		out_detected:   buffer std_logic;
		out_real:		out signed(15 downto 0);
		out_imag:		out signed(15 downto 0);
		out_valid:      out std_logic
	);
end btle_channel_receiver;


architecture rtl of btle_channel_receiver is

	signal newest_sample_real : std_logic_vector(15 downto 0) := (others => '0');
	signal newest_sample_imag : std_logic_vector(15 downto 0) := (others => '0');

	signal demod_sample_real  : std_logic_vector(15 downto 0);
	signal demod_sample_imag  : std_logic_vector(15 downto 0);
	
	signal oldest_sample_real : std_logic_vector(15 downto 0);
	signal oldest_sample_imag : std_logic_vector(15 downto 0);
	
	signal demod_real: signed(15 downto 0) := (others => '0');
	signal demod_imag: signed(15 downto 0) := (others => '0');
	signal demod_valid: std_logic := '0';

    signal bits: std_logic := '0';
    signal bits_valid: std_logic := '0';
    signal detection : std_logic := '0';

begin

	delay_real:
	entity work.btle_delay_line
	generic map( W => 16, L => BTLE_MEMORY_LEN, T => BTLE_DEMOD_TAP_POSITION )
	port map (
		clock => clock,
		sync_reset => reset,
		in_data => newest_sample_real,
		out_data => oldest_sample_real,
		out_data_tap => demod_sample_real
	);
	
	
	delay_imag:
	entity work.btle_delay_line
	generic map( W => 16, L => BTLE_MEMORY_LEN, T => BTLE_DEMOD_TAP_POSITION )		
	port map (
		clock => clock,
		sync_reset => reset,
		in_data => newest_sample_imag,
		out_data => oldest_sample_imag,
		out_data_tap => demod_sample_imag
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
	
		begin
			if reset = '1' then

				newest_sample_real <= (others => '0');
				newest_sample_imag <= (others => '0');
				
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
					
 					newest_sample_real <=  std_logic_vector(in_real);	
  					newest_sample_imag <=  std_logic_vector(in_imag);	
					
					demod_real <= signed(demod_sample_real);
					demod_imag <= signed(demod_sample_imag);

					out_real <= signed(oldest_sample_real);
					out_imag <= signed(oldest_sample_imag);
				
					demod_valid <= '1';
  					out_valid <= '1';

				end if;

				out_detected <= detection;
				
			end if;
		end 
	process;
end rtl;




