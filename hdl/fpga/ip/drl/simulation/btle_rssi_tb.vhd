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

entity btle_rssi_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_rssi_tb is

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';

	signal in_bus: iq_bus_t;
	signal in_report : std_logic := '0';

    signal out_results:     rssi_results_t;

begin
    duv: entity work.btle_rssi 
	generic map( max_timeslots => 2)
    port map(
    	clock => clock,
    	reset => reset,

        in_iq_bus.valid => in_bus.valid,
        in_iq_bus.real => in_bus.real,
       	in_iq_bus.imag => in_bus.imag,
       	in_iq_bus.timeslot => to_unsigned(0, 5),
		in_report => in_report,
		in_clipped => '0',
		in_detect => '0',
		out_results => out_results
 	);

    clock <= not clock after 500 ns;
    reset <= '1', '0' after 20 ns;

    stimulus: 
    process

    	begin
			test_runner_setup(runner, runner_cfg);

			in_report <= '0';
			in_bus.valid <= '0';
			in_bus.real <= to_signed(0, 16);
			in_bus.imag <= to_signed(0, 16);		
			
		   	wait until not reset;

			in_bus.valid <= '1';

			for i in 0 to 1000 loop
				wait until rising_edge(clock);
			end loop;

			in_bus.real <= to_signed(1, 16);
			in_bus.imag <= to_signed(1, 16);		

			in_report <= '1';
			wait until rising_edge(clock);
			in_report <= '0';

			wait until rising_edge(clock) and out_results.valid = '1';
			
			assert out_results.rssi = 0 report "Failed to compuute RSSI as 0 from all zero inputs"  severity failure;
			assert out_results.clipped = '0' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(0, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;

			wait until rising_edge(clock);

			assert out_results.valid = '1' report "out_valid was not maintained"  severity failure; 
			assert out_results.rssi = 0 report "Failed to compuute RSSI as 0 from all zero inputs"  severity failure;
			assert out_results.clipped = '0' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(1, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;
			
			for i in 0 to 1000 loop
				wait until rising_edge(clock);
			end loop;

			in_bus.real <= to_signed(30, 16);
			in_bus.imag <= to_signed(30, 16);	

			in_report <= '1';
			wait until rising_edge(clock);
			in_report <= '0';

			wait until rising_edge(clock) and out_results.valid = '1';

			assert out_results.rssi = 1 report "Failed to compuute RSSI as 1 from all one inputs"  severity failure;
			assert out_results.clipped = '0' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(0, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;

			wait until rising_edge(clock);
			
			assert out_results.valid = '1' report "out_valid was not maintained"  severity failure; 
			assert out_results.rssi = 0 report "Failed to compuute RSSI as 0 from all zero inputs"  severity failure;
			assert out_results.clipped = '0' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(1, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;

			for i in 0 to 1000 loop
				wait until rising_edge(clock);
			end loop;

			in_bus.real <= to_signed(2047, 16);
			in_bus.imag <= to_signed(2047, 16);	

			in_report <= '1';
			wait until rising_edge(clock);
			in_report <= '0';

			wait until rising_edge(clock) and out_results.valid = '1';

			assert out_results.rssi = 900 report "Failed to compuute RSSI as 900 from all 30's inputs"  severity failure;
			assert out_results.clipped = '0' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(0, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;

			wait until rising_edge(clock);

			assert out_results.valid = '1' report "out_valid was not maintained"  severity failure; 
			assert out_results.rssi = 0 report "Failed to compuute RSSI as 0 from all zero inputs"  severity failure;
			assert out_results.clipped = '0' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(1, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;
			
			for i in 0 to 1000 loop
				wait until rising_edge(clock);
			end loop;

			in_bus.real <= to_signed(-2048, 16);
			in_bus.imag <= to_signed(-2048, 16);	

			in_report <= '1';
			wait until rising_edge(clock);
			in_report <= '0';

			wait until rising_edge(clock) and out_results.valid = '1';

			assert out_results.rssi = 2047*2047 report "Failed to compuute RSSI as 2047^2 from all 2047's inputs"  severity failure;
			assert out_results.clipped = '1' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(0, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;

			wait until rising_edge(clock);

			assert out_results.valid = '1' report "out_valid was not maintained"  severity failure; 
			assert out_results.rssi = 0 report "Failed to compuute RSSI as 0 from all zero inputs"  severity failure;
			assert out_results.clipped = '0' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(1, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;

			for i in 0 to 1000 loop
				wait until rising_edge(clock);
			end loop;

			in_bus.real <= to_signed(0, 16);
			in_bus.imag <= to_signed(0, 16);	

			in_report <= '1';
			wait until rising_edge(clock);
			in_report <= '0';

			wait until rising_edge(clock) and out_results.valid = '1';

			assert out_results.rssi = (2048 * 2048) report "Failed to compuute RSSI as -2048^2 from all -2048's inputs"  severity failure;
			assert out_results.clipped = '1' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(0, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;

			wait until rising_edge(clock);

			assert out_results.valid = '1' report "out_valid was not maintained"  severity failure; 
			assert out_results.rssi = 0 report "Failed to compuute RSSI as 0 from all zero inputs"  severity failure;
			assert out_results.clipped = '0' report "False positive for clipping detection"  severity failure;
			assert out_results.timeslot = to_unsigned(1, out_results.timeslot'length) report "Wrong timeslot: " & to_string(out_results.timeslot)  severity failure;

        	report("End of testbench. All tests passed.");
        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process;

 
end;
