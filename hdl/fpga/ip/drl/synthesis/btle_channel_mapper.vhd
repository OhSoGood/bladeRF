--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_common.all;
use work.btle_channel.all;

entity btle_channel_mapper is
	generic (
		max_channels : integer := 1
	);
	port (
		clock:				in std_logic;
		reset:				in std_logic;

		rf_config:			in unsigned (1 downto 0);
		in_bit_bus:			in tdm_bit_bus_t;

		out_ch_info:		out btle_ch_info_t;
		out_bit_bus:		out tdm_bit_bus_t
	);
end btle_channel_mapper;


architecture rtl of btle_channel_mapper is

	
begin

	channeliser:
	process(clock, reset) is

		variable ch_int: channel_int_t;

		begin
			if reset = '1' then

			elsif rising_edge(clock) then

				out_ch_info.valid <= '0';
				out_ch_info.adv <= '0';
				out_ch_info.ch_idx <= to_unsigned(BTLE_CHANNEL_INVALID, out_ch_info.ch_idx'length);

				out_bit_bus.seq <= '0';
				out_bit_bus.timeslot <= (others => '0');
				out_bit_bus.valid <= '0';
				
				if in_bit_bus.valid = '1' then

					if max_channels = 1 then
						ch_int := 37;
					else
						ch_int := btle_channel_get_idx( to_integer(rf_config), to_integer(in_bit_bus.timeslot) );
						--ch_int := rf_band_info(to_integer(rf_config))(to_integer(in_bit_bus.timeslot));
					end if;
					
					if  ch_int /= BTLE_CHANNEL_INVALID then

						out_bit_bus <= in_bit_bus;

						out_ch_info.valid <= '1';						
						out_ch_info.ch_idx <= to_unsigned(ch_int, channel_idx_t'length);

						if ch_int >= 37 and ch_int <= 39 then
							out_ch_info.adv <= '1';
						end if;
						
					end if;
				end if;
			end if;
		end
	process;
end rtl;

