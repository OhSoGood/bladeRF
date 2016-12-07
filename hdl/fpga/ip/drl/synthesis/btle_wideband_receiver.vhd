--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

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

	type ch_array_type is array (0 to 15) OF integer;
	constant ch_idx_array : ch_array_type := (5, 6, 7, 8, 9, 10, 38, 40, 40, 40, 37, 0, 1, 2, 3, 4 );

	type wb_state_type is ( 
							STATE_WAIT_RTS, 
							STATE_SENDING );

	signal state : wb_state_type;
	
	signal fft_in_real: 	signed (15 downto 0);
	signal fft_in_imag: 	signed (15 downto 0);
	signal fft_in_valid: 	std_logic;

	signal fft_out_idx:		unsigned (4 downto 0);
	signal fft_out_real: 	signed (15 downto 0);
	signal fft_out_imag: 	signed (15 downto 0);
	signal fft_out_valid: 	std_logic;

	type bus_array is array(num_channels - 1 downto 0) of signed (15 downto 0);

	signal ch_in_real: 		signed (15 downto 0);
	signal ch_in_imag: 		signed (15 downto 0);
	signal ch_in_valid:		std_logic_vector(num_channels - 1 downto 0);
	signal ch_in_cts:		std_logic_vector(num_channels - 1 downto 0);

	signal ch_out_rts:		std_logic_vector(num_channels - 1 downto 0);
	signal ch_out_real: 	bus_array;
	signal ch_out_imag:		bus_array;
	signal ch_out_valid:    std_logic_vector(num_channels - 1 downto 0);
	signal ch_out_detected: std_logic_vector(num_channels - 1 downto 0);

	signal rx_timestamp:	unsigned(63 downto 0);


	attribute preserve : boolean;
	attribute preserve of fft_in_real : signal is true;
	attribute preserve of fft_in_imag : signal is true;
	attribute preserve of fft_in_valid : signal is true;
	attribute preserve of fft_out_idx : signal is true;
	attribute preserve of fft_out_real : signal is true;
	attribute preserve of fft_out_imag : signal is true;
	attribute preserve of fft_out_valid : signal is true;
	attribute preserve of ch_in_real : signal is true;
	attribute preserve of ch_in_imag : signal is true;
	attribute preserve of ch_in_valid : signal is true;
	attribute preserve of ch_in_cts : signal is true;
	attribute preserve of ch_out_rts : signal is true;
	attribute preserve of ch_out_real : signal is true;
	attribute preserve of ch_out_imag : signal is true;
	attribute preserve of ch_out_valid : signal is true;
	attribute preserve of ch_out_detected : signal is true;

	attribute syn_keep : boolean;
	attribute syn_keep of fft_in_real : signal is true;
	attribute syn_keep of fft_in_imag : signal is true;
	attribute syn_keep of fft_in_valid : signal is true;
	attribute syn_keep of fft_out_idx : signal is true;
	attribute syn_keep of fft_out_real : signal is true;
	attribute syn_keep of fft_out_imag : signal is true;
	attribute syn_keep of fft_out_valid : signal is true;
	attribute syn_keep of ch_in_real : signal is true;
	attribute syn_keep of ch_in_imag : signal is true;
	attribute syn_keep of ch_in_valid : signal is true;
	attribute syn_keep of ch_in_cts : signal is true;
	attribute syn_keep of ch_out_rts : signal is true;
	attribute syn_keep of ch_out_real : signal is true;
	attribute syn_keep of ch_out_imag : signal is true;
	attribute syn_keep of ch_out_valid : signal is true;
	attribute syn_keep of ch_out_detected : signal is true;

begin


	rx_timestamp <= in_timestamp;

	fft_based: if num_channels > 1 generate

		rx_bank : for i in 0 to num_channels - 1 
		generate
			ch_rx: entity work.btle_channel_receiver
				generic map(channel_index => ch_idx_array(i), samples_per_bit => samples_per_bit)
				port map(
					clock => 		clock,
					reset => 		reset,

					in_real => 		ch_in_real,
					in_imag => 		ch_in_imag,
					in_valid => 	ch_in_valid(i),
					in_timestamp =>	rx_timestamp,

					in_cts => 		ch_in_cts(i),
					out_rts =>		ch_out_rts(i),

					out_real => 	ch_out_real(i),
					out_imag => 	ch_out_imag(i),
					out_valid => 	ch_out_valid(i),
					out_detected => ch_out_detected(i) 
				);

		end generate;

    	fft : entity work.btle_fft_streamer
		generic map(order => num_channels)
    	port map(
			clock 			=> clock,
			reset 			=> reset,
			enable			=> enable,

			in_real  		=> fft_in_real,
			in_imag	   		=> fft_in_imag,
			in_valid       	=> fft_in_valid,
		
			out_bin_idx   	=> fft_out_idx,
			out_real		=> fft_out_real,
			out_imag  		=> fft_out_imag,
			out_valid       => fft_out_valid
    	);

		fft_input:
		process(clock, reset) is
			begin
				if reset = '1' then

					fft_in_real <= (others => '0');
					fft_in_imag <= (others => '0');
					fft_in_valid <= '0';

				elsif rising_edge(clock) then

					fft_in_valid <= in_wb_valid;
					fft_in_real <= in_wb_real;
					fft_in_imag <= in_wb_imag;
					
				end if;
			end
		process;

		fft_output:
		process(clock, reset) is
			begin
				if reset = '1' then

					ch_in_real <= (others => '0');
					ch_in_imag <= (others => '0');
					ch_in_valid <= (others => '0');

				elsif rising_edge(clock) then

					ch_in_valid <= (others => '0');
						
					if fft_out_valid = '1' then

						ch_in_real <= fft_out_real;
						ch_in_imag <= fft_out_imag;
						ch_in_valid(to_integer(fft_out_idx)) <= '1';

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

				in_cts => 		ch_in_cts(0),
				out_rts =>		ch_out_rts(0),

				out_real => 	ch_out_real(0),
				out_imag => 	ch_out_imag(0),
				out_valid => 	ch_out_valid(0),
				out_detected => ch_out_detected(0) 
			);

		single_input:
			process(clock, reset) is
			begin
				if reset = '1' then

					ch_in_real  <= (others => '0');
					ch_in_imag  <= (others => '0');
					ch_in_valid <= (others => '0');

				elsif rising_edge(clock) then

					ch_in_valid <= (others => '0');
					
					if in_wb_valid = '1' then

						ch_in_real  <= in_wb_real;
						ch_in_imag  <= in_wb_imag;
						ch_in_valid(0) <= '1';
					
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

					out_valid <= '0';
					ch_in_cts <= (others => '1');
					
					if ch_out_valid(0) = '1' then

						out_real <= ch_out_real(0);
						out_imag <= ch_out_imag(0);
						out_valid <= '1';

					end if;
					
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

				tmp := '0';

				for ch in 0 to num_channels - 1 loop
					tmp:= tmp or ch_out_detected(ch);
				end loop;

				out_detected <= tmp;

			end if;
		end
	process;

end rtl;
