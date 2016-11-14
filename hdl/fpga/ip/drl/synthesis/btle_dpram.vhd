--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity btle_dpram is
	port(
		clock:			in std_logic;
		reset:			in std_logic;

		in_wr_data:		in std_logic_vector(31 downto 0);
		in_wr_addr:     in std_logic_vector(9 downto 0);
		in_wr_en:		in std_logic;

		in_rd_addr:		in std_logic_vector(9 downto 0);
		out_rd_data:	out std_logic_vector(31 DOWNTO 0)
	);
end btle_dpram;


architecture rtl of btle_dpram is

begin

	u_dpr : entity work.dpram
		port map (
			clock		=> clock,
			aclr		=> reset,

			data		=> in_wr_data,
			rdaddress   => in_rd_addr,
			wraddress   => in_wr_addr,
			wren		=> in_wr_en,
			q			=> out_rd_data
		);

end rtl;
