--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

package btle_channel is

	subtype channel_int_t is integer range 0 to 63;
	subtype subband_int_t is integer range 0 to BTLE_NUM_SUBBANDS - 1;
	subtype timeslot_int_t is integer range 0 to BTLE_FFT_SIZE - 1;

	type subband_array_t is array (0 to BTLE_FFT_SIZE - 1) of channel_int_t;
	type band_array_t is array (0 to BTLE_NUM_SUBBANDS - 1) of subband_array_t;

	constant BTLE_CHANNEL_INVALID : integer := 63;

	constant rf_band_info: band_array_t := (
		(	5,  6,  7,  8,  9, 10, 38, BTLE_CHANNEL_INVALID, BTLE_CHANNEL_INVALID, BTLE_CHANNEL_INVALID, 37,  0,  1,  2,  3,  4 ),   -- 2414
		(  18, 19, 20, 21, 22, 23, 24, BTLE_CHANNEL_INVALID, BTLE_CHANNEL_INVALID, 					 11, 12, 13, 14, 15, 16, 17 ),	 -- 2442
		(  31, 32, 33, 34, 35, 36, 39, BTLE_CHANNEL_INVALID, BTLE_CHANNEL_INVALID, BTLE_CHANNEL_INVALID, 25, 26, 27, 28, 29, 30 )    -- 2468

	);

	function btle_channel_get_idx (	in_rf_id:    	in subband_int_t; 
									in_timeslot: 	in timeslot_int_t)  return channel_int_t;

end;



package body btle_channel is


	function btle_channel_get_idx (	in_rf_id:   	in subband_int_t; 
									in_timeslot: 	in timeslot_int_t )
		return channel_int_t is
	
		begin

			return rf_band_info(in_rf_id)(in_timeslot);

		end;

	
end btle_channel;


