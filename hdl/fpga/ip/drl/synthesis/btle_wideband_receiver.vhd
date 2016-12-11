--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.btle_common.all;

entity btle_wideband_receiver is
	generic(
		samples_per_bit : natural := 2;
		num_channels : natural := 16
	);
	port(
		clock: 			in std_logic;
		reset:			in std_logic;
		enable:			in std_logic;
		
		in_wb_real:		in signed(15 downto 0);
		in_wb_imag:		in signed(15 downto 0);
		in_wb_valid:	in std_logic;
		in_timestamp:   in unsigned(63 downto 0);

		out_real:		out signed(15 downto 0);				
		out_imag: 		out signed(15 downto 0);
		out_valid:		out std_logic;
		out_detected:   out std_logic
	);

end btle_wideband_receiver;


architecture rtl of btle_wideband_receiver is

	type bus_array is array(num_channels - 1 downto 0) of sample_t;
	
	type ch_array_type is array (0 to 15) OF integer;
	constant ch_idx_array : ch_array_type := (5, 6, 7, 8, 9, 10, 38, 40, 40, 40, 37, 0, 1, 2, 3, 4 );

	type wb_state_type is ( 
							STATE_WAIT_RTS, 
							STATE_SENDING );
	signal state : wb_state_type;

	signal wideband_input : iq_bus_t;
	signal fft_output: tdm_iq_bus_t;

	signal demod_ch_input: btle_ch_info_t;
	signal demod_iq_input: tdm_iq_bus_t;
	signal demod_bit_output: tdm_bit_bus_t;

	signal mapper_bit_input: tdm_bit_bus_t;
	signal mapper_bit_output: tdm_bit_bus_t;
	signal mapper_ch_output: btle_ch_info_t;

	signal aa_bit_input: tdm_bit_bus_t;
	signal aa_ch_input: btle_ch_info_t;

	signal aa_bit_output: tdm_bit_bus_t;
	signal aa_ch_output: btle_ch_info_t;
	signal aa_detect_results: aa_detect_results_t;


	signal ch_in_bit:			std_logic;
	signal ch_in_bit_valid:		std_logic_vector(num_channels - 1 downto 0);
	signal ch_in_aa_detected:	std_logic_vector(num_channels - 1 downto 0);
	signal ch_in_preamble_aa:	preamble_aa_t;


	signal ch_in_real: 			sample_t;
	signal ch_in_imag: 			sample_t;
	signal ch_in_valid:			std_logic_vector(num_channels - 1 downto 0);
	signal ch_in_cts:			std_logic_vector(num_channels - 1 downto 0);

	signal ch_out_rts:			std_logic_vector(num_channels - 1 downto 0);
	signal ch_out_real: 		bus_array;
	signal ch_out_imag:			bus_array;
	signal ch_out_valid:    	std_logic_vector(num_channels - 1 downto 0);

	signal rx_timestamp:	unsigned(63 downto 0);


--	attribute preserve : boolean;
--	attribute preserve of ch_in_real : signal is true;
--	attribute preserve of ch_in_imag : signal is true;
--	attribute preserve of ch_in_valid : signal is true;
--	attribute preserve of ch_in_cts : signal is true;
--	attribute preserve of ch_out_rts : signal is true;
--	attribute preserve of ch_out_real : signal is true;
--	attribute preserve of ch_out_imag : signal is true;
--	attribute preserve of ch_out_valid : signal is true;
--	attribute preserve of ch_out_detected : signal is true;

--	attribute syn_keep : boolean;
--	attribute syn_keep of ch_in_real : signal is true;
--	attribute syn_keep of ch_in_imag : signal is true;
--	attribute syn_keep of ch_in_valid : signal is true;
--	attribute syn_keep of ch_in_cts : signal is true;
--	attribute syn_keep of ch_out_rts : signal is true;
--	attribute syn_keep of ch_out_real : signal is true;
--	attribute syn_keep of ch_out_imag : signal is true;
--	attribute syn_keep of ch_out_valid : signal is true;
--	attribute syn_keep of ch_out_detected : signal is true;

