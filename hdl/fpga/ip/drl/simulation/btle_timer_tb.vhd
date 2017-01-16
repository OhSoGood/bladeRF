--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity btle_timer_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_timer_tb is
	
    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    signal enable: std_logic := '0';
    signal out_expiry: std_logic := '0';

	constant DURATION : integer := 97;
	constant REPETITIONS : integer := 103;

begin

    duv: entity work.btle_timer 
	 generic map(duration => DURATION, reload => true)
     port map(
    	clock => clock,
    	reset => reset,
		enable => enable,
        out_expiry => out_expiry
        );

    clock <= not clock after 15.625 ns;
    reset <= '1', '0' after 200 ns;

    stimulus: 
    process
    	variable count : integer := 0;
    	variable cycle : integer := 0;
    	
    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until not reset;
			wait until rising_edge(clock);
			wait until rising_edge(clock);

			enable <= '1';

			for x in 0 to REPETITIONS - 1 loop

				wait until rising_edge(clock);
				assert out_expiry = '0' report "Failed to reset reloading counter"  severity failure;
			
				while out_expiry = '0' loop
					count := count + 1;			
					wait until rising_edge(clock);
				end loop;
			
				assert count = DURATION report "Failed to expire after " & to_string(count) & " cycles, repetition " & to_string(x) severity failure;

				count := 1;
			
			end loop;

		    report("End of testbench. All tests passed.");
        	test_runner_cleanup(runner);
        	std.env.finish;
			
    	end 
    process; 

end;
