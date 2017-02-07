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

entity btle_rssi_manager_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;



architecture testbench of btle_rssi_manager_tb is

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    
	signal wideband_input : iq_bus_t;
	signal fft_output: tdm_iq_bus_t;

    signal wb_rssi_trigger: std_logic;
    signal nb_rssi_trigger: std_logic;
    signal wb_rssi_results: rssi_results_t;
    signal nb_rssi_results: rssi_results_t;

	signal rts: std_logic;
	signal cts: std_logic;

	signal report_output : iq_bus_t;
	

begin
	w_rssi:
	entity work.btle_rssi
		generic map( 
			max_timeslots => 1
		)
    	port map(
    		clock => clock,
    		reset => reset,
        	in_iq_bus.valid => wideband_input.valid,
        	in_iq_bus.real => wideband_input.real,
            in_iq_bus.imag => wideband_input.imag,
            in_iq_bus.timeslot => (others => '0'),
			in_report => wb_rssi_trigger,
			out_results => wb_rssi_results
 		);

	n_rssi:
	entity work.btle_rssi
		generic map( 
			max_timeslots => 16
		)
    	port map(
    		clock => clock,
    		reset => reset,
        	in_iq_bus.valid => fft_output.valid,
        	in_iq_bus.real => fft_output.real,
            in_iq_bus.imag => fft_output.imag,
            in_iq_bus.timeslot => fft_output.timeslot,
			in_report => nb_rssi_trigger,
			out_results => nb_rssi_results
 		);	

    rssi_mgr:
	entity work.btle_rssi_manager
		generic map(
			max_timeslots => 16,
			reports_per_second => 50	
		)
		port map(
			clock			=> clock,
			reset			=> reset,
			enable32m		=> '1',
			enable2m		=> '1',

			in_timestamp	=> (others => '0'),
			in_rf_config	=> "00",
		
			out_trigger_wb	=> wb_rssi_trigger,
			out_trigger_nb	=> nb_rssi_trigger,
		
			in_wb_results   => wb_rssi_results,
			in_nb_results	=> nb_rssi_results,

			in_cts			=> cts,
			out_rts         => rts,

			out_real		=> report_output.real,
			out_imag		=> report_output.imag,
			out_valid		=> report_output.valid
		);

    clock <= not clock after 500 ns;
    reset <= '1', '0' after 20 ns;


	dummy_fft:
	process(clock, reset) is

		variable ts: integer := 0;

		begin
			if reset = '1' then

				fft_output.valid <= '0';
				fft_output.real <= (others => '0');
				fft_output.imag <= (others => '0');
				fft_output.timeslot <= (others => '0');

				ts := 0;
				
			elsif rising_edge(clock) then

				fft_output.valid <= '0';
				fft_output.real <= (others => '0');
				fft_output.imag <= (others => '0');
				fft_output.timeslot <= (others => '0');
				
				if wideband_input.valid = '1' then

					fft_output.valid <= '1';
					fft_output.real <= to_signed(33, fft_output.real'length);
					fft_output.imag <= to_signed(-33, fft_output.imag'length);
					fft_output.timeslot <= to_unsigned(ts, fft_output.timeslot'length);

					if ts /= 15 then
						ts := ts + 1;
					else
						ts := 0;
					end if;

				end if;

			end if;
		end
	process;


	dummy_output:
	process(clock, reset) is
		begin
			if reset = '1' then

				cts <= '0';
				
			elsif rising_edge(clock) then

				cts <= '0';
				
				if rts = '1' then
					cts <= '1';
				end if;

			end if;
		end
	process;



    stimulus: 
    process

    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until not reset;
		   	
	 		wideband_input.real <= to_signed(10, wideband_input.real'length);
	 		wideband_input.imag <= to_signed(10, wideband_input.imag'length);
	 		wideband_input.valid <= '1';	

			for i in 0 to 64000000 loop
				wait until rising_edge(clock);
			end loop;

        	report("End of testbench. All tests passed.");
        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process;

 
end;

