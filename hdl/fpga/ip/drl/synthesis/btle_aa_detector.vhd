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
		in_data_ch_cfg:		in aa_crc_config_t;

		out_bit_bus:		out tdm_bit_bus_t;
		out_ch_info:		out btle_ch_info_t;
		out_detect_results:	out aa_crc_config_t
	);
end btle_aa_detector;


architecture rtl of btle_aa_detector is
begin
	aa_detector:
	process(clock, reset) is

		type ch_memory_array_type is array(num_timeslots - 1 downto 0) of preamble_aa_t;
		type aa_array_type is array(max_addresses - 1 downto 0) of aa_crc_config_t;

		variable memory: ch_memory_array_type;
		variable addresses : aa_array_type;
		variable aa_insert_index : integer range 0 to max_addresses - 1 := 0;
	
		begin
			if reset = '1' then

				for ts in 0 to num_timeslots - 1 loop
					memory(ts) := (others => '0');
				end loop;

				for addr_index in 0 to max_addresses - 1 loop
					addresses(addr_index).valid := '0';
					addresses(addr_index).preamble_aa 	:= (others => '0');
					addresses(addr_index).crc_init 	:= (others => '0');
				end loop;

				aa_insert_index := 0;

				out_detect_results.valid <= '0';
				out_detect_results.preamble_aa <= (others => '0');
				out_detect_results.crc_init <= (others => '0');
				
			elsif rising_edge(clock) then

				out_bit_bus.seq <= '0';
				out_bit_bus.valid <= '0';
				out_bit_bus.timeslot <= (others => '0');

				out_detect_results.valid <= '0';
				out_detect_results.preamble_aa <= (others => '0');
				out_detect_results.crc_init <= (others => '0');
				
				out_ch_info.valid <= '0';
				out_ch_info.ch_idx <= to_unsigned(BTLE_INVALID_CHANNEL, out_ch_info.ch_idx'length);
				out_ch_info.adv <= '0';

				if in_data_ch_cfg.valid = '1' then

					-- A new Access Address / Preamble has been supplied
					-- -> Add to the circular list, overwriting the oldest

					addresses(aa_insert_index) := in_data_ch_cfg;

					if aa_insert_index = max_addresses - 1 then
						aa_insert_index := 0;
					else
						aa_insert_index := aa_insert_index + 1;
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

								out_detect_results.valid <= '1';
								out_detect_results.preamble_aa <= BTLE_BED6;
								out_detect_results.crc_init <= BTLE_ADV_CRC_INIT;
							
							end if;

						else

							-- Data channel
							-- -> Search acess address connection database

							for addr_index in 0 to max_addresses - 1 loop

								if addresses(addr_index).valid = '1' then

									if memory(to_integer(in_bit_bus.timeslot)) = addresses(addr_index).preamble_aa then
								
										out_detect_results <= addresses(addr_index);
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

