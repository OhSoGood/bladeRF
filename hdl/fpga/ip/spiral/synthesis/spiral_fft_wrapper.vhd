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
		order : integer
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

	u_spiral_fft: entity work.spiral_fft
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
		variable in_phase: integer range 0 to 15;

		begin
			if reset = '1' then

				next_in <= '0';
				in_phase := 0;

				for i in 0 to order - 1 loop
					sample_memory(i).real := to_signed(0, 16);
					sample_memory(i).imag := to_signed(0, 16);
				end loop;
				
			elsif rising_edge(clock) then

				next_in <= '0';

				if in_phase = order - 1 then
					next_in <= '1';
				end if;

				if in_phase < order / 2 then 
					in_real_0 <= sample_memory(2 * in_phase).real;
					in_imag_0 <= sample_memory(2 * in_phase).imag;
					in_real_1 <= sample_memory((2 * in_phase) + 1).real;
					in_imag_1 <= sample_memory((2 * in_phase) + 1).imag;
				end if;

				if in_iq_bus.valid = '1' then
					sample_memory(in_phase).real := in_iq_bus.real;
					sample_memory(in_phase).imag := in_iq_bus.imag;
				else
					sample_memory(in_phase).real := to_signed(0, 16);
					sample_memory(in_phase).imag := to_signed(0, 16);
				end if;

				
				if in_phase = order - 1 then
					in_phase := 0;
				else
					in_phase := in_phase + 1;
				end if;

			end if;
		end
	process;


	fft_output:
	process(clock, reset) is
		begin
			if reset = '1' then

				out_iq_bus.real <= (others => '0');
				out_iq_bus.imag <= (others => '0');	
				out_iq_bus.timeslot <= (others => '0');

			elsif rising_edge(clock) then



			end if;
		end
	process;
	
	
end rtl;

