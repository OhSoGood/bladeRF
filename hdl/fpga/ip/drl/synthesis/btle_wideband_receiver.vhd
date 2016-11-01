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
		out_valid:		out std_logic
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

begin

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

				out_real <= (others => '0');
				out_imag <= (others => '0');
				out_valid <= '0';

			elsif rising_edge(clock) then

				out_valid <= '0';

				if fft_out_valid = '1' then

					out_real <= fft_out_real;
					out_imag <= fft_out_imag;
					out_valid <= '1';

				end if;
			end if;
		end
	process;


end rtl;
