--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;
use work.btle_channel.all;

entity btle_rssi_manager is
	generic(
		max_timeslots : integer := 1;
		reports_per_second : integer := 50	
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		enable32m:      in std_logic;
		enable2m:       in std_logic;

		in_timestamp:	in unsigned(63 downto 0);
		in_rf_config:	in unsigned (1 downto 0);
		
		out_trigger_wb: out std_logic;
		out_trigger_nb: out std_logic;
		
		in_wb_results:  in rssi_results_t;
		in_nb_results:  in rssi_results_t;

		in_cts:			in std_logic;
		out_rts:        out std_logic;

		out_real:       out sample_t;
		out_imag:		out sample_t;
		out_valid:		out std_logic
	);
end btle_rssi_manager;


architecture rtl of btle_rssi_manager is

	signal rssi_to_mem : 				std_logic_vector(31 downto 0) := (others => '0');
	signal rssi_to_mem_wr_addr :		unsigned(9 downto 0) := (others => '0');
	signal rssi_to_mem_valid : 			std_logic := '0';

	signal rssi_from_mem : 				std_logic_vector(31 downto 0) := (others => '0');
	signal rssi_from_mem_rd_addr :		unsigned(9 downto 0) := (others => '0');
	
begin

	rssi_memory:
	entity work.btle_dpram
		port map (
			clock			=> 	clock,
			reset			=>	reset,	
			in_wr_data		=> 	rssi_to_mem,
			in_wr_addr		=>	rssi_to_mem_wr_addr,
			in_wr_en		=>	rssi_to_mem_valid,
			in_rd_addr		=>	rssi_from_mem_rd_addr,
			out_rd_data		=>  rssi_from_mem
		);


	rssi_trigger: 
	process(clock, reset) is		

		variable sample_count: integer;
		
		begin
			if reset = '1' then

				out_trigger_wb <= '0';
				out_trigger_nb <= '0';

				sample_count := 0;
				
			elsif rising_edge(clock) then

				out_trigger_wb <= '0';
				out_trigger_nb <= '0';

				if enable32m = '1' then

					sample_count := sample_count + 1;

					if sample_count = 640000 - 1 then

						out_trigger_wb <= '1';
						sample_count := 0;

					end if;

				end if;
			end if;
		end 
	process;


	report_fsm:
	process(clock, reset) is

		type rssi_state_t is (	STATE_COLLECT_WB_REPORTS, 
								STATE_WAIT_CTS, 
								STATE_TRIGGER_HEADER,
								STATE_SEND_PROTOCOL_VERSION,
								STATE_SEND_BOARD_CHANNEL_ID,
								STATE_SEND_TIMESTAMP1,
								STATE_SEND_TIMESTAMP2,
							    STATE_SEND_WB_REPORT_COUNT,
								STATE_SEND_WB_REPORTS,
								STATE_SEND_NULL,
								STATE_SEND_TT_RX,
								STATE_SEND_TT_REQ,
								STATE_SEND_TT_REPORT,
								STATE_SEND_PACKET_END );

		variable state : rssi_state_t := STATE_COLLECT_WB_REPORTS;

		variable sub_count: integer := 0;
		variable sub_target : integer := 0;
		variable total_count : integer := 0;

		variable rssi_timestamp : unsigned (63 downto 0);
		
		variable tt_rx : integer := 0;
		variable tt_req : integer := 0;
		variable tt_report : integer := 0;
		
		begin
			if reset = '1' then

				rssi_timestamp := (others => '0');

				sub_count := 0;
				sub_target := 0;
				total_count := 0;
				
				out_rts   <= '0';
				out_real  <= (others => '0');
				out_imag  <= (others => '0');
				out_valid <= '0';

				rssi_to_mem_wr_addr <= (others => '0');
				rssi_from_mem_rd_addr <= (others => '0');
				rssi_to_mem_valid <= '0';

			elsif rising_edge(clock) then

				out_rts   <= '0';
				out_real  <= (others => '0');
				out_imag  <= (others => '0');
				out_valid <= '0';

				rssi_to_mem_valid <= '0';

				case state is
				
					when STATE_COLLECT_WB_REPORTS =>

						if in_wb_results.valid = '1' then

							rssi_to_mem_wr_addr <= to_unsigned(sub_count, rssi_to_mem_wr_addr'length);
							rssi_to_mem <= std_logic_vector(in_wb_results.clipped & in_wb_results.rssi(30 downto 0));
							rssi_to_mem_valid <= '1';

							if sub_count = 0 then
								rssi_timestamp := in_timestamp;
							end if;

							if sub_count = reports_per_second - 1 then

								out_rts <= '1';

								tt_req := 0;
								sub_count := 0;
								total_count := 0;
								
								state := STATE_WAIT_CTS;
				
							else
								sub_count := sub_count + 1;
							end if;

						end if;

					--when STATE_COLLECT_NB_REPORTS =>

					
					--	rssi_to_mem_wr_addr <= reports_per_second + (nb_count * BTLE_FFT_SIZE) + in_nb_results.timeslot;

					when STATE_WAIT_CTS =>

 						tt_req := tt_req + 1;
						out_rts <= '1';

						if in_cts = '1' then

							tt_report := 0;
							out_imag <= x"5555";				
							out_real <= x"AAAA";								
							out_valid <= '1';
							total_count := total_count + 1;

							state := STATE_SEND_PROTOCOL_VERSION;
							
						end if;

					when STATE_SEND_PROTOCOL_VERSION =>

 						tt_report := tt_report + 1;
						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= x"0000";			-- Protocol ID
							out_real <= x"0002";			-- Message ID							
							out_valid <= '1';
 							total_count := total_count + 1;

							state := STATE_SEND_BOARD_CHANNEL_ID;
							
						end if;

					when STATE_SEND_BOARD_CHANNEL_ID =>

 						tt_report := tt_report + 1;
						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= signed(resize(in_rf_config, out_imag'length)); 
							out_real <= to_signed(0, out_real'length);			
							out_valid <= '1';
 							total_count := total_count + 1;

							state := STATE_SEND_TIMESTAMP1;

						end if;

					when STATE_SEND_TIMESTAMP1 =>

 						tt_report := tt_report + 1;
						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= signed(rssi_timestamp(63 downto 48));			
							out_real <= signed(rssi_timestamp(47 downto 32));			
							out_valid <= '1';							
 							total_count := total_count + 1;

							state := STATE_SEND_TIMESTAMP2;

						end if;

					when STATE_SEND_TIMESTAMP2 =>

 						tt_report := tt_report + 1;
						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= signed(rssi_timestamp(31 downto 16));			
							out_real <= signed(rssi_timestamp(15 downto 0));			
							out_valid <= '1';

							total_count := total_count + 1;

							state := STATE_SEND_WB_REPORT_COUNT;
						end if;


					when STATE_SEND_WB_REPORT_COUNT =>

	 					tt_report := tt_report + 1;
						out_rts <= '1';
						
						if in_cts = '1' then

							out_imag <= to_signed(reports_per_second, 32)(31 downto 16);			
							out_real <= to_signed(reports_per_second, 32)(15 downto 0);			
							out_valid <= '1';

							sub_count := 0;
							sub_target := reports_per_second;
							total_count := total_count + 1;

							state := STATE_SEND_WB_REPORTS;
						end if;				

					when STATE_SEND_WB_REPORTS =>

 						tt_report := tt_report + 1;
						out_rts <= '1';
						
						if in_cts = '1' then

							rssi_from_mem_rd_addr <= to_unsigned(sub_count, rssi_from_mem_rd_addr'length);

							out_imag <= signed(rssi_from_mem(31 downto 16));
							out_real <= signed(rssi_from_mem(15 downto 0));			
							out_valid <= '1';

							sub_count := sub_count + 1;
							total_count := total_count + 1;

							if sub_count >= sub_target then
								state := STATE_SEND_NULL;
							end if;
							
						end if;


					when STATE_SEND_NULL =>

 						tt_report := tt_report + 1;
						out_rts <= '1';

						if in_cts = '1' then
						
							out_imag <= (others => '0');
							out_real <= (others => '0');
							out_valid <= '1';
							total_count := total_count + 1;
								
							if total_count = 1020 then

								state := STATE_SEND_TT_RX;

							end if;

						end if;


					when STATE_SEND_TT_RX =>

 						tt_report := tt_report + 1;
						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= to_signed(0, 32)(31 downto 16);          -- This is unused right now, but useful to keep
							out_real <= to_signed(0, 32)(15 downto 0);
							out_valid <= '1';
							total_count := total_count + 1;
					
							state := STATE_SEND_TT_REQ;

						end if;

					when STATE_SEND_TT_REQ =>

 						tt_report := tt_report + 1;
						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= to_signed(tt_req, 32)(31 downto 16);
							out_real <= to_signed(tt_req, 32)(15 downto 0);
							out_valid <= '1';

							total_count := total_count + 1;
					
							state := STATE_SEND_TT_REPORT;

						end if;
						
					when STATE_SEND_TT_REPORT=>

 						tt_report := tt_report + 1;
						out_rts <= '1';

						if in_cts = '1' then

							out_imag <= to_signed(tt_report, 32)(31 downto 16);
							out_real <= to_signed(tt_report, 32)(15 downto 0);
							out_valid <= '1';

							total_count := total_count + 1;
					
							state := STATE_SEND_PACKET_END;

						end if;
						
					when STATE_SEND_PACKET_END =>

						out_rts <= '1';

						if in_cts = '1' then
								
							out_imag <= x"AAAA";
							out_real <= x"5555";								
							out_valid <= '1';

							sub_count := 0;
							total_count := 0;
							state := STATE_COLLECT_WB_REPORTS;

						end if;

					
					when others =>

						sub_count := 0;
						total_count := 0;
						state := STATE_COLLECT_WB_REPORTS;
				end case;

			end if;

		end
	process;
	
end rtl;

