--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_complex.all;
use work.btle_common.all;


entity btle_channel_receiver is
	generic(
		samples_per_bit : natural := 2
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;

		in_real:		in signed(15 downto 0);
		in_imag:		in signed(15 downto 0);
		in_valid:       in std_logic;
		in_timestamp:	in unsigned(63 downto 0);

		in_demod_seq:	in std_logic;
		in_demod_valid:	in std_logic;

		in_ch_info:		in btle_ch_info_t;

		in_cts:         in std_logic;
		out_rts:        out std_logic;

		in_aa_detect:	in aa_crc_config_t;
		in_rf_config:	in unsigned (1 downto 0);
		in_ch_idx:      in channel_idx_t;

		in_cts_dch:		in std_logic;
		out_rts_dch:	out std_logic;
		out_dch_config:	out aa_crc_config_t;
		
		out_real:		out signed(15 downto 0);
		out_imag:		out signed(15 downto 0);
		out_valid:      out std_logic
	);
end btle_channel_receiver;


architecture rtl of btle_channel_receiver is


	-- 10x32 bit words = maximum payload + CRC size of BTLE 
	type word_array is array(9 downto 0) of std_logic_vector (31 downto 0);




	signal iq_to_mem : 					std_logic_vector(31 downto 0) := (others => '0');
	signal iq_to_mem_wr_addr :			unsigned(9 downto 0) := (others => '0');
	signal iq_to_mem_valid : 			std_logic := '0';

	signal iq_from_mem : 				std_logic_vector(31 downto 0) := (others => '0');
	signal iq_from_mem_rd_addr :		unsigned(9 downto 0) := (others => '0');

	signal demod_out_seq: std_logic := '0';
	signal demod_out_valid: std_logic := '0';


    signal dew_out_seq: std_logic := '0';
    signal dew_out_valid: std_logic := '0';

	signal dew_to_modules_seq: std_logic;
	signal dew_to_modules_valid: std_logic;

	signal soh: std_logic := '0';		-- Start of header this cycle
	signal sop: std_logic := '0';		-- Start of payload this cycle
	


	signal crc_result : std_logic_vector (23 downto 0);
	signal crc_decoded: std_logic := '0';
	signal crc_valid : std_logic := '0';

	signal common_header: common_header_t;
	signal adv_header: adv_header_t;
	signal data_header: data_header_t;

	signal aa_channel_info: btle_ch_info_t;
	signal aa_detection_memory: aa_crc_config_t;
	signal payload_bits: word_array;
	
