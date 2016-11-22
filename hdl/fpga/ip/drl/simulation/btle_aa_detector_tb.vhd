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

    signal bits: std_logic := '0';
	signal bits_valid: std_logic := '0';

    signal detect_result: std_logic := '0';
	signal out_seq: std_logic := '0';
	signal out_valid: std_logic := '0';
	
begin
    duv: entity work.btle_aa_detector 
    port map(
    	clock => clock,
    	reset => reset,
        in_seq => bits,
        in_valid => bits_valid,
        out_detect => detect_result,
        out_seq => out_seq,
        out_valid => out_valid );

    clock <= not clock after 500 ns;
    reset <= '1', '0' after 20 ns;

    stimulus: 
    process
		variable RV : RandomPType;
		variable random_iter : integer;
    	begin
			test_runner_setup(runner, runner_cfg);

			RV.InitSeed(RV'instance_name);

			bits <= '0';
			bits_valid <= '0'; 
			
		   	wait until not reset;
			wait until rising_edge(clock);

			-- Send a long burst of random samples

			random_iter := RV.RandInt(500,1000);

			report("Simulating for " & to_string(random_iter) & " iterations without AA");
			
			for i in 0 to random_iter loop
				wait until rising_edge(clock);
				
				bits <= RV.RandSlv(0, 1, 1)(0); 
				bits_valid <= '1';

				assert detect_result = '0' report "False detect!" severity failure;
			end loop;

			-- Send the real Advertising Access Address + Preamble

			report("Sending Access Addres BED6...");

			for i in BTLE_BED6'range loop
				wait until rising_edge(clock);

				bits <= BTLE_BED6(i);
				bits_valid <= '1';

				assert detect_result = '0' report "False detect!" severity failure;
			end loop;

			wait until rising_edge(clock);	-- clock in the final bit of the real AA
			wait until rising_edge(clock);	-- clock out the result

			assert detect_result = '1' report "Missed detection!" severity failure;

			report("...BED6 detected!");
			
			random_iter := RV.RandInt(500,1000);

			report("Simulating for " & to_string(random_iter) & " iterations without AA");

			for i in 0 to random_iter loop
				wait until rising_edge(clock);
				
				bits <= RV.RandSlv(0, 1, 1)(0); 
				bits_valid <= '1';

				assert detect_result = '0' report "False detect!" severity failure;
			end loop;

			wait until rising_edge(clock);
			bits_valid <= '0';
	
        	report("End of testbench. All tests passed.");
        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process; 
end;