begin

	rx_timestamp <= in_timestamp;

	demod:
	entity work.btle_demod_matched 
		generic map (
			samples_per_bit => samples_per_bit, 
			max_channels => num_channels
		)
		port map (
    		clock 		=> clock,
    		reset 		=> reset,
        	in_iq_bus 	=> demod_iq_input,
        	out_bit_bus => demod_bit_output
  		);

	mapper: entity work.btle_channel_mapper
		generic map (
			max_channels => num_channels
		)
		port map (
			clock		=> clock,
			reset		=> reset,
			rf_config	=> "00",
			in_bit_bus	=> mapper_bit_input,
			out_ch_info	=> mapper_ch_output,
			out_bit_bus	=> mapper_bit_output
		);
			
  	aa_detect: 
   	entity work.btle_aa_detector 
		generic map (
			num_timeslots => num_channels, 
			max_addresses => BTLE_MAXIMUM_AA_MEMORY
		)
   		port map (
    		clock => clock,
    		reset => reset,
    	
			in_bit_bus => aa_bit_input,
			in_ch_info => aa_ch_input,

			in_cfg.valid => '0',
			in_cfg.preamble_aa => (others => '0'),

			out_bit_bus => aa_bit_output,
			out_ch_info => aa_ch_output,
			out_detect_results => aa_detect_results
		);



	demod_to_mapper:
	process(clock, reset) is
		begin
			if reset = '1' then
			
				mapper_bit_input.seq <= '0';
				mapper_bit_input.valid <= '0';
				mapper_bit_input.timeslot <= (others => '0');

			elsif rising_edge(clock) then

				mapper_bit_input <= demod_bit_output;
				
			end if;
		end
	process;	


	mapper_to_aa:
	process(clock, reset) is
		begin
			if reset = '1' then

				aa_bit_input.seq <= '0';
				aa_bit_input.valid <= '0';
				aa_bit_input.timeslot <= (others => '0');

				aa_ch_input.ch_idx <= to_unsigned(BTLE_INVALID_CHANNEL, aa_ch_input.ch_idx'length);
				aa_ch_input.adv <= '0';
				aa_ch_input.valid <= '0';

			elsif rising_edge(clock) then

				aa_bit_input <= mapper_bit_output;
				aa_ch_input <= mapper_ch_output;
					
			end if;
		end
	process;	


	fft_based: if num_channels > 1 generate

		rx_bank : for i in 0 to num_channels - 1 
		generate
		
			ch_rx: entity work.btle_channel_receiver
				generic map (
					channel_index => ch_idx_array(i), 
					samples_per_bit => samples_per_bit
				)
				port map (
					clock => 			clock,
					reset => 			reset,

					in_real => 			ch_in_real,
					in_imag => 			ch_in_imag,
					in_valid => 		ch_in_valid(i),
					in_timestamp =>	rx_timestamp,

					in_demod_seq => 	ch_in_bit,
					in_demod_valid =>	ch_in_bit_valid(i),
					
					in_cts => 			ch_in_cts(i),
					out_rts =>			ch_out_rts(i),

					in_preamble_aa =>	ch_in_preamble_aa,
					in_aa_detected => 	ch_in_aa_detected(i),

					out_real => 		ch_out_real(i),
					out_imag => 		ch_out_imag(i),
					out_valid => 		ch_out_valid(i)
				);	

		end generate;

    	fft : entity work.btle_fft_streamer
			generic map (
				order => num_channels
			)
    		port map (
				clock 			=> clock,
				reset 			=> reset,
				enable			=> enable,
				in_iq_bus 		=> wideband_input,
				out_iq_bus		=> fft_output
    		);


		fft_input:
		process(clock, reset) is
			begin
				if reset = '1' then

					wideband_input.real <= (others => '0');
					wideband_input.imag <= (others => '0');
					wideband_input.valid <= '0';

				elsif rising_edge(clock) then

					wideband_input.real <= in_wb_real;
					wideband_input.imag <= in_wb_imag;
					wideband_input.valid <= in_wb_valid;
					
				end if;
			end
		process;


		fft_to_demod:
		process(clock, reset) is
			begin
				if reset = '1' then

					demod_iq_input.real <= (others => '0');
					demod_iq_input.imag <= (others => '0');
					demod_iq_input.valid <= '0';
					demod_iq_input.timeslot <= (others => '0');

				elsif rising_edge(clock) then

					demod_iq_input <= fft_output;
					
				end if;
			end
		process;	


		aa_to_ch:
		process(clock, reset) is
			begin
				if reset = '1' then

					ch_in_bit <= '0';
					ch_in_bit_valid <= (others => '0');

					ch_in_aa_detected <= (others => '0');
					ch_in_preamble_aa <= (others => '0');
					
					ch_in_real <= (others => '0');
					ch_in_imag <= (others => '0');
					ch_in_valid <= (others => '0');

				elsif rising_edge(clock) then

					ch_in_valid <= (others => '0');	
					
					if fft_output.valid = '1' then

						ch_in_real <= fft_output.real;
						ch_in_imag <= fft_output.imag;
						ch_in_valid(to_integer(fft_output.timeslot)) <= '1';

					end if;

					ch_in_bit <= '0';
					ch_in_bit_valid <= (others => '0');
					ch_in_aa_detected <= (others => '0');
					ch_in_preamble_aa <= (others => '0');

					if aa_bit_output.valid = '1' then

						ch_in_bit <= aa_bit_output.seq;
						ch_in_bit_valid(to_integer(aa_bit_output.timeslot)) <= '1';

						if aa_detect_results.detected = '1' then

							ch_in_aa_detected(to_integer(aa_bit_output.timeslot)) <= '1';
							ch_in_preamble_aa <= aa_detect_results.preamble_aa;
							
						end if;

					end if;
					
				end if;
			end
		process;

		ch_output:
		process(clock, reset) is

			variable active_channel: integer := 0;
			
			begin
				if reset = '1' then

					ch_in_cts <= (others => '0');
					out_real <= (others => '0');
					out_imag <= (others => '0');
					out_valid <= '0';

					state <= STATE_WAIT_RTS;
					
				elsif rising_edge(clock) then

					ch_in_cts <= (others => '0');
					out_real <= (others => '0');
					out_imag <= (others => '0');
					out_valid <= '0';

					case state is

						when STATE_WAIT_RTS =>

							for ch in 0 to num_channels - 1 loop

								if ch_out_rts(ch) = '1' then

									-- Found channel to send
									-- -> Store and transition

									ch_in_cts(ch) <= '1';
									active_channel := ch;
									state <= STATE_SENDING;
									exit;
									
								end if;
									
							end loop;

						when STATE_SENDING =>

							if ch_out_rts(active_channel) = '1' then

								ch_in_cts(active_channel) <= '1';

								if ch_out_valid(active_channel) = '1' then
						
									out_real <= ch_out_real(active_channel);
									out_imag <= ch_out_imag(active_channel);
									out_valid <= '1';	

								end if;
								
							else

								-- Channel released RTS, so is finished sending
								-- -> Wait for the next one
								
								state <= STATE_WAIT_RTS;

							end if;

						when others =>

							state <= STATE_WAIT_RTS;

					end case;
					
				end if;
			end
		process;

	else generate

		single_rx: entity work.btle_channel_receiver
			generic map(channel_index => 37, samples_per_bit => samples_per_bit)
			port map(
				clock => 		clock,
				reset => 		reset,

				in_real => 		ch_in_real,
				in_imag => 		ch_in_imag,
				in_valid => 	ch_in_valid(0),
				in_timestamp =>	rx_timestamp,

				in_demod_seq => ch_in_bit,
				in_demod_valid => ch_in_bit_valid(0),

				in_cts => 		ch_in_cts(0),
				out_rts =>		ch_out_rts(0),

				in_preamble_aa =>	aa_detect_results.preamble_aa,
				in_aa_detected =>   ch_in_aa_detected(0),

				out_real => 	ch_out_real(0),
				out_imag => 	ch_out_imag(0),
				out_valid => 	ch_out_valid(0)
			);



		input_to_demod:
		process(clock, reset) is
			begin
				if reset = '1' then

					demod_iq_input.real <= (others => '0');
					demod_iq_input.imag <= (others => '0');
					demod_iq_input.valid <= '0';
					demod_iq_input.timeslot <= (others => '0');

				elsif rising_edge(clock) then

					demod_iq_input.real  <= in_wb_real;
					demod_iq_input.imag  <= in_wb_imag;
					demod_iq_input.valid <= in_wb_valid;
					demod_iq_input.timeslot <= (others => '0');
					
				end if;
			end
		process;


		aa_to_ch:
			process(clock, reset) is
			begin
				if reset = '1' then

					ch_in_bit <='0';
					ch_in_bit_valid(0) <= '0';

					ch_in_aa_detected <= (others => '0');
					ch_in_preamble_aa <= (others => '0');
					
					ch_in_real  <= (others => '0');
					ch_in_imag  <= (others => '0');
					ch_in_valid <= (others => '0');

				elsif rising_edge(clock) then

					ch_in_real  <= in_wb_real;
					ch_in_imag  <= in_wb_imag;
					ch_in_valid(0) <= in_wb_valid;

					ch_in_bit <= '0';
					ch_in_bit_valid <= (others => '0');
					ch_in_aa_detected <= (others => '0');
					ch_in_preamble_aa <= (others => '0');

					if aa_bit_output.valid = '1' then

						ch_in_bit <= aa_bit_output.seq;
						ch_in_bit_valid(to_integer(aa_bit_output.timeslot)) <= '1';

						if aa_detect_results.detected = '1' then

							ch_in_aa_detected(0) <= '1';
							ch_in_preamble_aa <= aa_detect_results.preamble_aa;
							
						end if;

					end if;

				end if;
			end
		process;

		single_output:
		process(clock, reset) is
			begin
				if reset = '1' then

					ch_in_cts <= (others => '1');
					out_real <= (others => '0');
					out_imag <= (others => '0');
					out_valid <= '0';

				elsif rising_edge(clock) then

					ch_in_cts <= (others => '1');
					
					out_real <= ch_out_real(0);
					out_imag <= ch_out_imag(0);
					out_valid <= ch_out_valid(0);
					
				end if;
			end
		process;

	end generate;

	ch_detector:
	process(clock, reset) is
		variable tmp : std_logic;
		begin
			
			if reset = '1' then

				out_detected <= '0';

			elsif rising_edge(clock) then

				out_detected <= aa_detect_results.detected;

			end if;
		end
	process;

end rtl;
