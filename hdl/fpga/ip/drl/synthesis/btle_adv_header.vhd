--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;


entity btle_adv_header is
	port(
		clock:			in std_logic;
		reset:			in std_logic;

		-- input signal
		in_soh:			in std_logic;
		in_seq:       	in std_logic;
		in_valid:		in std_logic;

		-- output bits

		out_decoded:	out std_logic;
		out_valid:		out std_logic;
		out_bits:       out std_logic_vector (15 downto 0);
		out_pdu_type: 	out unsigned (3 downto 0);
		out_length: 	out unsigned (5 downto 0);
		out_tx_addr: 	out std_logic;
		out_rx_addr: 	out std_logic
	);
end btle_adv_header;


architecture rtl of btle_adv_header is

	type hdr_state_type is ( STATE_IDLE, STATE_DECODING );

begin
	header_fsm:
	process(clock, reset) is

		variable state : hdr_state_type;
		variable header: std_logic_vector (15 downto 0);
		variable header_idx : integer := 0;
		variable hdr_len_bits : unsigned (11 downto 0) := (others => '0');
		variable hdr_type : unsigned (3 downto 0) := (others => '0');

		begin
			if reset = '1' then

				state := STATE_IDLE;
				header := (others => '0');
				header_idx := 0;

				out_decoded 	<= '0';
				out_valid 		<= '0';
				out_bits        <= (others => '0');
				out_pdu_type 	<= (others => '0');
				out_length		<= (others => '0');
				out_tx_addr 	<= '0';
				out_rx_addr 	<= '0';
				
			elsif rising_edge(clock) then

				out_decoded <= '0';

				if in_soh = '1' then	

					out_valid 		<= '0';
					out_bits        <= (others => '0');
					out_pdu_type 	<= (others => '0');
					out_length	 	<= (others => '0');
					out_tx_addr 	<= '0';
					out_rx_addr 	<= '0';

					header := (others => '0');
					header_idx := 0;
					state := STATE_DECODING;

				end if;

				case state is
				
					when STATE_IDLE =>
						-- Nothing to do
						
					when STATE_DECODING =>
					
						if in_valid = '1' then
							
							header(header_idx) := in_seq;

							if header_idx /= header'high then
								header_idx := header_idx + 1;
							else
								hdr_len_bits := unsigned(header(13 downto 8)) * 8;
								hdr_type := unsigned(header(3 downto 0));

								out_bits <= reverse_any_vector(header);
								out_length <= unsigned(header(13 downto 8));
								out_rx_addr <= header(7);
								out_tx_addr <= header(6);
								out_pdu_type <= hdr_type;

								if (hdr_len_bits >= BTLE_MIN_PAYLOAD_LEN) and (hdr_len_bits <= BTLE_MAX_PAYLOAD_LEN) then
									if hdr_type <= 6 then
										out_valid <= '1';									
									end if;
								end if;

								out_decoded <= '1';
								state := STATE_IDLE;
								
							end if;
						end if;

					when others =>
					
						out_decoded 	<= '0';
						out_valid 		<= '0';
						out_pdu_type 	<= (others => '0');
						out_length  	<= (others => '0');
						out_tx_addr 	<= '0';
						out_rx_addr 	<= '0';

						state := STATE_IDLE;
				end case;		

			end if;
		end
	process;
end rtl;

