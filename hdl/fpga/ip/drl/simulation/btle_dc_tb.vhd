--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.btle_complex.all;
use work.btle_common.all;

entity btle_dc_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;



architecture testbench of btle_dc_tb is

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    
	signal wb_input : iq_bus_t;
	signal wb_output: iq_bus_t;


begin
	dc:
	entity work.btle_dc
		generic map( 
			LENGTH => 2 ** 16,
			ACCUM => 32
		)
    	port map(
    		clock => clock,
    		reset => reset,
        	in_iq_bus => wb_input,
        	out_iq_bus => wb_output
 		);

    clock <= not clock after 500 ns;
    reset <= '1', '0' after 20 ns;

    stimulus: 
    process

    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until not reset;
		   	
	 		wb_input.real <= to_signed(2047, wb_input.real'length);
	 		wb_input.imag <= to_signed(2047, wb_input.imag'length);
	 		wb_input.valid <= '1';	

			for i in 0 to 2 ** 18 loop
				wait until rising_edge(clock);
			end loop;

        	report("End of testbench. All tests passed.");
        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process;

 
end architecture;

