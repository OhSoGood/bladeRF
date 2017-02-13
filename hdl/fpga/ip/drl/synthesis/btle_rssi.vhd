--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;
use work.btle_channel.all;

entity btle_rssi is
	generic(
		max_timeslots : integer := 1
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		in_iq_bus:		in tdm_iq_bus_t;
		in_clipped:     in std_logic;
		in_detect:      in std_logic;
		in_report:      in std_logic;
		out_results:    out rssi_results_t
	);
end btle_rssi;


architecture rtl of btle_rssi is

	subtype accumulator_t is unsigned(43 downto 0);
	
	type rssi_info_t is record
		accumulator: accumulator_t;
		clipped: std_logic;
		count: integer;
		detections: integer;
	end record;

	type rssi_info_array_t is array (0 to max_timeslots - 1) of rssi_info_t;
	
begin
	rssi: 
	process(clock, reset) is		

		type rssi_state_t is ( STATE_NORMAL, STATE_REPORTING );

		variable rssi_state : rssi_state_t;
		variable rssi_info: rssi_info_array_t;
		variable scaled_in_real: signed(11 downto 0);
		variable scaled_in_imag: signed(11 downto 0);	
		variable report_ts: timeslot_int_t;
		variable ts_int: timeslot_int_t;
		
		begin
			if reset = '1' then

				for ts in 0 to max_timeslots - 1 loop
					rssi_info(ts) := ( (others => '0'), '0', 0, 0 );
				end loop;

				report_ts := 0;
				rssi_state := STATE_NORMAL;

				out_results <= ('0', (others => '0'), (others => '0'), '0', (others => '0') );

			elsif rising_edge(clock) then

				ts_int := to_integer(in_iq_bus.timeslot);
				out_results <= ('0', (others => '0'), (others => '0'), '0', (others => '0') );

				if rssi_state = STATE_NORMAL then

					if in_report = '1' then
						rssi_state := STATE_REPORTING;
						report_ts := 0;
					end if;

				end if;

				if rssi_state = STATE_REPORTING then

					if rssi_info(report_ts).count /= 0 then
						out_results.rssi <= resize((rssi_info(report_ts).accumulator + (rssi_info(report_ts).count - 1)) / (2 * rssi_info(report_ts).count), 32);
					end if;

					out_results.timeslot <= to_unsigned(report_ts, out_results.timeslot'length);
					out_results.clipped <= rssi_info(report_ts).clipped;
					out_results.valid <= '1';
					out_results.detections <= to_unsigned(rssi_info(report_ts).detections, out_results.detections'length);
					
					rssi_info(report_ts) := ( (others => '0'), '0', 0, 0 );

					if(report_ts /= max_timeslots - 1) then
						report_ts := report_ts + 1;
					else
						report_ts := 0;
						rssi_state := STATE_NORMAL;
					end if;

				end if;

				if in_iq_bus.valid = '1' then
				
					rssi_info(ts_int).clipped := in_clipped;
					scaled_in_real := resize(in_iq_bus.real, scaled_in_real'length);
					scaled_in_imag := resize(in_iq_bus.imag, scaled_in_real'length);

					rssi_info(ts_int).accumulator := rssi_info(ts_int).accumulator + unsigned( (scaled_in_real * scaled_in_real) + (scaled_in_imag * scaled_in_imag) );
					rssi_info(ts_int).count := rssi_info(ts_int).count + 1;
					
				end if;

				if in_detect = '1' then
					rssi_info(ts_int).detections := rssi_info(ts_int).detections + 1;
				end if;
			end if;
		end 
	process;
end rtl;

