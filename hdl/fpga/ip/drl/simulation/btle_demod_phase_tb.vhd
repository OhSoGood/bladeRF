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

entity btle_demod_phase_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_demod_phase_tb is
	constant TB_DATA_PATH: string := "simulation/";

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';

	signal iq_enable: std_logic := '0';
	signal iq_complete: std_logic := '0';

	signal iq_bus: iq_bus_t;
	signal bit_bus: tdm_bit_bus_t;
	
    
begin
    duv: entity work.btle_demod_phase 
	generic map( samples_per_bit => 2, max_channels => 1)
    port map(
    	clock => clock,
    	reset => reset,
        in_iq_bus.valid => iq_bus.valid,
        in_iq_bus.real => iq_bus.real,
       	in_iq_bus.imag => iq_bus.imag,
       	in_iq_bus.timeslot => to_unsigned(0, 5),
        out_bit_bus => bit_bus
 	);

	iq: entity work.btle_iq_streamer 
	generic map(filepath => TB_DATA_PATH & "fir_samples_in.txt")
	port map(
		clock => clock,
		reset => reset,
		enable => iq_enable,
		out_iq_bus => iq_bus,
		iq_done => iq_complete
	);

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
			
        	report("End of testbench. All tests passed.");

        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process;

 
end;
