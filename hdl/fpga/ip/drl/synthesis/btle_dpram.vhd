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
		in_wr_addr:     in unsigned(9 downto 0);
		in_wr_en:		in std_logic;

		in_rd_addr:		in unsigned(9 downto 0);
		out_rd_data:	out std_logic_vector(31 DOWNTO 0)
	);
end btle_dpram;


architecture rtl of btle_dpram is

component dpram
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdaddress	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wraddress	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;


begin

	u_dpr : component dpram
		port map (
			clock		=> clock,
			aclr		=> reset,

			data		=> in_wr_data,
			rdaddress   => std_logic_vector(in_rd_addr),
			wraddress   => std_logic_vector(in_wr_addr),
			wren		=> in_wr_en,
			q			=> out_rd_data
		);

end rtl;