begin

	iq_memory:
	entity work.btle_dpram
		port map (
			clock			=> 	clock,
			reset			=>	reset,	
			in_wr_data		=> 	iq_to_mem,
			in_wr_addr		=>	iq_to_mem_wr_addr,
			in_wr_en		=>	iq_to_mem_valid,
			in_rd_addr		=>	iq_from_mem_rd_addr,
			out_rd_data		=>  iq_from_mem
		);

	dewhiten:
	entity work.btle_dewhitener
		port map (
			clock => clock,
			reset => reset,
			in_restart => soh,
			in_seq => demod_out_seq,
			in_valid => demod_out_valid,
			in_ch_idx => in_ch_idx,
			out_seq => dew_out_seq,
			out_valid => dew_out_valid
		);

	adv_hdr_decode:
	entity work.btle_adv_header
		port map (
			clock			=>	clock,
			reset			=>	reset,
			in_soh			=>	soh,
			in_seq			=>	dew_to_modules_seq,
			in_valid		=>	dew_to_modules_valid,
			in_ch_info		=>	aa_channel_info,
			out_common_hdr	=>	common_header,
			out_adv_hdr     =>  adv_header,
			out_data_hdr	=>  data_header
		);


	crc_calc:
	entity work.btle_crc
		port map(
			clock			=>	clock,
			reset			=>	reset,
			in_soh			=>	soh,
			in_sop			=>	sop,
			in_payload_len	=>	common_header.length,
			in_seq			=> 	dew_to_modules_seq,
			in_valid		=>	dew_to_modules_valid,
			in_seed			=>	aa_detection_memory.crc_init,
			out_crc			=>	crc_result,
			out_decoded		=>	crc_decoded,
			out_valid		=>	crc_valid
		);
	

	bits_in:
	process(clock, reset) is
		begin
			if reset = '1' then

				demod_out_seq <= '0';
	 			demod_out_valid <= '0';
	
			elsif rising_edge(clock) then

				demod_out_valid <= '0';
				
				if in_demod_valid = '1' then

					demod_out_seq <= in_demod_seq;
					demod_out_valid <= '1';

				end if;
			end if;
		end
	process;


	dewhiten_out:
	process(clock, reset) is
		begin
			if reset = '1' then

				dew_to_modules_seq <= '0';
	 			dew_to_modules_valid <= '0';
	
			elsif rising_edge(clock) then

				dew_to_modules_valid <= '0';
				
				if dew_out_valid = '1' then

					dew_to_modules_seq <= dew_out_seq;
					dew_to_modules_valid <= '1';

				end if;
			end if;
		end
	process;


	memory_in: 
	process(clock, reset) is
		begin
			if reset = '1' then

				iq_to_mem <= (others => '0');
				iq_to_mem_wr_addr <= (others => '0');
	 			iq_to_mem_valid <= '0';
	
			elsif rising_edge(clock) then

				iq_to_mem_valid <= '0';

				if in_valid = '1' then		
					
 					iq_to_mem <=  std_logic_vector(in_real & in_imag);
					iq_to_mem_valid <= '1';

					if iq_to_mem_wr_addr = 1023 then
						iq_to_mem_wr_addr <= to_unsigned(0, iq_to_mem_wr_addr'length);
					else
						iq_to_mem_wr_addr <= iq_to_mem_wr_addr + 1;
					end if;
				end if;				
			end if;
		end 
	process;




	config_dch_fsm:
	process(clock, reset) is

		type dch_state_t is ( STATE_DCH_WAIT_CONNECT, STATE_DCH_WAIT_CTS );
		variable dch_state : dch_state_t;

		begin
			if reset = '1' then

				out_rts_dch <= '0';
				out_dch_config <= ( '0', (others => '0'), (others => '0') );

				dch_state := STATE_DCH_WAIT_CONNECT;
				
			elsif rising_edge(clock) then

				out_rts_dch <= '0';
				out_dch_config <= ( '0', (others => '0'), (others => '0') );

				case dch_state is
				
					when STATE_DCH_WAIT_CONNECT =>

						-- If the CRC is good, then check for the CONNECT message which contains a new
						-- Access Address and CRC Initial value for the data channels

						if crc_decoded = '1' and crc_valid = '1' and common_header.pdu_llid = to_unsigned(BTLE_ADV_PDU_CONNECT_REQ, common_header.pdu_llid'length) then

							out_rts_dch <= '1';
							dch_state := STATE_DCH_WAIT_CTS;
							
						end if;

					when STATE_DCH_WAIT_CTS =>

						out_rts_dch <= '1';

						if in_cts_dch = '1' then

							out_dch_config.valid <= '1';
							out_dch_config.crc_init <= payload_bits(4)(31 downto 8);

							if payload_bits(3)(31) = '1' then
								out_dch_config.preamble_aa <= "10101010" & payload_bits(3);
							else
								out_dch_config.preamble_aa <= "01010101" & payload_bits(3);
							end if; 
						
							dch_state := STATE_DCH_WAIT_CONNECT;

						end if;
						
					when others =>

						dch_state := STATE_DCH_WAIT_CONNECT;
				
				end case;
					
			end if;
		end
	process;




	burst_fsm:
	process(clock, reset) is

		type ch_state_t is (	STATE_WAIT_DETECT, 
								STATE_WAIT_CTS, 
								STATE_TRIGGER_HEADER,
								STATE_RX_HEADER,
								STATE_RX_PAYLOAD,
								STATE_START_REPORT,
								STATE_SEND_PROTOCOL_VERSION,
								STATE_SEND_BOARD_CHANNEL_ID,
								STATE_SEND_TIMESTAMP1,
								STATE_SEND_TIMESTAMP2,
								STATE_SEND_DECODE_STATUS,
								STATE_SEND_PREAMBLE,
								STATE_SEND_AA,
								STATE_SEND_CONNECT_CRC,
								STATE_SEND_CONNECT_AA,
								STATE_SEND_PAYLOAD_COUNT,
								STATE_SEND_PAYLOAD,
								STATE_SEND_SAMPLE_COUNT,
								STATE_SEND_SAMPLES,
								STATE_SEND_NULL,
								STATE_SEND_PACKET_END );

		variable state : ch_state_t;

		variable sub_count : integer := 0;
		variable sub_target : integer := 0;
		variable total_count : integer := 0;

		variable aa_timestamp : unsigned (63 downto 0);

		
		begin

			if reset = '1' then

				aa_detection_memory <= ( '0', (others => '0'), (others => '0') );		
				aa_timestamp := (others => '0');
			
				out_rts <= '0';
				out_real <= (others => '0');
				out_imag <= (others => '0');
				out_valid <= '0';
				soh <= '0';
				sop <= '0';

				iq_from_mem_rd_addr <= (others => '0');
				
				state := STATE_WAIT_DETECT;
				
			elsif rising_edge(clock) then

				out_rts <= '0';
				out_real <= (others => '0');
				out_imag <= (others => '0');
				out_valid <= '0';
				soh <= '0';
				sop <= '0';

				case state is
				
					when STATE_WAIT_DETECT =>

						if in_aa_detect.valid = '1' and in_ch_info.valid = '1' then

							-- Save the timetamp and the 'read' buffer position when the AA was detected
							-- so that symbols (including some pretrigger) can be reported

							aa_detection_memory <= in_aa_detect;
							aa_timestamp := in_timestamp;
							aa_channel_info <= in_ch_info;

							iq_from_mem_rd_addr <= (iq_to_mem_wr_addr + 1024 - BTLE_DEMOD_TAP_POSITION) mod 1024;

							-- This is the last bit of the Access Address, so wait for the next bit before
							-- starting to receive the header
							
							state := STATE_TRIGGER_HEADER;

						end if;

					when STATE_TRIGGER_HEADER =>

						if in_demod_valid = '1' then

							soh <= '1';
							state := STATE_RX_HEADER;

						end if;
							
					when STATE_RX_HEADER =>

						if common_header.decoded = '1' then

							if common_header.valid = '1' then

								-- The header was decoded OK
								-- -> Signal start of payload (SOP)
								-- -> Attempt to decode the payload and CRC
								
								sop <= '1';

								-- How many bits to receive payload + CRC?
								-- Accumulate in groups of 32 slv for ease of processing
								
 								sub_count := 0;
 								sub_target := (to_integer(common_header.length) * 8) + BTLE_CRC_LEN;

								for w in 0 to payload_bits'length - 1  loop
									payload_bits(w) <= (others => '0');
								end loop;
								
								state := STATE_RX_PAYLOAD;

							else

								-- Header decode failed
								-- -> No point decoding the payload as have no reliable idea how long it is
								-- -> Start reporting with known information.
								
								--state := STATE_START_REPORT;
								state := STATE_WAIT_DETECT;

							end if;

						end if;
						
					when STATE_RX_PAYLOAD =>

						if crc_decoded = '1' then

							if crc_valid = '1' then
							    state := STATE_START_REPORT;
							else
								state := STATE_WAIT_DETECT;
							end if;
							
						else
							if dew_to_modules_valid = '1' then

								if sub_count < sub_target then

									-- bit 31 is lsb (received first) as per strange BTLE over the air spec
									
									payload_bits(sub_count / 32)(31 - (sub_count mod 32)) <= dew_to_modules_seq;
									sub_count := sub_count + 1;

								end if;
									
							end if;
						end if;

					when STATE_START_REPORT =>

						out_rts <= '1';

 						sub_count := 0;
 						sub_target := 0;
 						total_count := 0;
 						
						state := STATE_WAIT_CTS;
						
					when STATE_WAIT_CTS =>

						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= x"5555";				
							out_real <= x"AAAA";								
							out_valid <= '1';
							total_count := total_count + 1;

							state := STATE_SEND_PROTOCOL_VERSION;
							
						end if;

					when STATE_SEND_PROTOCOL_VERSION =>

						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= x"0000";			
							out_real <= x"0001";								
							out_valid <= '1';
 							total_count := total_count + 1;

							state := STATE_SEND_BOARD_CHANNEL_ID;
							
						end if;

					when STATE_SEND_BOARD_CHANNEL_ID =>

						out_rts <= '1';
						
						if in_cts = '1' then

							--out_imag <= x"0000";	

							out_imag <= signed(resize(in_rf_config, out_imag'length)); 
							out_real <= signed(resize(in_ch_idx,    out_real'length));			
							out_valid <= '1';
 							total_count := total_count + 1;

							state := STATE_SEND_TIMESTAMP1;

						end if;

					when STATE_SEND_TIMESTAMP1 =>

						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= signed(aa_timestamp(63 downto 48));			
							out_real <= signed(aa_timestamp(47 downto 32));			
							out_valid <= '1';							
 							total_count := total_count + 1;

							state := STATE_SEND_TIMESTAMP2;

						end if;

					when STATE_SEND_TIMESTAMP2 =>

						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= signed(aa_timestamp(31 downto 16));			
							out_real <= signed(aa_timestamp(15 downto 0));			
							out_valid <= '1';
							total_count := total_count + 1;
							
							state := STATE_SEND_DECODE_STATUS;
						end if;

					when STATE_SEND_DECODE_STATUS =>

						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= "00000000000000" & crc_valid & common_header.valid;
							out_real <= signed(common_header.bits);
							out_valid <= '1';
 							total_count := total_count + 1;

 							state := STATE_SEND_PREAMBLE;
 						end if;

 					when STATE_SEND_PREAMBLE =>

						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= (others => '0');
							out_real <= "00000000" & signed(aa_detection_memory.preamble_aa(39 downto 32));
							out_valid <= '1';
 							total_count := total_count + 1;

 							state := STATE_SEND_AA;
						end if;

 					when STATE_SEND_AA =>

						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= signed(aa_detection_memory.preamble_aa(31 downto 16));
							out_real <= signed(aa_detection_memory.preamble_aa(15 downto 0));
							out_valid <= '1';
 							total_count := total_count + 1;

 							state := STATE_SEND_CONNECT_CRC;
 							
						end if;

					when STATE_SEND_CONNECT_CRC =>

						out_rts <= '1';

						if in_cts = '1' then
						
							if crc_valid = '1' and common_header.pdu_llid = to_unsigned(BTLE_ADV_PDU_CONNECT_REQ, common_header.pdu_llid'length) then

								out_imag <= "10000000" & signed(payload_bits(4)(31 downto 24));
								out_real <= signed(payload_bits(4)(23 downto 8));

							else

								out_imag <= (others => '0');
								out_real <= (others => '0');

							end if;

							out_valid <= '1';
 							total_count := total_count + 1;

 							state := STATE_SEND_CONNECT_AA;
 							
 						end if;


					when STATE_SEND_CONNECT_AA =>

						out_rts <= '1';

						if in_cts = '1' then
						
							if crc_valid = '1' and common_header.pdu_llid = to_unsigned(BTLE_ADV_PDU_CONNECT_REQ, common_header.pdu_llid'length) then

								out_imag <= signed(payload_bits(3)(31 downto 16));
								out_real <= signed(payload_bits(3)(15 downto 0));

							else

								out_imag <= (others => '0');
								out_real <= (others => '0');

							end if;

							out_valid <= '1';
 							total_count := total_count + 1;

 							state := STATE_SEND_PAYLOAD_COUNT;
 							
 						end if;
 					
					when STATE_SEND_PAYLOAD_COUNT =>

						out_rts <= '1';

						if in_cts = '1' then

							if common_header.valid = '1' then

								out_imag <= (others => '0');
								out_real <= signed(resize(common_header.length , out_real'length));
								sub_count := 0;

								-- Payload plus CRC length (+3) rounded up to whole number of 32bit words (+3/4)
								-- Maximum is 40 bytes (37 + 3) = 10 words.
								
								sub_target := (to_integer(common_header.length) + 3 + 3) / 4;
								
								state := STATE_SEND_PAYLOAD;

							else

								out_imag <= (others => '0');
								out_real <= (others => '0');
								state := STATE_SEND_SAMPLE_COUNT;
								
							end if;

							out_valid <= '1';
 							total_count := total_count + 1;
 							
						end if;

					when STATE_SEND_PAYLOAD =>

						out_rts <= '1';

						if in_cts = '1' then
							out_imag <= signed(payload_bits(sub_count)(31 downto 16));
							out_real <= signed(payload_bits(sub_count)(15 downto 0));
							out_valid <= '1';
							
 							total_count := total_count + 1;
 							sub_count := sub_count + 1;

							if sub_count >= sub_target then

								state := STATE_SEND_SAMPLE_COUNT;

							end if;
						end if;
						
					when STATE_SEND_SAMPLE_COUNT =>

						out_rts <= '1';

						if in_cts = '1' then

							-- How many samples to send?
							-- If header and CRC were correct then just send enough to cover the burst plus
							-- pre/post trigger.
							-- Otherwise, send the worst case.

							if common_header.valid = '1' and crc_valid = '1' then
								sub_target := BTLE_SAMPLES_PER_SYMBOL * (BTLE_TRIGGER_LEN + BTLE_PREAMBLE_LEN + BTLE_AA_LEN + BTLE_HEADER_LEN + (to_integer(common_header.length) * 8) + BTLE_CRC_LEN + BTLE_TRIGGER_LEN);
							else
								sub_target := BTLE_MEMORY_LEN;
							end if;

							out_imag <= x"0000";
							out_real <= to_signed(sub_target, out_real'length);
							out_valid <= '1';
 							total_count := total_count + 1;

							sub_count := 0;


 							state := STATE_SEND_SAMPLES;
 						end if;

					
					when STATE_SEND_SAMPLES =>

						out_rts <= '1';

						if in_cts = '1' then
						
							if iq_from_mem_rd_addr /= iq_to_mem_wr_addr then

								out_imag <= signed(iq_from_mem (15 downto  0));	
								out_real <= signed(iq_from_mem (31 downto 16));
								out_valid <= '1';

								if iq_from_mem_rd_addr = 1023 then
									iq_from_mem_rd_addr <= to_unsigned(0, iq_from_mem_rd_addr'length) ;
								else
									iq_from_mem_rd_addr <= iq_from_mem_rd_addr + 1;
								end if;

								sub_count := sub_count + 1;
								total_count := total_count + 1;

								if sub_count >= sub_target then

									sub_count := 0;
									state := STATE_SEND_NULL;
									
								end if;
								
							end if;

						end if;

					when STATE_SEND_NULL =>

						out_rts <= '1';

						if in_cts = '1' then
						
							out_real <= (others => '0');
							out_imag <= (others => '0');
							out_valid <= '1';

							total_count := total_count + 1;
								
							if total_count = 1023 then

								state := STATE_SEND_PACKET_END;

							end if;

						end if;

					when STATE_SEND_PACKET_END =>

						out_rts <= '1';

						if in_cts = '1' then
								
							out_imag <= x"AAAA";
							out_real <= x"5555";								
							out_valid <= '1';

							sub_count := 0;
							total_count := 0;
							state := STATE_WAIT_DETECT;

						end if;

					when others =>

						sub_count := 0;
						total_count := 0;
						state := STATE_WAIT_DETECT;
				
				end case;

			end if;
		end
	process;

	
end rtl;




