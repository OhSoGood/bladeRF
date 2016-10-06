--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

entity btle_aa_detector is
	port(
		clock:			in std_logic;
		reset:			in std_logic;

		-- input signal
		in_bit:			in std_logic;
		in_valid:       in std_logic;

		-- output bits
		out_detect:		out std_logic := '0'
	);
end btle_aa_detector;


architecture rtl of btle_aa_detector is
begin
	aa_detector:
	process(clock, reset) is

		variable memory: std_logic_vector (BTLE_DETECTOR_LEN - 1 downto 0);
	
		begin
			if reset = '1' then

				memory := (others => '0');
				out_detect <= '0';
				
			elsif rising_edge(clock) then

				out_detect <= '0';
			
				if in_valid = '1' then
	
					-- > Shift memory
					-- > Add new bit
					-- > Check correlation

					memory := memory(BTLE_DETECTOR_LEN - 2 downto 0) & in_bit;

					if memory = BTLE_BED6 then
						out_detect <= '1';
					end if;
				end if;
			end if;
		end
	process;
end rtl;

