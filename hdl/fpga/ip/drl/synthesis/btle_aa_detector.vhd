--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

entity btle_aa_detector is
	generic(
		num_channels : integer := 1;
		num_addresses : integer := 1
	);
	port(
		clock:				in std_logic;
		reset:				in std_logic;
		in_seq:				in std_logic;
		in_valid:       	in std_logic;
		in_ch_index:		in integer range num_channels - 1 downto 0;
		in_preamble_aa:		in std_logic_vector (BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 1 downto 0);
		in_aa_valid:		in std_logic;
		out_preamble_aa:	out std_logic_vector (BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 1 downto 0);
		out_detected:		out std_logic
	);
end btle_aa_detector;


architecture rtl of btle_aa_detector is
begin
	aa_detector:
	process(clock, reset) is

		type ch_memory_array_type is array(num_channels - 1 downto 0) of std_logic_vector (BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 1 downto 0);
		type aa_array_type is array(num_addresses - 1 downto 0) of std_logic_vector (BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 1 downto 0);

		variable memory: ch_memory_array_type;
		variable addresses : aa_array_type;
		variable aa_insert_index : integer;
	
		begin
			if reset = '1' then

				for ch_index in 0 to num_channels - 1 loop
					memory(ch_index) := (others => '0');
				end loop;

				for addr_index in 0 to num_addresses - 1 loop
					addresses(addr_index) := BTLE_BED6;
				end loop;

				--addresses(0) := BTLE_BED6;
				aa_insert_index := 0;
				
				out_preamble_aa <= (others => '0');
				out_detected <= '0';
				
			elsif rising_edge(clock) then

				out_detected <= '0';

				if in_aa_valid = '1' then

					-- A new Access Address / Preamble has been supplied
					-- -> Add to the circular list, overwriting the oldest
					
					memory(aa_insert_index) := in_preamble_aa;
					aa_insert_index := aa_insert_index + 1;

					if aa_insert_index = num_addresses then
					
						aa_insert_index := 0;

					end if;

				end if;

				
				if in_valid = '1' then
	
					-- > Shift memory
					-- > Add new bit
					-- > Check correlation

					memory(in_ch_index) := memory(in_ch_index)(BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 2 downto 0) & in_seq;

					for addr_index in 0 to num_addresses - 1 loop

						if memory(in_ch_index) = addresses(addr_index) then
					
							out_preamble_aa <= addresses(addr_index);
							out_detected <= '1';
							exit;

						end if;
						
					end loop;
				end if;
			end if;
		end
	process;
end rtl;

