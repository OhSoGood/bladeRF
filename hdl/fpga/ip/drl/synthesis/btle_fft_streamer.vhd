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
		reset:			in std_logic;
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

	signal inverse: std_logic_vector(0 downto 0) := (others => '0');
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


	component fft is
		port (
			clk          : in  std_logic                     := 'X';             -- clk
			reset_n      : in  std_logic                     := 'X';             -- reset_n
			sink_valid   : in  std_logic                     := 'X';             -- sink_valid
			sink_ready   : out std_logic;                                        -- sink_ready
			sink_error   : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- sink_error
			sink_sop     : in  std_logic                     := 'X';             -- sink_sop
			sink_eop     : in  std_logic                     := 'X';             -- sink_eop
			sink_real    : in  signed(15 downto 0) := (others => 'X'); -- sink_real
			sink_imag    : in  signed(15 downto 0) := (others => 'X'); -- sink_imag
			fftpts_in    : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- fftpts_in
			inverse      : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- inverse
			source_valid : out std_logic;                                        -- source_valid
			source_ready : in  std_logic                     := 'X';             -- source_ready
			source_error : out std_logic_vector(1 downto 0);                     -- source_error
			source_sop   : out std_logic;                                        -- source_sop
			source_eop   : out std_logic;                                        -- source_eop
			source_real  : out signed(15 downto 0);                    -- source_real
			source_imag  : out signed(15 downto 0);                    -- source_imag
			fftpts_out   : out std_logic_vector(4 downto 0)                      -- fftpts_out
		);
	end component fft;

begin

	u_fft : component fft
		port map (
			clk          => clock,
			reset_n      => not reset,
			sink_valid   => sink_valid,
			sink_ready   => sink_ready,
			sink_error   => sink_error,
			sink_sop     => sink_sop,
			sink_eop     => sink_eop,
			sink_real    => sink_real, 
			sink_imag    => sink_imag,
			fftpts_in    => fftpts_in,
			inverse      => inverse,
			source_valid => source_valid,
			source_ready => source_ready,
			source_error => source_error,
			source_sop   => source_sop,
			source_eop   => source_eop,
			source_real  => source_real,
			source_imag  => source_imag,
			fftpts_out   => fftpts_out
		);


	input:
	process(clock, reset) is
		variable in_phase : integer;
		begin
			if reset = '1' then
				in_phase := 0;

				sink_sop <= '0';
				sink_eop <= '0';
				sink_valid <= '0';
				inverse <= (others => '0');
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
	process(clock, reset) is
		variable out_phase : integer;
		begin
			if reset = '1'  then

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
