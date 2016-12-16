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
		in_ch_info:		in btle_ch_info_t;
		
		-- output bits

		out_common_hdr: out common_header_t;
		out_adv_hdr:	out adv_header_t;
		out_data_hdr:	out data_header_t
	);
end btle_adv_header;


architecture rtl of btle_adv_header is

	type hdr_state_type is ( STATE_IDLE, STATE_DECODING_ADV, STATE_DECODING_DATA );

begin
	header_fsm:
	process(clock, reset) is

		variable state : hdr_state_type;
		variable header: std_logic_vector (15 downto 0);
		variable header_idx : integer range 0 to header'high := 0;

		variable rfu2: unsigned (2 downto 0) := (others => '0');
		variable rfu : unsigned (2 downto 0) := (others => '0');
		
		variable hdr_len_bits : unsigned (11 downto 0) := (others => '0');
		variable hdr_type : unsigned (3 downto 0) := (others => '0');
		
		
		begin
			if reset = '1' then

				out_common_hdr	<= ( '0', '0', (others => '0'), (others => '0'), (others => '0') );
				out_adv_hdr		<= ( '0', '0' );
				
				state := STATE_IDLE;
				header := (others => '0');
				header_idx := 0;

			elsif rising_edge(clock) then

				out_common_hdr.decoded <= '0';

				if in_soh = '1' then	

					out_common_hdr.valid <= '0';
					out_common_hdr.length <= (others => '0');
					out_common_hdr.pdu_llid <= (others => '0');
					out_common_hdr.bits <= (others => '0');

					out_adv_hdr		<= ( '0', '0' );
					out_data_hdr 	<= ( '0', '0', '0' );
	
					header := (others => '0');
					header_idx := 0;

					if in_ch_info.adv = '1' then
						state := STATE_DECODING_ADV;
					else
						state := STATE_DECODING_DATA;
					end if;

				end if;

				case state is
				
					when STATE_IDLE =>
						-- Nothing to do
						
					when STATE_DECODING_ADV =>
					
						if in_valid = '1' then
							
							header(header_idx) := in_seq;

							if header_idx /= header'high then
								header_idx := header_idx + 1;
							else 
								rfu2 := unsigned('0' & header(15 downto 14));
								hdr_len_bits := unsigned(header(13 downto 8)) * 8;

								out_adv_hdr.rx_addr <= header(7);
								out_adv_hdr.tx_addr <= header(6);

								rfu := unsigned('0' & header(5 downto 4));
								hdr_type := unsigned(header(3 downto 0));

								out_common_hdr.bits <= reverse_any_vector(header);
								out_common_hdr.length <= unsigned(header(13 downto 8));
								out_common_hdr.pdu_llid <= hdr_type;

								if (hdr_len_bits >= BTLE_MIN_PAYLOAD_LEN) and (hdr_len_bits <= BTLE_MAX_PAYLOAD_LEN) then
								
									if hdr_type <= BTLE_ADV_PDU_ADV_SCAN_IND then

										if rfu2 = "000" and rfu = "000" then

											out_common_hdr.valid <= '1';

										end if;
									end if;
								end if;

								out_common_hdr.decoded <= '1';
								state := STATE_IDLE;
								
							end if;
						end if;

					when STATE_DECODING_DATA =>

						if in_valid = '1' then
							
							header(header_idx) := in_seq;

							if header_idx /= header'high then
								header_idx := header_idx + 1;
							else 
								rfu2 := unsigned(header(15 downto 13));
								hdr_len_bits := unsigned('0' & header(12 downto 8)) * 8;
								rfu := unsigned(header(7 downto 5));

								out_data_hdr.md <= header(5);
								out_data_hdr.sn <= header(4);
								out_data_hdr.nesn <= header(3);

								hdr_type := unsigned("00" & header(1 downto 0));

								out_common_hdr.bits <= reverse_any_vector(header);
								out_common_hdr.length <= unsigned('0' & header(12 downto 8));
								out_common_hdr.pdu_llid <= hdr_type;
							
								if (hdr_type > BTLE_LLID_RESERVED) and (hdr_type <= BTLE_LLID_CONTROL) then

									if rfu2 = "000" and rfu = "000" then

										out_common_hdr.valid <= '1';

									end if;
								end if;

								out_common_hdr.decoded <= '1';
								state := STATE_IDLE;
								
							end if;
						end if;

					when others =>
					
						out_common_hdr	<= ( '0', '0', (others => '0'), (others => '0'), (others => '0') );
						out_adv_hdr		<= ( '0', '0' );
						out_data_hdr		<= ( '0', '0', '0' );
						
						state := STATE_IDLE;
						
				end case;		

			end if;
		end
	process;
end rtl;

