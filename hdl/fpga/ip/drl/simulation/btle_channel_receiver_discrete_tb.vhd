--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.btle_common.all;

entity btle_channel_receiver_discrete_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;

architecture testbench of btle_channel_receiver_discrete_tb is
	constant TB_DATA_PATH: string := "simulation/";

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';

	signal iq_enable : std_logic := '0';
    signal iq_real: signed(15 downto 0) := to_signed(0, 16);
    signal iq_imag: signed(15 downto 0) := to_signed(0, 16);
	signal iq_valid: std_logic := '0';
	signal iq_complete : std_logic := '0';
	
    signal bits: std_logic := '0';
    signal bits_valid: std_logic := '0';

    signal detection : std_logic := '0';
 	signal preamble_aa: std_logic_vector (BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 1 downto 0);
 	
	shared variable detections : integer := 0;
begin

	iq: entity work.btle_iq_streamer 
	generic map(filepath => TB_DATA_PATH & "aa_samples.txt")
	port map(
		clock => clock,
		reset => reset,
		enable => iq_enable,
		iq_real => iq_real,
		iq_imag => iq_imag,
		iq_valid => iq_valid,
		iq_done => iq_complete
	);

    demod: entity work.btle_demod_matched 
	generic map( samples_per_bit => 2, max_channels => 16)
    port map(
    	clock => clock,
    	reset => reset,
        in_real => iq_real,
        in_imag => iq_imag,
        in_valid => iq_valid,
        in_fft_idx => to_unsigned(0, 5),
        out_bit => bits,
        out_valid => bits_valid,
        out_fft_idx => open);

   detect: entity work.btle_aa_detector 
   generic map(num_channels => 1, num_addresses => BTLE_MAXIMUM_AA_MEMORY)
   port map(
     	clock => clock,
    	reset => reset,
		in_seq => bits,
		in_valid => bits_valid,
		in_ch_index => 0,
		in_preamble_aa => (others => '0'),
		in_aa_valid => '0',
		out_preamble_aa => preamble_aa,
		out_detected => detection);
		
    clock <= not clock after 500 ns;
    reset <= '1', '0' after 20 ns;

    stimulus: 
    process
    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until not reset;

			iq_enable <= '1';
			wait until iq_complete;
			iq_enable <= '0';

			assert detections = 1 report "Failed to detect exactly 1 AA burst"  severity failure;
			assert preamble_aa = "0101010101101011011111011001000101110001" report "Incorrect Preamble/AA" severity failure;
		
        	report("End of testbench. All tests passed.");
        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process;

	checker:
	process(clock, reset)
		variable sample_index : integer := 0;
		begin
			if reset = '1' then

				sample_index := 0;
				detections := 0;

			elsif rising_edge(clock) then

				if iq_valid = '1' then
					sample_index := sample_index + 1;
				end if;
				
				if detection = '1' then
					detections := detections + 1;
					 report "Detected AA at sample: " & to_string(sample_index) & ". Total=" & to_string(detections);
				end if;
				
			end if;
		end
	process;  
end;
