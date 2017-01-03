--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

--http://www.spiral.net/hardware/dftgen.html

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;


entity spiral_fft_wrapper is
	generic (
		order : integer := 16
		--fft_window: integer := BTLE_WINDOW_NONE
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		enable:			in std_logic;
		in_iq_bus:		in iq_bus_t;
		out_iq_bus:		out tdm_iq_bus_t
	);
end spiral_fft_wrapper;


architecture rtl of spiral_fft_wrapper is

	type iq_mem_item_t is record
		real: 		sample_t;
		imag: 		sample_t;
	end record;

	type iq_mem_array_t is array (0 to order - 1) of iq_mem_item_t;

	signal next_in: std_logic := '0';
	signal next_out: std_logic := '0';

	signal in_real_0:  signed(15 downto 0);
	signal in_imag_0:  signed(15 downto 0);
	signal in_real_1:  signed(15 downto 0);
	signal in_imag_1:  signed(15 downto 0);

	signal out_real_0:  signed(15 downto 0);
	signal out_imag_0:  signed(15 downto 0);
	signal out_real_1:  signed(15 downto 0);
	signal out_imag_1:  signed(15 downto 0);

begin

	u_spiral_fft: entity work.spiral_fft_patent
	port map (
		clk => clock,
		reset => reset,
		next_in => next_in,
		next_out => next_out,
		x0 => in_real_0,
		y0 => out_real_0,
		x1 => in_imag_0,
		y1 => out_imag_0,
		x2 => in_real_1,
		y2 => out_real_1,
		x3 => in_imag_1,
		y3 => out_imag_1
	);

	fft_input:
	process(clock, reset) is

		variable sample_memory: iq_mem_array_t;
		variable write_phase: integer range 0 to 15;
		variable read_phase: integer range 0 to 15;
		variable feed_fft : boolean;

		begin
			if reset = '1' then

				next_in <= '0';
				read_phase := 0;
				write_phase := 0;
				feed_fft := false;

				for i in 0 to order - 1 loop
					sample_memory(i).real := to_signed(0, 16);
					sample_memory(i).imag := to_signed(0, 16);
				end loop;

				in_real_0 <= (others => '0');
				in_imag_0 <= (others => '0');
				in_real_1 <= (others => '0');
				in_imag_1 <= (others => '0');

			elsif rising_edge(clock) then

				next_in <= '0';

				if feed_fft = true and read_phase < order then 

						in_real_0 <= sample_memory(read_phase).real;
						in_imag_0 <= sample_memory(read_phase).imag;
						in_real_1 <= sample_memory(read_phase + 1).real;
						in_imag_1 <= sample_memory(read_phase + 1).imag;

						if read_phase /= order - 2 then
							read_phase := read_phase + 2;
						else
							feed_fft := false;
							read_phase := 0;
						end if;
				end if;
					
				if in_iq_bus.valid = '1' then

					sample_memory(write_phase).real := in_iq_bus.real;
					sample_memory(write_phase).imag := in_iq_bus.imag;

					if write_phase = order - 1 then
						read_phase := 0;
						write_phase := 0;
						feed_fft := true;
						next_in <= '1';
					else
						write_phase := write_phase + 1;
					end if;				
				end if;
			end if;
		end
	process;


	fft_output:
	process(clock, reset) is

		variable sample_memory: iq_mem_array_t;
		variable out_phase: integer range 0 to 15;
		variable wait_sync : boolean;

		begin	
			if reset = '1' then

				out_phase := 0;
				wait_sync := true;

				out_iq_bus <= ((others => '0'), (others => '0'), '0', (others => '0') );

				for i in 0 to order - 1 loop
					sample_memory(i).real := to_signed(0, 16);
					sample_memory(i).imag := to_signed(0, 16);
				end loop;

			elsif rising_edge(clock) then

				out_iq_bus <= ((others => '0'), (others => '0'), '0', (others => '0') );

				if wait_sync = false then

					if out_phase < order / 2 then

						sample_memory(2 * out_phase).real := out_real_0;
						sample_memory(2 * out_phase).imag := out_imag_0;
						sample_memory((2 * out_phase) + 1).real := out_real_1;
						sample_memory((2 * out_phase) + 1).imag := out_imag_1;

					end if;
					
					out_iq_bus.real <= shift_right(sample_memory(out_phase).real, 1);
					out_iq_bus.imag <= shift_right(sample_memory(out_phase).imag, 1);

					--out_iq_bus.real <= sample_memory(out_phase).real;
					--out_iq_bus.imag <= sample_memory(out_phase).imag;
					out_iq_bus.timeslot <= to_unsigned(out_phase, out_iq_bus.timeslot'length);
					out_iq_bus.valid <= '1';
					
					if out_phase = order - 1 then
						out_phase := 0;
						wait_sync := true;
					else
						out_phase := out_phase + 1;
					end if;
					
				end if;

				if next_out = '1' then
					out_phase := 0;
					wait_sync := false;
				end if;

			end if;
		end
	process;
	
	
end rtl;

