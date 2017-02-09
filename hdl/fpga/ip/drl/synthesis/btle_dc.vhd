--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

entity btle_dc is
	generic(
		LENGTH: positive := 2 ** 12;
		ACCUM: positive := 32 
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		in_iq_bus:		in iq_bus_t;
		out_clipped:    out std_logic;
		out_iq_bus:     out iq_bus_t
	);
end entity;

architecture rtl of btle_dc is
begin


comp: 
process(clock, reset)

	variable ioff: sample_t;
	variable qoff: sample_t; 
	variable iacc: signed(ACCUM - 1 downto 0);
	variable qacc: signed(ACCUM - 1 downto 0);
	variable cycle: integer range 0 to LENGTH - 1;

	variable isat: sample_t;
	variable qsat: sample_t;

	begin
        if reset = '1' then

			iacc := (others => '0');
			qacc := (others => '0');
			ioff := (others => '0');
			qoff := (others => '0');
			cycle := 0;

			out_clipped <= '0';
			out_iq_bus <= ( (others => '0'), (others => '0'), '0' );
        elsif rising_edge(clock) then

			out_iq_bus <= ( (others => '0'), (others => '0'), '0' );
			out_clipped <= '0';

			if in_iq_bus.valid = '1' then

				if in_iq_bus.real >= BTLE_MAX_IQ or in_iq_bus.real <= BTLE_MIN_IQ or in_iq_bus.imag >= BTLE_MAX_IQ or in_iq_bus.imag <= BTLE_MIN_IQ then
					out_clipped <= '1';
				end if;	

				isat := resize(in_iq_bus.real - ioff, sample_t'length);
				qsat := resize(in_iq_bus.imag - qoff, sample_t'length);

				if isat > BTLE_MAX_IQ then
					out_clipped <= '1';
					isat := to_signed(BTLE_MAX_IQ, isat'length);
				elsif isat < BTLE_MIN_IQ then
					out_clipped <= '1';
					isat := to_signed(BTLE_MIN_IQ, isat'length);
				end if;

				if qsat > BTLE_MAX_IQ then
					out_clipped <= '1';
					qsat := to_signed(BTLE_MAX_IQ, qsat'length);
				elsif qsat < BTLE_MIN_IQ then
					out_clipped <= '1';
					qsat := to_signed(BTLE_MIN_IQ, qsat'length);
				end if;

				out_iq_bus.real <= isat;
				out_iq_bus.imag <= qsat;
                out_iq_bus.valid <= '1';

				iacc := resize(iacc + in_iq_bus.real, ACCUM);
				qacc := resize(qacc + in_iq_bus.imag, ACCUM);

				if cycle = LENGTH - 1 then
					ioff := resize(iacc / LENGTH, sample_t'length);
					qoff := resize(qacc / LENGTH, sample_t'length);
					cycle := 0;
					iacc := (others => '0');
					qacc := (others => '0');
				else
					cycle := cycle + 1;
				end if;
				
			end if;
        end if;
	end 
process;

end 
architecture;
