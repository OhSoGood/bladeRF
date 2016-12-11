--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
library osvvm;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use osvvm.RandomPkg.all;

use work.btle_common.all;

entity btle_aa_detector_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_aa_detector_tb is

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';

    signal input_seq: tdm_bit_bus_t;
    signal input_ch_info: btle_ch_info_t;
	signal aa_cfg: aa_config_t;

    signal output_ch_info: btle_ch_info_t;
	signal output_seq: tdm_bit_bus_t;
    signal aa_detect_results: aa_detect_results_t;

	
begin
    duv: entity work.btle_aa_detector 
	generic map(num_timeslots => 16, max_addresses => BTLE_MAXIMUM_AA_MEMORY)
    port map (
    	clock => clock,
    	reset => reset,

        in_bit_bus => input_seq,
        in_ch_info => input_ch_info,
		in_cfg => aa_cfg,
        
		out_bit_bus => output_seq,
		out_ch_info => output_ch_info,
		out_detect_results => aa_detect_results
    );

    clock <= not clock after 500 ns;
    reset <= '1', '0' after 20 ns;

    stimulus: 
    process
		variable RV : RandomPType;
		variable random_iter : integer;
    	begin
			test_runner_setup(runner, runner_cfg);

			RV.InitSeed(RV'instance_name);

			aa_cfg.valid <= '0';
			aa_cfg.preamble_aa <= (others => '0');

			input_seq.seq <= '0';
			input_seq.valid <= '0';
			input_seq.timeslot <= to_unsigned(15, timeslot_t'length);

			input_ch_info.valid <= '1';
			input_ch_info.adv <= '1';
			input_ch_info.ch_idx <= to_unsigned(37, input_ch_info.ch_idx'length);
			
		   	wait until not reset;
			wait until rising_edge(clock);

			-- Send a long burst of random samples

			random_iter := RV.RandInt(500,1000);

			report("Simulating for " & to_string(random_iter) & " iterations without AA");
			
			for i in 0 to random_iter loop
				wait until rising_edge(clock);
				
				input_seq.seq <= RV.RandSlv(0, 1, 1)(0); 
				input_seq.valid <= '1';

				assert aa_detect_results.detected = '0' report "False detect!" severity failure;
			end loop;

			-- Send the real Advertising Access Address + Preamble

			report("Sending Access Addres BED6...");

			for i in BTLE_BED6'range loop
				wait until rising_edge(clock);

				input_seq.seq <= BTLE_BED6(i);
				input_seq.valid <= '1';

				assert aa_detect_results.detected = '0' report "False detect!" severity failure;
			end loop;

			wait until rising_edge(clock);	-- clock in the final bit of the real AA
			wait until rising_edge(clock);	-- clock out the result

			assert aa_detect_results.detected = '1' report "Missed detection!" severity failure;
			assert aa_detect_results.preamble_aa = "0101010101101011011111011001000101110001" report "Incorrect Preamble/AA" severity failure;

			report("...BED6 detected!");
			
			random_iter := RV.RandInt(500,1000);

			report("Simulating for " & to_string(random_iter) & " iterations without AA");

			for i in 0 to random_iter loop
				wait until rising_edge(clock);
				
				input_seq.seq <= RV.RandSlv(0, 1, 1)(0); 
				input_seq.valid <= '1';

				assert aa_detect_results.detected = '0' report "False detect!" severity failure;
			end loop;

			wait until rising_edge(clock);
			input_seq.valid <= '0';
	
        	report("End of testbench. All tests passed.");
        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process; 
end;