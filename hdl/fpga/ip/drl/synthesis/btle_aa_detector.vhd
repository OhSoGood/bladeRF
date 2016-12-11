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
		max_addresses : integer := 1
	);
	port (
		clock:				in std_logic;
		reset:				in std_logic;

		in_bit_bus:			in tdm_bit_bus_t;
		in_ch_info:			in btle_ch_info_t;
		in_cfg:				in aa_config_t;

		out_bit_bus:		out tdm_bit_bus_t;
		out_ch_info:		out btle_ch_info_t;
		out_detect_results:	out aa_detect_results_t
	);
end btle_aa_detector;


architecture rtl of btle_aa_detector is
begin
	aa_detector:
	process(clock, reset) is

		type data_ch_aa_t is record
			valid:		std_logic;
			aa: 		preamble_aa_t;
		end record;

		type ch_memory_array_type is array(num_timeslots - 1 downto 0) of preamble_aa_t;
		type aa_array_type is array(max_addresses - 1 downto 0) of data_ch_aa_t;

		variable memory: ch_memory_array_type;
		variable addresses : aa_array_type;
		variable aa_insert_index : integer;
	
		begin
			if reset = '1' then

				for ts in 0 to num_timeslots - 1 loop
					memory(ts) := (others => '0');
				end loop;

				for addr_index in 0 to max_addresses - 1 loop
					addresses(addr_index).valid := '0';
					addresses(addr_index).aa 	:= (others => '0');
				end loop;

				aa_insert_index := 0;

				out_detect_results.detected <= '0';
				out_detect_results.preamble_aa <= (others => '0');

			elsif rising_edge(clock) then

				out_bit_bus.seq <= '0';
				out_bit_bus.valid <= '0';
				out_bit_bus.timeslot <= (others => '0');

				out_detect_results.detected <= '0';
				out_detect_results.preamble_aa <= (others => '0');

				out_ch_info.valid <= '0';
				out_ch_info.ch_idx <= to_unsigned(BTLE_INVALID_CHANNEL, out_ch_info.ch_idx'length);
				out_ch_info.adv <= '0';

				if in_cfg.valid = '1' then

					-- A new Access Address / Preamble has been supplied
					-- -> Add to the circular list, overwriting the oldest

					addresses(aa_insert_index).valid 	:= '1';
					addresses(aa_insert_index).aa 		:= in_cfg.preamble_aa;

					aa_insert_index := aa_insert_index + 1;

					if aa_insert_index = max_addresses then
						aa_insert_index := 0;
					end if;

				end if;

			
				if in_bit_bus.valid = '1' then

					if in_ch_info.valid = '1' then
					
						-- > Shift memory
						-- > Add new bit
						-- > Check correlation

						memory(to_integer(in_bit_bus.timeslot)) := memory(to_integer(in_bit_bus.timeslot))(BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 2 downto 0) & in_bit_bus.seq;

						if in_ch_info.adv = '1' then

							-- Advertising channel
							-- -> Check global AA (BED6)
							
							if memory (to_integer(in_bit_bus.timeslot)) = BTLE_BED6 then

								out_detect_results.preamble_aa <= BTLE_BED6;
								out_detect_results.detected <= '1';
							
							end if;

						else

							-- Data channel
							-- -> Search acess address connection database

							for addr_index in 0 to max_addresses - 1 loop

								if addresses(addr_index).valid = '1' then

									if memory(to_integer(in_bit_bus.timeslot)) = addresses(addr_index).aa then
									
										out_detect_results.preamble_aa <= addresses(addr_index).aa;
										out_detect_results.detected <= '1';
										exit;

									end if;

								end if;
									
							end loop;
								
						end if;

						out_ch_info <= in_ch_info;
						out_bit_bus <= in_bit_bus;
						
					end if;
					
				end if;

			end if;
		end
	process;
end rtl;

