--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_common.all;

package btle_window is

	subtype window_phase_t is integer range 0 to 15;
	type window_type_t is (BTLE_WINDOW_HANNING, BTLE_WINDOW_HAMMING, BTLE_WINDOW_NONE );
	type window_coeff_t is array (0 to 15) OF integer range 0 to 2047;
	type window_array_t is array (0 to window_type_t'pos(BTLE_WINDOW_NONE) - 1) of window_coeff_t;
	
	constant window_array : window_array_t := (
		( 69, 267, 568, 930, 1304, 1641, 1895, 2031, 2031, 1895, 1641, 1304, 930, 568, 267,  69),	-- hanning(16) * 2048						
		(164, 245, 476, 815, 1204, 1577, 1868, 2027, 2027, 1868, 1577, 1204, 815, 476, 245, 164)	-- hamming(16) * 2048
	);

	function btle_apply_window (	in_win:    	in window_type_t; 
									in_sample: 	in sample_t; 
									in_phase : 	in window_phase_t ) return sample_t;
	
end;


package body btle_window is

	function btle_apply_window (	in_win:    	in window_type_t; 
									in_sample: 	in sample_t; 
									in_phase : 	in window_phase_t )
		return sample_t is

 		variable windowed: signed(31 downto 0);	
		variable result: sample_t;
		
		begin

			if in_win /= BTLE_WINDOW_NONE then
				windowed := ((in_sample * window_array(window_type_t'pos(in_win))(in_phase)) + 1024) / 2048;
				result := resize(windowed, result'length);
			else
				result := in_sample;		
			end if;

  			return result;
		end;

end btle_window;

