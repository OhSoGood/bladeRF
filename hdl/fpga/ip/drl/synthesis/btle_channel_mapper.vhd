--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

entity btle_channel_mapper is
	port (
		clock:				in std_logic;
		reset:				in std_logic;

		rf_config:			in unsigned (1 downto 0);
		in_iq_bus:			in tdm_iq_bus_t;

		out_ch_info:		out btle_ch_info_t;
		out_iq_bus:			out tdm_iq_bus_t
	);
end btle_channel_mapper;


architecture rtl of btle_channel_mapper is

	type subband_array_t is array (0 to BTLE_FFT_SIZE - 1) of integer range 0 to 63;
	type band_array_t is array (0 to BTLE_NUM_SUBBANDS - 1) of subband_array_t;

	constant rf_band_info: band_array_t := (
		(	5, 6, 7, 8, 9, 10, 38, BTLE_INVALID_CHANNEL, BTLE_INVALID_CHANNEL, BTLE_INVALID_CHANNEL, 37, 0, 1, 2, 3, 4 ),
		(	63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63 ),
		(	63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63 )
	);


	
begin

	channeliser:
	process(clock, reset) is

		variable ch_int: integer;

		begin
			if reset = '1' then

			elsif rising_edge(clock) then

				out_ch_info.valid <= '0';
				out_ch_info.adv <= '0';
				out_ch_info.ch_idx <= to_unsigned(BTLE_INVALID_CHANNEL, out_ch_info.ch_idx'length);

				out_iq_bus.real <= (others => '0');
				out_iq_bus.imag <= (others => '0');
				out_iq_bus.timeslot <= (others => '0');
				out_iq_bus.valid <= '0';
				
				if in_iq_bus.valid = '1' then

					ch_int := rf_band_info(to_integer(rf_config))(to_integer(in_iq_bus.timeslot));
					
					if  ch_int /= BTLE_INVALID_CHANNEL then

						out_iq_bus <= in_iq_bus;

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

