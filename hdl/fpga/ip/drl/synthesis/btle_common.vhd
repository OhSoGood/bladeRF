--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package btle_common is

	constant BTLE_SAMPLES_PER_SYMBOL : integer := 2;
	constant BTLE_MAXIMUM_AA_MEMORY : integer := 5;

	-- Bits
	constant BTLE_TRIGGER_LEN: integer := 25;
	constant BTLE_PREAMBLE_LEN: integer := 8;
	constant BTLE_AA_LEN : integer := 32;
	constant BTLE_HEADER_LEN : integer := 16;
	constant BTLE_MIN_PAYLOAD_LEN: integer := (6 * 8);
	constant BTLE_MAX_PAYLOAD_LEN: integer := (37 * 8);
	constant BTLE_CRC_LEN: integer := 24;

	constant BTLE_BED6 : std_logic_vector (BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 1 downto 0) := "0101010101101011011111011001000101110001";

	--Samples
	constant BTLE_MEMORY_LEN: integer := BTLE_SAMPLES_PER_SYMBOL * (BTLE_TRIGGER_LEN + BTLE_PREAMBLE_LEN + BTLE_AA_LEN + BTLE_HEADER_LEN + BTLE_MAX_PAYLOAD_LEN + BTLE_CRC_LEN + BTLE_TRIGGER_LEN);	
	constant BTLE_DEMOD_TAP_POSITION: integer := BTLE_SAMPLES_PER_SYMBOL * (BTLE_TRIGGER_LEN + BTLE_PREAMBLE_LEN + BTLE_AA_LEN);

	function reverse_any_vector (a: in std_logic_vector) return std_logic_vector;

	subtype sample_t is signed (15 downto 0);
	subtype timeslot_t is unsigned (4 downto 0);

	type iq_bus_t is record
		real: 		sample_t;
		imag: 		sample_t;
		valid: 		std_logic;
	end record;

	type tdm_iq_bus_t is record
		real: 		sample_t;
		imag: 		sample_t;
		valid: 		std_logic;
		timeslot: 	timeslot_t;
	end record;

	type bit_bus_t is record
		seq:		std_logic;
		valid:		std_logic;
	end record;

	type tdm_bit_bus_t is record
		seq:		std_logic;
		valid:		std_logic;
		timeslot:	timeslot_t;
	end record;

end;


package body btle_common is

	function reverse_any_vector (a: in std_logic_vector)
		return std_logic_vector is
 		variable result: std_logic_vector(a'RANGE);

  		alias aa: std_logic_vector(a'REVERSE_RANGE) is a;

		begin
  			for i in aa'RANGE loop
    			result(i) := aa(i);
  			end loop;

  			return result;
		end; -- function reverse_any_vector


end btle_common;

