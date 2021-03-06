--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.btle_common.all;

entity btle_wideband_receiver_connect_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;

architecture testbench of btle_wideband_receiver_connect_tb is
	constant TB_DATA_PATH: string := "simulation/";

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';

	signal in_iq_bus: iq_bus_t;

	signal out_detected: std_logic := '0';
    signal out_real: signed(15 downto 0) := to_signed(0, 16);
    signal out_imag: signed(15 downto 0) := to_signed(0, 16);
	signal out_valid: std_logic := '0';

	signal iq_enable : std_logic := '0';
	signal iq_complete : std_logic := '0';

	shared variable detections : integer := 0;
	
begin

	rx : entity work.btle_wideband_receiver
	generic map(samples_per_bit => 2, num_channels => 16)
	port map(
		clock => clock,
		reset => reset,
		enable => '1',

		in_wb_real => in_iq_bus.real,
		in_wb_imag => in_iq_bus.imag,
		in_wb_valid => in_iq_bus.valid,
		in_timestamp => (others => '0'),

		in_control => (others => '0'),
		in_connect => (others => '0'),
		in_crc => (others => '0'),

		out_real => out_real,
		out_imag => out_imag,
		out_valid => out_valid, 
		out_detected => out_detected
	);

	iq: entity work.btle_iq_streamer 
	--generic map(filepath => TB_DATA_PATH & "0_connect_adv_aa_hdr_crc.txt")
	generic map(filepath => TB_DATA_PATH & "connect_data_stitch.txt")
	port map(
		clock => clock,
		reset => reset,
		enable => iq_enable,
		out_iq_bus => in_iq_bus,
		iq_done => iq_complete
	);

	
    clock <= not clock after 15.625 ns;
    reset <= '1', '0' after 100 ns;

    stimulus: 
    process
    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until not reset;

			iq_enable <= '1';
			wait until iq_complete;
			iq_enable <= '0';

			assert detections >= 7 report "Failed to detect 7 or more AA bursts"  severity failure;
			
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

				if out_valid = '1' then
					sample_index := sample_index + 1;
				end if;
				
				if out_detected = '1' then
					detections := detections + 1;
					 report "Detected AA at sample: " & to_string(sample_index) & ". Total=" & to_string(detections);
				end if;

			end if;
		end
	process;  
end;
