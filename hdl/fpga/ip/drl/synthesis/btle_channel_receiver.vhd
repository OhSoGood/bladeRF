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

		in_cts:         in std_logic;
		out_rts:        out std_logic;
		
		out_detected:   buffer std_logic;
		out_real:		out signed(15 downto 0);
		out_imag:		out signed(15 downto 0);
		out_valid:      out std_logic
	);
end btle_channel_receiver;


architecture rtl of btle_channel_receiver is

	type ch_state_type is ( STATE_WAIT_DETECT, STATE_WAIT_CTS, STATE_COUNTDOWN );
	signal state : ch_state_type;

	signal memory_clock_en : std_logic;
	signal memory_sample_valid : std_logic;

	signal newest_sample : std_logic_vector(31 downto 0) := (others => '0');
	signal demod_sample  : std_logic_vector(31 downto 0);	
	signal oldest_sample : std_logic_vector(31 downto 0);
	
	signal demod_real: signed(15 downto 0) := (others => '0');
	signal demod_imag: signed(15 downto 0) := (others => '0');
	signal demod_valid: std_logic := '0';

    signal bits: std_logic := '0';
    signal bits_valid: std_logic := '0';
    signal detection : std_logic := '0';

begin

	delay_iq:
	entity work.btle_delay_line
	generic map( W => 32, L => BTLE_MEMORY_LEN, T => BTLE_DEMOD_TAP_POSITION )
	port map (
		clock => clock,
		clock_en => memory_clock_en,
		sync_reset => reset,
		in_data => newest_sample,
		out_valid => memory_sample_valid,
		out_data => oldest_sample,
		out_data_tap => demod_sample
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

	memory_in: 
	process(clock, reset) is
		begin
			if reset = '1' then

				newest_sample <= (others => '0');
				
				out_detected <= '0';

				memory_clock_en <= '0';
				
			elsif rising_edge(clock) then

				memory_clock_en <= '0';

				if in_valid = '1' then		
					
 					newest_sample <=  std_logic_vector(in_real & in_imag);				
					memory_clock_en <= '1';

				end if;

				out_detected <= detection;
				
			end if;
		end 
	process;


	memory_to_demod:
	process(clock, reset) is
		begin
			if reset = '1' then

				demod_real <= (others => '0');
				demod_imag <= (others => '0');
				demod_valid <= '0';
				
			elsif rising_edge(clock) then

				demod_valid <= '0';
				
				if memory_sample_valid = '1' then
				
					demod_real <= signed(demod_sample (31 downto 16));
					demod_imag <= signed(demod_sample (15 downto  0));
					demod_valid <= '1';	

				end if;

			end if;
		end
	process;



--	state_fsm:
--	process(clock, reset) is
--		begin
--			if reset = '1' then
--				state <= STATE_WAIT_DETECT;
--			elsif rising_edge(clock) then
--				case state is
--					when STATE_WAIT_DETECT =>
--
--			
--				state <= state_next;
--			end if;
--		end
--	process;

	state_fsm:
	process(clock, reset) is

		variable countdown: integer := 0;
		begin

			if reset = '1' then
			
				out_rts <= '0';
				out_real <= (others => '0');
				out_imag <= (others => '0');
				out_valid <= '0';
				state <= STATE_WAIT_DETECT;
				
			elsif rising_edge(clock) then
					
				case state is
					when STATE_WAIT_DETECT =>

						out_rts <= '0';
						out_real <= (others => '0');
						out_imag <= (others => '0');
						out_valid <= '0';
						
						if detection = '1' then

							out_rts <= '1';
							state <= STATE_WAIT_CTS;
	
						end if;

					when STATE_WAIT_CTS =>

						out_rts <= '1';
						out_real <= (others => '0');
						out_imag <= (others => '0');
						out_valid <= '0';	

						if in_cts = '1' then
						
							out_real <= x"AAAA";
							out_imag <= x"5555";
							out_valid <= '1';
							state <= STATE_COUNTDOWN;

							countdown := BTLE_MEMORY_LEN;
 
						end if;

					when STATE_COUNTDOWN =>

						out_rts <= '1';
						out_valid <= '0';

						if memory_sample_valid = '1' then

							out_real <= signed(oldest_sample (31 downto 16));
							out_imag <= signed(oldest_sample (15 downto  0));
							out_valid <= '1';

							countdown := countdown - 1;
							
						end if;

						if countdown = 0 then
						
							state <= STATE_WAIT_DETECT;

						end if;

					when others =>
					
						out_rts <= '0';
						out_real <= (others => '0');
						out_imag <= (others => '0');
						out_valid <= '0';
						state <= STATE_WAIT_DETECT;
				
				end case;

			end if;
		end
	process;

	
end rtl;




