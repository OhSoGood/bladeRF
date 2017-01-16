--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_common.all;

entity btle_timer is
	generic(
		duration : integer;
		reload : boolean
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		enable:			in std_logic;
		out_expiry:     out std_logic
	);
end btle_timer;


architecture rtl of btle_timer is
begin
	timer:
	process(clock, reset) is

		type timer_state_t is ( STATE_RUNNING, STATE_EXPIRED );

		variable val: integer := duration;
		variable state : timer_state_t := STATE_RUNNING;
		
		begin
			if reset = '1' then

				out_expiry <= '0';

				val := duration;
				state := STATE_RUNNING;
				
			elsif rising_edge(clock) then

				if enable = '1' then

					out_expiry <= '0';

					case state is
						when STATE_RUNNING =>

							val := val - 1;

							if val = 0 then
							
								out_expiry <= '1';

								if reload = true then
									val := duration;
								else 
									state := STATE_EXPIRED;
								end if; 

							end if;
					
						when STATE_EXPIRED =>

							out_expiry <= '1';

						when others =>
							state := STATE_RUNNING;
							
					end case;
					
				end if;
			end if;
		end
	process;
end rtl;

