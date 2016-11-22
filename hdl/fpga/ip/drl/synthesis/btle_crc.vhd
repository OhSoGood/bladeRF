--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;


entity btle_crc is
	port(
		clock:				in std_logic;
		reset:				in std_logic;
		in_soh:				in std_logic;				-- Start of header (16 bits)
		in_sop:				in std_logic;				-- Start of payload (value supplied)
		in_payload_len:		in unsigned (5 downto 0);	-- Payload length in bytes
		in_seq:       		in std_logic;
		in_valid:			in std_logic;
		out_crc:			out std_logic_vector (23 downto 0);
		out_decoded:		out std_logic;
		out_valid:			out std_logic
	);
end btle_crc;


architecture rtl of btle_crc is

	type crc_state_type is ( STATE_IDLE, STATE_CALC_HDR, STATE_CALC_PAYLOAD, STATE_CHECK_CRC );

begin
	crc:
	process(clock, reset) is

		variable state : crc_state_type;
		variable bs: std_logic_vector (23 downto 0);
		variable fb : std_logic;
		variable countdown : integer;
		variable crc_rx : std_logic_vector(23 downto 0);

		begin
			if reset = '1' then

				state := STATE_IDLE;

                out_decoded <= '0';
				out_valid <= '0';
				out_crc	<= (others => '0');
				
			elsif rising_edge(clock) then

				out_decoded <= '0';

				if in_soh = '1' then	

					bs := x"AAAAAA";
					state := STATE_CALC_HDR;
					countdown := BTLE_HEADER_LEN;

					out_valid <= '0';
					out_crc	<= (others => '0');
				
				elsif in_sop = '1' then

					assert state = STATE_CALC_HDR 
						report "Error: Unexpected state when CRC SOP asserted: " 
							--& to_string(state) 
						severity failure; 

					assert countdown = 0 
						report "Error: Countdown was non-zero when CRC SOP asserted: " 
							--& to_string(countdown) 
						severity failure;

					state := STATE_CALC_PAYLOAD;
					countdown := 8 * to_integer(in_payload_len);

				end if;

				if state = STATE_CALC_HDR or state = STATE_CALC_PAYLOAD then

					if in_valid = '1' and countdown > 0 then

						fb := in_seq xor bs(0);
							
						bs := fb & bs(23 downto 1);
						bs(22) := bs(22) xor fb;
						bs(20) := bs(20) xor fb;
						bs(19) := bs(19) xor fb;
						bs(17) := bs(17) xor fb;
						bs(14) := bs(14) xor fb;
						bs(13) := bs(13) xor fb;	

						countdown := countdown - 1;

						if (countdown = 0) and (state = STATE_CALC_PAYLOAD) then

							countdown := BTLE_CRC_LEN;
							state := STATE_CHECK_CRC;

						end if;
					end if;

				elsif state = STATE_CHECK_CRC then

					assert countdown /= 0
						report "Error: Countdown was zero when about to feed CRC check: " 
							--& to_string(countdown) 
						severity failure;

					if in_valid = '1' and countdown > 0 then

						countdown := countdown - 1;
						
						crc_rx(23 - countdown) := in_seq;

						if countdown = 0 then

							for i in 0 to 23 loop
								out_crc(23 - i) <= bs(i);
							end loop;
							
							if crc_rx = bs then
								out_valid <= '1';
							end if;

							out_decoded <= '1';
							state := STATE_IDLE;
						end if;
					end if;

				end if;
			end if;
		end
	process;
end rtl;

