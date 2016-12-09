--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

entity btle_aa_detector is
	generic (
		num_timeslots : integer := 1;
		num_addresses : integer := 1
	);
	port (
		clock:				in std_logic;
		reset:				in std_logic;

		in_seq:				in tdm_bit_bus_t;
		in_cfg:				in aa_config_t;

		out_seq:			out tdm_bit_bus_t;
		out_detect_results:	out aa_detect_results_t
	);
end btle_aa_detector;


architecture rtl of btle_aa_detector is
begin
	aa_detector:
	process(clock, reset) is

		type ch_memory_array_type is array(num_timeslots - 1 downto 0) of preamble_aa_t;
		type aa_array_type is array(num_addresses - 1 downto 0) of preamble_aa_t;

		variable memory: ch_memory_array_type;
		variable addresses : aa_array_type;
		variable aa_insert_index : integer;
	
		begin
			if reset = '1' then

				for ts in 0 to num_timeslots - 1 loop
					memory(ts) := (others => '0');
				end loop;

				for addr_index in 0 to num_addresses - 1 loop
					addresses(addr_index) := BTLE_BED6;
				end loop;

				aa_insert_index := 0;

				out_detect_results.detected <= '0';
				out_detect_results.preamble_aa <= (others => '0');

			elsif rising_edge(clock) then

				out_detect_results.detected <= '0';
				out_detect_results.preamble_aa <= (others => '0');

				if in_cfg.valid = '1' then

					-- A new Access Address / Preamble has been supplied
					-- -> Add to the circular list, overwriting the oldest
					
					addresses(aa_insert_index) := in_cfg.preamble_aa;
					aa_insert_index := aa_insert_index + 1;

					if aa_insert_index = num_addresses then
					
						aa_insert_index := 0;

					end if;

				end if;

			
				if in_seq.valid = '1' then
	
					-- > Shift memory
					-- > Add new bit
					-- > Check correlation

					memory(to_integer(in_seq.timeslot)) := memory(to_integer(in_seq.timeslot))(BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 2 downto 0) & in_seq.seq;

					for addr_index in 0 to num_addresses - 1 loop

						if memory(to_integer(in_seq.timeslot)) = addresses(addr_index) then
					
							out_detect_results.preamble_aa <= addresses(addr_index);
							out_detect_results.detected <= '1';
							exit;

						end if;
						
					end loop;
					
				end if;

				out_seq <= in_seq;

			end if;
		end
	process;
end rtl;

