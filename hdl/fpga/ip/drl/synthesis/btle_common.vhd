--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package btle_common is
	constant BTLE_AA_LEN : integer := 32;
	constant BTLE_PRE_LEN: integer := 8;
	constant BTLE_DETECTOR_LEN: integer := BTLE_AA_LEN + BTLE_PRE_LEN;
	constant BTLE_BED6 : std_logic_vector (39 downto 0) := "0101010101101011011111011001000101110001";
end;

