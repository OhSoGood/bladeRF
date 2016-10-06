--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity btle_fft_streamer is
	generic(order : integer);
	port(
		clock:			in std_logic;
		reset_n:		in std_logic;
		enable:			in std_logic;

		in_real:		in signed(15 downto 0);
		in_imag:		in signed(15 downto 0);
		in_valid:       in std_logic;
		
		out_bin_idx:   	out unsigned(4 downto 0);
		out_real:		out signed(15 downto 0);
		out_imag:		out signed(15 downto 0);
		out_valid:      out std_logic
	);
end btle_fft_streamer;


architecture rtl of btle_fft_streamer is

	signal fftpts_in : std_logic_vector (4 downto 0) := (others => '0'); 
	signal fftpts_out : std_logic_vector (4 downto 0):= (others => '0'); 

	signal inverse: std_logic := '0';
	signal sink_eop: std_logic := '0';

	signal sink_error: std_logic_vector (1 downto 0) := (others => '0');
	signal sink_imag : signed (15 downto 0) := (others => '0');
	signal sink_ready: std_logic := '0';
	signal sink_real : signed (15 downto 0) := (others => '0');	
	signal sink_sop: std_logic := '0';
	signal sink_valid: std_logic := '0';
	signal source_eop: std_logic := '0';
	signal source_error: std_logic_vector (1 downto 0) := (others => '0');
	signal source_imag:  signed (15 downto 0) := (others => '0');
	signal source_sop: std_logic := '0';
	signal source_valid: std_logic := '0';
	signal source_ready: std_logic := '0';
	signal source_real:  signed (15 downto 0) := (others => '0');

begin

	fft: entity work.fft_ii_0_example_design_core
	port map(
		clk => clock,					-- in
		fftpts_in => fftpts_in,			
		fftpts_out => fftpts_out,
		inverse => inverse,
		reset_n => reset_n,
		sink_eop => sink_eop,			-- into FFT
		sink_error => sink_error,				-- into FFT from upstream avalon block
		sink_imag => sink_imag,			-- into FFT
		sink_ready => sink_ready,		-- out of FFT
		sink_real => sink_real,			-- into FFT
		sink_sop => sink_sop,			-- into FFT
		sink_valid => sink_valid,		-- into FFT
		source_eop => source_eop,		-- out of FFT
		source_error => source_error,	-- out of FFT
		source_imag => source_imag,		-- out of FFT
		source_sop => source_sop,		-- out of FFT
		source_valid => source_valid,	-- out of FFT
		source_ready => source_ready,	-- into FFT
		source_real => source_real);	-- out of FFT


	input:
	process(clock, reset_n) is
		variable in_phase : integer;
		begin
			if reset_n = '0' then
				in_phase := 0;

				sink_sop <= '0';
				sink_eop <= '0';
				sink_valid <= '0';
				inverse <= '0';
				sink_error <= "00";
				fftpts_in <= "00000";

				sink_real <= (others => '0');
				sink_imag <= (others => '0');		

			elsif rising_edge(clock) then

				fftpts_in <= "10000";
				sink_valid <= '0';
				sink_sop <= '0';
				sink_eop <= '0';
			
				if sink_ready = '1' and in_valid = '1' then

					if in_phase = 0 then
						sink_sop <= '1';
					elsif in_phase = order - 1 then
						sink_eop <= '1';
					end if;

					sink_valid <= '1';
					sink_real <= in_real;
					sink_imag <= in_imag;

					in_phase := in_phase + 1;

					if in_phase >= order then
						in_phase := 0;
					end if;
				end if;
			end if;
		end
	process;


	output:
	process(clock, reset_n) is
		variable out_phase : integer;
		begin
			if reset_n = '0'  then

				out_phase := 0;
				out_bin_idx <= to_unsigned(0, 5);
				out_valid <= '0';
				source_ready <= '0';

				out_real <= (others => '0');				
				out_imag <= (others => '0');

			elsif rising_edge(clock) then

				source_ready <= '1';
				out_valid <= '0';
			
				if source_valid = '1' then

					if source_sop = '1' then
						out_phase := 0;
					else
						out_phase := out_phase + 1;
					end if;

					out_real <= source_real;
					out_imag <= source_imag;
					out_bin_idx <= to_unsigned(out_phase, 5);
					out_valid <= '1';

					if source_eop = '1' then
						assert out_phase = 15 report "source_eop asserted when out_phase= " & to_string(out_phase) severity failure;
					end if;

				end if;

				assert source_error = "00" report "Source error asserted " & to_string(source_error) severity failure;
			end if;
		end
	process;

end rtl;
