--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

entity btle_fft_streamer is
	generic (
		order : integer;
		fft_window: integer := BTLE_WINDOW_NONE
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		enable:			in std_logic;
		in_iq_bus:		in iq_bus_t;
		out_iq_bus:		out tdm_iq_bus_t
	);
end btle_fft_streamer;


architecture rtl of btle_fft_streamer is


 --0.5402     1
 --   2.0879  2
 --   4.4341  4
 --   7.2619  7
 --  10.1893  10
 --  12.8211  13
 --  14.8017  15
 --  15.8638  16
 --  15.8638  16
 --  14.8017  15
 --  12.8211  13
 -- 10.1893   10
 --   7.2619  7
 --   4.4341  4
 --   2.0879  2
 --   0.5402  1

	-- Noramised to 2048

	type window_t is array (0 to 15) OF integer range 0 to 2047;
	type window_array_t is array (0 to BTLE_WINDOW_NONE - 1) of window_t;
	

	constant window_array : window_array_t := (
		( 69, 267, 568, 930, 1304, 1641, 1895, 2031, 2031, 1895, 1641, 1304, 930, 568, 267,  69),									-- hanning(16) * 2048						
		(164, 245, 476, 815, 1204, 1577, 1868, 2027, 2027, 1868, 1577, 1204, 815, 476, 245, 164)	-- hamming(16) * 2048
	);


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

	--attribute preserve : boolean;
	--attribute preserve of fftpts_in : signal is true;
	--attribute preserve of fftpts_out : signal is true;
	--attribute preserve of inverse : signal is true;
	--attribute preserve of sink_eop : signal is true;
	--attribute preserve of sink_error : signal is true;
	--attribute preserve of sink_imag : signal is true;
	--attribute preserve of sink_ready : signal is true;
	--attribute preserve of sink_real : signal is true;
	--attribute preserve of sink_sop : signal is true;
	--attribute preserve of sink_valid : signal is true;
	--attribute preserve of source_eop : signal is true;
	--attribute preserve of source_error : signal is true;
	--attribute preserve of source_imag : signal is true;
	--attribute preserve of source_sop : signal is true;
	--attribute preserve of source_valid : signal is true;
	--attribute preserve of source_ready : signal is true;
	--attribute preserve of source_real : signal is true;

	--attribute syn_keep : boolean;
	--attribute syn_keep of fftpts_in : signal is true;
	--attribute syn_keep of fftpts_out : signal is true;
	--attribute syn_keep of inverse : signal is true;
	--attribute syn_keep of sink_eop : signal is true;
	--attribute syn_keep of sink_error : signal is true;
	--attribute syn_keep of sink_imag : signal is true;
	--attribute syn_keep of sink_ready : signal is true;
	--attribute syn_keep of sink_real : signal is true;
	--attribute syn_keep of sink_sop : signal is true;
	--attribute syn_keep of sink_valid : signal is true;
	--attribute syn_keep of source_eop : signal is true;
	--attribute syn_keep of source_error : signal is true;
	--attribute syn_keep of source_imag : signal is true;
	--attribute syn_keep of source_sop : signal is true;
	--attribute syn_keep of source_valid : signal is true;
	--attribute syn_keep of source_ready : signal is true;
	--attribute syn_keep of source_real : signal is true;			

	

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
		variable in_phase : integer range 0 to order - 1 := 0;
		variable in_window_real: signed (31 downto 0);
		variable in_window_imag: signed (31 downto 0);	

		begin

			inverse <= (others => '0');
			sink_error <= "00";
			fftpts_in <= "10000";
		
			if reset = '1' then
			
				in_phase := 0;

				sink_sop <= '0';
				sink_eop <= '0';
				sink_valid <= '0';

				sink_real <= (others => '0');
				sink_imag <= (others => '0');		

			elsif rising_edge(clock) then

				sink_valid <= '0';
				sink_sop <= '0';
				sink_eop <= '0';
			
				if sink_ready = '1' and in_iq_bus.valid = '1' then

					if in_phase = 0 then
						sink_sop <= '1';
					elsif in_phase = order - 1 then
						sink_eop <= '1';
					end if;
					
					sink_valid <= '1';

					if fft_window /= BTLE_WINDOW_NONE then

						in_window_real := ((in_iq_bus.real * window_array(fft_window)(in_phase)) + 1024) / 2048;
						in_window_imag := ((in_iq_bus.imag * window_array(fft_window)(in_phase)) + 1024) / 2048;
					
						sink_real <= resize(in_window_real, sink_real'length);
						sink_imag <= resize(in_window_imag, sink_imag'length);

					else
					
						sink_real <= in_iq_bus.real;
						sink_imag <= in_iq_bus.imag;

					end if;

					if in_phase = order - 1 then
						in_phase := 0;
					else
						in_phase := in_phase + 1;
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
				source_ready <= '0';

				out_iq_bus.real <= (others => '0');
				out_iq_bus.imag <= (others => '0');
				out_iq_bus.valid <= '0';
				out_iq_bus.timeslot <= (others => '0');

			elsif rising_edge(clock) then

				source_ready <= '1';
				
				out_iq_bus.real <= (others => '0');
				out_iq_bus.imag <= (others => '0');
				out_iq_bus.valid <= '0';
				out_iq_bus.timeslot <= (others => '0');
			
				if source_valid = '1' then

					if source_sop = '1' then
						out_phase := 0;
					else
						out_phase := out_phase + 1;
					end if;

					out_iq_bus.real <= source_real;
					out_iq_bus.imag <= source_imag;
					out_iq_bus.timeslot <= to_unsigned(out_phase, out_iq_bus.timeslot'length);
					out_iq_bus.valid <= '1';

					if source_eop = '1' then
						assert out_phase = 15 report "source_eop asserted when out_phase= " 
						--& to_string(out_phase) 
						severity failure;
					end if;

				end if;

				assert source_error = "00" report "Source error asserted " 
				--& to_string(source_error) 
				severity failure;
			end if;
		end
	process;

end rtl;
