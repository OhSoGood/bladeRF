--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.btle_common.all;
use work.btle_fft.all;
use work.btle_window.all;

entity btle_rx_lineup_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_rx_lineup_tb is

	signal iq_enable: std_logic := '0';
	signal iq_done: std_logic := '0';

	signal clock: std_logic := '0';
	signal reset: std_logic := '0';

	signal in_iq_bus: iq_bus_t;
	signal out_iq_bus: tdm_iq_bus_t;
	
begin


	iq: entity work.btle_iq_streamer 
	generic map(filepath => "simulation\\" & "basic_fft_in.txt")
	port map(
		clock => clock,
		reset => reset,
		enable => iq_enable,
		out_iq_bus => in_iq_bus,
		iq_done => iq_done
	);

	dut: entity work.btle_fft_streamer
	generic map (order => 16, fft_type => BTLE_FFT_SPIRAL)
	port map (
		clock => clock,
		reset => reset,
		enable => '1',
		in_iq_bus => in_iq_bus,
		in_fft_window => BTLE_WINDOW_NONE,
		out_iq_bus => out_iq_bus
	);


    clock <= not clock after 15.625 ns;
    reset <= '1', '0' after 100 ns;
    
    stimulus: 
    process
		variable v : integer := 0;
    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until reset = '0';
			wait until rising_edge(clock);

			iq_enable <= '1';

			wait until rising_edge(iq_done);
			for i in 1 to 2000  loop
 				wait until rising_edge(clock);
 			end loop;

 			report("End of testbench. All tests passed.");

        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process; 


end;
