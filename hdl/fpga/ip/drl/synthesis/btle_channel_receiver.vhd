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
		channel_index : integer := 37;
		samples_per_bit : natural := 2
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;

		in_real:		in signed(15 downto 0);
		in_imag:		in signed(15 downto 0);
		in_valid:       in std_logic;
		in_timestamp:	in unsigned(63 downto 0);

		in_cts:         in std_logic;
		out_rts:        out std_logic;
		
		out_detected:   buffer std_logic;
		out_real:		out signed(15 downto 0);
		out_imag:		out signed(15 downto 0);
		out_valid:      out std_logic
	);
end btle_channel_receiver;


architecture rtl of btle_channel_receiver is

	type ch_state_type is ( 
							STATE_WAIT_DETECT, 
							STATE_WAIT_CTS, 
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
							STATE_SEND_PAYLOAD_COUNT,
							STATE_SEND_PAYLOAD,
							STATE_SEND_SAMPLE_COUNT,
							STATE_SEND_SAMPLES,
							STATE_SEND_NULL,
							STATE_SEND_PACKET_END
							);


	-- 10x32 bit words = maximum payload + CRC size of BTLE 
	type word_array is array(9 downto 0) of std_logic_vector (31 downto 0);

	signal state : ch_state_type;

	signal iq_to_mem : 					std_logic_vector(31 downto 0) := (others => '0');
	signal iq_to_mem_wr_addr :			unsigned(9 downto 0) := (others => '0');
	signal iq_to_mem_valid : 			std_logic := '0';

	signal iq_from_mem : 				std_logic_vector(31 downto 0) := (others => '0');
	signal iq_from_mem_rd_addr :		unsigned(9 downto 0) := (others => '0');

	signal demod_out_seq: std_logic := '0';
	signal demod_out_valid: std_logic := '0';

	signal preamble_aa:					std_logic_vector(BTLE_PREAMBLE_LEN + BTLE_AA_LEN - 1 downto 0);
    signal aa_detected : 				std_logic := '0';
	signal aa_timestamp : 				unsigned (63 downto 0);

    signal dew_out_seq: std_logic := '0';
    signal dew_out_valid: std_logic := '0';

	signal soh: std_logic := '0';		-- Start of header this cycle
	signal sop: std_logic := '0';		-- Start of payload this cycle
	
	signal header_decoded: std_logic := '0';
	signal header_valid: std_logic := '0';
	signal header_bits: std_logic_vector (15 downto 0);
	signal header_pdu_type : unsigned (3 downto 0);
	signal header_length: unsigned (5 downto 0);
	signal header_tx_addr : std_logic;
	signal header_rx_addr : std_logic;

	signal crc_result : std_logic_vector (23 downto 0);
	signal crc_decoded: std_logic := '0';
	signal crc_valid : std_logic := '0';
	
