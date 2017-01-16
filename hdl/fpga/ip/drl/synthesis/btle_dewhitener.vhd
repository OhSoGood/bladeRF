--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_common.all;

entity btle_dewhitener is
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		in_restart:		in std_logic;
		in_seq:			in std_logic;
		in_valid:		in std_logic;
		in_ch_idx:		in channel_idx_t;
		out_seq:		out std_logic;
		out_valid:      out std_logic
	);
end btle_dewhitener;


architecture rtl of btle_dewhitener is
begin
	dewhiten:
	process(clock, reset) is

		variable bs: std_logic_vector (6 downto 0);
		variable fb : std_logic;
	
		begin
			if reset = '1' then

				bs := (others => '0');
				out_seq <= '0';
				out_valid <= '0';
				
			elsif rising_edge(clock) then
		
				out_valid <= in_valid;

				if in_restart = '1' then
					bs := std_logic_vector('1' & in_ch_idx);
				end if;

				if in_valid = '1' then

					fb := bs(0);
					bs := fb & bs(6 downto 1);
					bs(2) := bs(2) xor fb;
					
					out_seq <= fb xor in_seq;
				end if;
			end if;
		end
	process;
end rtl;

