--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package btle_complex is

	subtype int16 is integer range -2**14 to 2**14 - 1;
	subtype uint16 is integer range 0 to 2**15 - 1;
	
	subtype int32 is integer range -2**30 to 2**30 - 1;
	subtype uint32 is integer range 0 to 2147483647;

	type complex_i16 is record
		real : int16;
		imag : int16;
	end record;

	type complex_i32 is record
		real : int32;
		imag : int32;
	end record;

	function "+"(left, right : complex_i32) return complex_i32;
	function add(left, right : complex_i32) return complex_i32;
	function "*"(left, right : complex_i16) return complex_i32;
	function mul(left, right : complex_i16; s: natural) return complex_i32;
end;

package body btle_complex is

	function "+"(left, right : complex_i32) return complex_i32 is
	begin
		return add (left, right);
	end;
	
	function add(left, right : complex_i32) return complex_i32 is
	begin
		return (left.real + right.real, left.imag + right.imag);
	end;

	function "*"(left, right : complex_i16) return complex_i32 is
	begin
		return mul(left, right, 0);
	end;
	
	function mul(left, right : complex_i16; s: natural) return complex_i32 is
		variable k1 : int32;
		variable k2 : int32;
		variable k3 : int32;
	begin

		k1 := left.real *  (right.real + right.imag);
		k2 := right.imag * (left.real + left.imag);
		k3 := right.real * (left.imag - left.real);
	
		return ((k1 - k2) / (2 ** s), (k1 + k3) / (2 ** s));
	end;

end;
