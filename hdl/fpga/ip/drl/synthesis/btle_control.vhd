--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package btle_control is

	-- 0 and 1 are RF ID
	constant BTLE_CONTROL_CONNECT : integer := 2;
	constant BTLE_CONTROL_REPORT_ADV_HDR_FAILURE : integer := 3;
	constant BTLE_CONTROL_REPORT_ADV_CRC_FAILURE : integer := 4;
	constant BTLE_CONTROL_REPORT_DATA_HDR_FAILURE : integer := 5;
	constant BTLE_CONTROL_REPORT_DATA_CRC_FAILURE : integer := 6;
	-- 7 and 8 are FFT Window

	type btle_control_report_opts_t is record
		adv_hdr_fail: 		std_logic;
		adv_crc_fail: 		std_logic;
		data_hdr_fail: 		std_logic;
		data_crc_fail: 		std_logic;
	end record;

end;


package body btle_control is


end btle_control;

