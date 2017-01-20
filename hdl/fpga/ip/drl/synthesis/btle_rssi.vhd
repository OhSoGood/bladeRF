--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

entity btle_rssi is
	generic(
		samples_per_bit : natural := 2;
		max_channels : integer := 1
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		in_iq_bus:		in tdm_iq_bus_t;
		in_report:      in std_logic;
		out_valid:      out std_logic;
		out_timeslot:   out timeslot_t;
		out_rssi:       out rssi_t;
		out_clipped:    out std_logic
	);
end btle_rssi;


architecture rtl of btle_rssi is


	subtype accumulator_t is unsigned(33 downto 0);
	type accumulator_array_t is array (0 to max_channels - 1) of accumulator_t;
	
begin
	rssi: 
	process(clock, reset) is		

--		type rssi_ch_info_t is record
--
--			ch_idx:		channel_idx_t;
--			adv:		std_logic;
--			valid:		std_logic;
--		end record;

		variable accumulator: accumulator_array_t;
		variable clipped: std_logic_vector (max_channels -1 downto 0);
		variable scaled_in_real: signed(11 downto 0);
		variable scaled_in_imag: signed(11 downto 0);	
		variable count: integer;

		
		begin
			if reset = '1' then

				for ts in 0 to max_channels - 1 loop
					accumulator(ts) := (others => '0');
				end loop;

				count := 0;
				clipped := (others => '0');
				
				out_valid <= '0';
				out_timeslot <= (others => '0');
				out_rssi <= (others => '0');     

			elsif rising_edge(clock) then

				out_valid <= '0';
				out_timeslot <= (others => '0');
				out_rssi <= (others => '0');     

				if in_report = '1' then
				
					out_timeslot <= (others => '0');

					if count /= 0 then
						out_rssi <= resize((accumulator(0) + (count - 1)) / (2 * count), 32);
					else
						out_rssi <= (others => '0');
					end if;

					out_clipped <= clipped(0);
					out_valid <= '1';

					clipped(0) := '0';
					accumulator(0) := (others => '0');
					count := 0;
					
				end if;

				if in_iq_bus.valid = '1' then

					if in_iq_bus.real >= 2047 or in_iq_bus.real <= -2048 or in_iq_bus.imag >= 2047 or in_iq_bus.imag <= -2048 then
						clipped(to_integer(in_iq_bus.timeslot)) := '1';
					end if;	

					scaled_in_real := resize(in_iq_bus.real, 12);
					scaled_in_imag := resize(in_iq_bus.imag, 12);

					accumulator(to_integer(in_iq_bus.timeslot)) := accumulator(to_integer(in_iq_bus.timeslot)) + unsigned( (scaled_in_real * scaled_in_real) + (scaled_in_imag * scaled_in_imag) );
					count := count + 1;
					
				end if;
			end if;
		end 
	process;

	
end rtl;

