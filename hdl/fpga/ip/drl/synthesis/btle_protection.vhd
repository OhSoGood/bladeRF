--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity btle_protection is
	generic(
	    clock_freq : integer;
		duration : integer;
		active : boolean
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		enable:			in std_logic;
		out_expiry:     out std_logic
	);
end btle_protection;


architecture rtl of btle_protection is

	signal pps : std_logic := '0';

begin

	timer_protected: if active = true generate

		pps_gen:
		entity work.btle_timer 
			generic map (
				duration => clock_freq, 
				reload => true
			)
			port map (
    			clock 		=> clock,
    			reset 		=> reset,
        		enable 	    => enable,
        		out_expiry  => pps
  			);

  		second_counter:
  		entity work.btle_timer
			generic map (
				duration => duration, 
				reload => false
			)
			port map (
    			clock 		=> pps,
    			reset 		=> reset,
        		enable 	    => enable,
        		out_expiry  => out_expiry
  			);

  	else generate

		out_expiry <= '0';

  	end generate;

end rtl;

