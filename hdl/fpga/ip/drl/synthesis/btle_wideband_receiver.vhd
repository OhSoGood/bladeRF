--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity btle_wideband_receiver is
	generic(
		samples_per_bit : natural := 2
	);
	port(
		clock: 			in std_logic;
		reset:			in std_logic;
		enable:			in std_logic;
		
		in_wb_real:		in signed(15 downto 0);
		in_wb_imag:		in signed(15 downto 0);
		in_wb_valid:	in std_logic;

		out_real:		out signed(15 downto 0);				
		out_imag: 		out signed(15 downto 0);
		out_valid:		out std_logic;
		out_detected:   out std_logic
	);

end btle_wideband_receiver;



architecture rtl of btle_wideband_receiver is

	signal fft_in_real: 	signed (15 downto 0);
	signal fft_in_imag: 	signed (15 downto 0);
	signal fft_in_valid: 	std_logic;

	signal fft_out_idx:		unsigned (4 downto 0);
	signal fft_out_real: 	signed (15 downto 0);
	signal fft_out_imag: 	signed (15 downto 0);
	signal fft_out_valid: 	std_logic;

	type bus_array is array(15 downto 0) of signed (15 downto 0);

	signal ch_in_real: 		signed (15 downto 0);
	signal ch_in_imag: 		signed (15 downto 0);
	signal ch_in_valid:		std_logic_vector(15 downto 0);
	
	signal ch_out_real: 	bus_array;
	signal ch_out_imag:		bus_array;
	signal ch_out_valid:    std_logic_vector(15 downto 0);
	signal ch_out_detected: std_logic_vector(15 downto 0);

begin


	rx_bank : for i in 0 to 15 generate
		ch_rx: entity work.btle_channel_receiver
			generic map(samples_per_bit => samples_per_bit)
			port map(
				clock => clock,
				reset => reset,

				in_real => ch_in_real,
				in_imag => ch_in_imag,
				in_valid => ch_in_valid(i),

				out_real => ch_out_real(i),
				out_imag => ch_out_imag(i),
				out_valid => ch_out_valid(i),
				out_detected  => ch_out_detected(i) 
			);

	end generate;

    fft : entity work.btle_fft_streamer
	generic map(order => 16)
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

				fft_in_valid <= '0';

				if in_wb_valid = '1' then

					fft_in_real <= in_wb_real;
					fft_in_imag <= in_wb_imag;
					fft_in_valid <= '1';

				end if;
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
		begin
			if reset = '1' then

				out_real <= (others => '0');
				out_imag <= (others => '0');
				out_valid <= '0';

			elsif rising_edge(clock) then

				out_valid <= '0';

				--for ch in 0 to 15 loop
				--	if ch_out_valid(ch) and '1' then
				--	
				--			out_real <= ch_out_real(ch);
				--		out_imag <= ch_out_imag(ch);
				--		out_valid <= '1';	

--					end if;
--				end loop;

				if ch_out_valid = "0000010000000000" then

					out_real <= ch_out_real(10);
					out_imag <= ch_out_imag(10);
					out_valid <= '1';

				end if;
				
			end if;
		end
	process;


	ch_detector:
	process(clock, reset) is
		variable tmp : std_logic;
		begin
			
			if reset = '1' then

				out_detected <= '0';

			elsif rising_edge(clock) then

				tmp := '0';

				for ch in 0 to 15 loop
					tmp:= tmp or ch_out_detected(ch);
				end loop;

				out_detected <= tmp;

			end if;
		end
	process;

end rtl;
