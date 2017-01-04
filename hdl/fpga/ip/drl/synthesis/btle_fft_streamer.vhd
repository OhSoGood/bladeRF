--
-- (c) Distributed Radio Limited 2016-1017
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_common.all;
use work.btle_window.all;
use work.btle_fft.all;


entity btle_fft_streamer is
	generic (
		order : integer;
		fft_type:   fft_type_t := BTLE_FFT_SPIRAL;
		fft_window: window_type_t := BTLE_WINDOW_NONE
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		enable:			in std_logic;
		in_iq_bus:		in iq_bus_t;
		out_iq_bus:		out tdm_iq_bus_t
	);
end btle_fft_streamer;


architecture rtl of btle_fft_streamer is

begin

fft_selection:  

	if fft_type = BTLE_FFT_ALTERA generate

		fft_altera : entity work.btle_fft_altera			
			generic map (
				order => order,
				fft_window => fft_window
			)
    		port map (
				clock 			=> clock,
				reset 			=> reset,
				enable			=> enable,
				in_iq_bus 		=> in_iq_bus,
				out_iq_bus		=> out_iq_bus
    		);

	else generate
	
		fft_spiral : entity work.btle_fft_spiral			
			generic map (
				order => order,
				fft_window => fft_window
			)
    		port map (
				clock 			=> clock,
				reset 			=> reset,
				enable			=> enable,
				in_iq_bus 		=> in_iq_bus,
				out_iq_bus		=> out_iq_bus
    		);

	end generate;

end rtl;