begin

	iq_memory:
	entity work.btle_dpram
	port map(
		clock			=> 	clock,
		reset			=>	reset,	
		in_wr_data		=> 	iq_to_mem,
		in_wr_addr		=>	iq_to_mem_wr_addr,
		in_wr_en		=>	iq_to_mem_valid,
		in_rd_addr		=>	iq_from_mem_rd_addr,
		out_rd_data		=>  iq_from_mem
	);

	demod: 
	entity work.btle_demod_matched 
	port map (
    	clock => clock,
    	reset => reset,
        in_real => in_real,
        in_imag => in_imag,
        in_valid => in_valid,
        out_bit => demod_out_seq,
        out_valid => demod_out_valid
  	);

   	detect: 
   	entity work.btle_aa_detector 

	generic map(num_channels => 1, num_addresses => BTLE_MAXIMUM_AA_MEMORY)
   	port map (
    	clock => clock,
    	reset => reset,
		in_seq => demod_out_seq,
		in_valid => demod_out_valid,
		in_ch_index => 0,
		in_preamble_aa => (others => '0'),
		in_aa_valid => '0',
		out_preamble_aa => preamble_aa,
		out_detected => aa_detected
	);

	dewhiten:
	entity work.btle_dewhitener
	generic map(channel => channel_index)
	port map (
		clock => clock,
		reset => reset,
		in_restart => soh,
		in_seq => demod_out_seq,
		in_valid => demod_out_valid,
		out_seq => dew_out_seq,
		out_valid => dew_out_valid
	);

	hdr_decode:
	entity work.btle_adv_header
	port map(
		clock			=>	clock,
		reset			=>	reset,
		in_soh		=>	soh,
		in_seq			=>	dew_out_seq,
		in_valid		=>	dew_out_valid,
		out_decoded		=>	header_decoded,
		out_valid		=>	header_valid,
		out_bits        =>  header_bits,
		out_pdu_type	=>  header_pdu_type,	-- out unsigned (3 downto 0);
		out_length		=>	header_length,		--out unsigned (5 downto 0);
		out_tx_addr		=>  header_tx_addr, 	
		out_rx_addr		=>	header_rx_addr
	);


	crc_calc:	entity work.btle_crc
	port map(
		clock			=>	clock,
		reset			=>	reset,
		in_soh			=>	soh,
		in_sop			=>	sop,
		in_payload_len	=>	header_length,
		in_seq			=> 	dew_out_seq,
		in_valid		=>	dew_out_valid,
		out_crc			=>	crc_result,
		out_decoded		=>	crc_decoded,
		out_valid		=>	crc_valid
	);
	

	detector:
	process(clock, reset)
		begin
			if reset = '1' then
				out_detected <= '0';
			elsif rising_edge(clock) then
				out_detected <= aa_detected;
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


	burst_fsm:
	process(clock, reset) is

		variable payload_bits: word_array;
		variable sub_count : integer := 0;
		variable sub_target : integer := 0;
		variable total_count : integer := 0;

		begin

			if reset = '1' then
			
				out_rts <= '0';
				out_real <= (others => '0');
				out_imag <= (others => '0');
				out_valid <= '0';
				soh <= '0';
				sop <= '0';
	
				iq_from_mem_rd_addr <= (others => '0');
				
				state <= STATE_WAIT_DETECT;
				
			elsif rising_edge(clock) then

				out_rts <= '0';
				out_real <= (others => '0');
				out_imag <= (others => '0');
				out_valid <= '0';
				soh <= '0';
				sop <= '0';

				case state is
				
					when STATE_WAIT_DETECT =>

						if aa_detected = '1' then

							-- Save the timetamp and the 'read' buffer position when the AA was detected
							-- so that symbols (including some pretrigger) can be reported
							
							aa_timestamp <= in_timestamp;
							iq_from_mem_rd_addr <= (iq_to_mem_wr_addr + 1024 - BTLE_DEMOD_TAP_POSITION) mod 1024;
							soh <= '1';

							state <= STATE_RX_HEADER;

						end if;
						
					when STATE_RX_HEADER =>

						if header_decoded = '1' then

							if header_valid = '1' then

								-- The header was decoded OK
								-- -> Signal start of payload (SOP)
								-- -> Attempt to decode the payload and CRC
								
								sop <= '1';

								-- How many bits to receive payload + CRC?
								-- Accumulate in groups of 32 slv for ease of processing
								
 								sub_count := 0;
 								sub_target := (to_integer(header_length) * 8) + BTLE_CRC_LEN;

								for w in 0 to payload_bits'length - 1  loop
									payload_bits(w) := (others => '0');
								end loop;
								
								state <= STATE_RX_PAYLOAD;

							else

								-- Header decode failed
								-- -> No point decoding the payload as have no reliable idea how long it is
								-- -> Start reporting with known information.
								
								state <= STATE_START_REPORT;

							end if;

						end if;
						
					when STATE_RX_PAYLOAD =>

						if crc_decoded = '1' then
							
							state <= STATE_START_REPORT;
							
						else
							if dew_out_valid = '1' then

								if sub_count < sub_target then

									-- bit 31 is lsb (received first) as per strange BTLE over the air spec
									
									payload_bits(sub_count / 32)(31 - (sub_count mod 32)) := dew_out_seq;
									sub_count := sub_count + 1;

								end if;
									
							end if;
						end if;

					when STATE_START_REPORT =>

						out_rts <= '1';

 						sub_count := 0;
 						sub_target := 0;
 						total_count := 0;
 						
						state <= STATE_WAIT_CTS;
						
					when STATE_WAIT_CTS =>

						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= x"5555";				
							out_real <= x"AAAA";								
							out_valid <= '1';
							total_count := total_count + 1;

							state <= STATE_SEND_PROTOCOL_VERSION;
							
						end if;

					when STATE_SEND_PROTOCOL_VERSION =>

						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= x"0000";			
							out_real <= x"0001";								
							out_valid <= '1';
 							total_count := total_count + 1;

							state <= STATE_SEND_BOARD_CHANNEL_ID;
							
						end if;

					when STATE_SEND_BOARD_CHANNEL_ID =>

						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= x"0000";				
							out_real <= to_signed(channel_index, out_real'length);			
							out_valid <= '1';
 							total_count := total_count + 1;

							state <= STATE_SEND_TIMESTAMP1;

						end if;

					when STATE_SEND_TIMESTAMP1 =>

						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= signed(aa_timestamp(63 downto 48));			
							out_real <= signed(aa_timestamp(47 downto 32));			
							out_valid <= '1';							
 							total_count := total_count + 1;

							state <= STATE_SEND_TIMESTAMP2;

						end if;

					when STATE_SEND_TIMESTAMP2 =>

						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= signed(aa_timestamp(31 downto 16));			
							out_real <= signed(aa_timestamp(15 downto 0));			
							out_valid <= '1';
							total_count := total_count + 1;
							
							state <= STATE_SEND_DECODE_STATUS;
						end if;

					when STATE_SEND_DECODE_STATUS =>

						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= "00000000000000" & crc_valid & header_valid;
							out_real <= signed(header_bits);
							out_valid <= '1';
 							total_count := total_count + 1;

 							state <= STATE_SEND_PREAMBLE;
 						end if;

 					when STATE_SEND_PREAMBLE =>

						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= (others => '0');
							out_real <= "00000000" & signed(preamble_aa(39 downto 32));
							out_valid <= '1';
 							total_count := total_count + 1;

 							state <= STATE_SEND_AA;
						end if;

 					when STATE_SEND_AA =>

						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= signed(preamble_aa(31 downto 16));
							out_real <= signed(preamble_aa(15 downto 0));
							out_valid <= '1';
 							total_count := total_count + 1;

 							state <= STATE_SEND_PAYLOAD_COUNT;
						end if;
 					
					when STATE_SEND_PAYLOAD_COUNT =>

						out_rts <= '1';

						if in_cts = '1' then

							if header_valid = '1' then

								out_imag <= (others => '0');
								out_real <= signed(resize(header_length , out_real'length));
								sub_count := 0;

								-- Payload plus CRC length (+3) rounded up to whole number of 32bit words (+3/4)
								-- Maximum is 40 bytes (37 + 3) = 10 words.
								
								sub_target := (to_integer(header_length) + 3 + 3) / 4;
								
								state <= STATE_SEND_PAYLOAD;

							else

								out_imag <= (others => '0');
								out_real <= (others => '0');
								state <= STATE_SEND_SAMPLE_COUNT;
								
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

								state <= STATE_SEND_SAMPLE_COUNT;

							end if;
						end if;
						
					when STATE_SEND_SAMPLE_COUNT =>

						out_rts <= '1';

						if in_cts = '1' then

							-- How amny samples to send?
							-- If header and CRC were correct then just send enough to cover the burst plus
							-- pre/post trigger.
							-- Otherwise, send the worst case.

							if header_valid = '1' and crc_valid = '1' then
								sub_target := BTLE_SAMPLES_PER_SYMBOL * (BTLE_TRIGGER_LEN + BTLE_PREAMBLE_LEN + BTLE_AA_LEN + BTLE_HEADER_LEN + (to_integer(header_length) * 8) + BTLE_CRC_LEN + BTLE_TRIGGER_LEN);
							else
								sub_target := BTLE_MEMORY_LEN;
							end if;

							out_imag <= x"0000";
							out_real <= to_signed(sub_target, out_real'length);
							out_valid <= '1';
 							total_count := total_count + 1;

							sub_count := 0;


 							state <= STATE_SEND_SAMPLES;
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
									state <= STATE_SEND_NULL;
									
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

								state <= STATE_SEND_PACKET_END;

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
							state <= STATE_WAIT_DETECT;

						end if;

					when others =>

						sub_count := 0;
						total_count := 0;
						state <= STATE_WAIT_DETECT;
				
				end case;

			end if;
		end
	process;

	
end rtl;




