--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

entity btle_demod_matched is
	generic(
		samples_per_bit : natural := 2;
		max_channels : integer := 1
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;
		in_iq_bus:		in tdm_iq_bus_t;
		out_bit_bus:	out tdm_bit_bus_t
	);
end btle_demod_matched;


architecture rtl of btle_demod_matched is

	type phase_array_t is array (0 to max_channels - 1) of natural range 0 to samples_per_bit - 1;
	type signed17_array_t is array (0 to max_channels - 1) of signed(16 downto 0);


	type filter_ref_type is record
		f_upper_real: signed(7 downto 0);
		f_upper_imag: signed(7 downto 0);
		f_lower_real: signed(7 downto 0);
		f_lower_imag: signed(7 downto 0);
	end record;
	
	type filter_ref_array_type is array (natural range <>) of
		filter_ref_type;

	constant FILTER_REF: filter_ref_array_type := (
    	( to_signed(127, 8),    to_signed(0,  8), 		to_signed(127, 8),  to_signed(  0, 8) ),
		( to_signed(90,  8),    to_signed(90, 8), 		to_signed(90,  8),  to_signed(-90, 8) )    	  	
	);


	signal mul_lower_real: signed(15 downto 0);
	signal mul_lower_imag: signed(15 downto 0);
	signal mul_upper_real: signed(15 downto 0);
	signal mul_upper_imag: signed(15 downto 0);
	signal mul_valid : std_logic := '0';
	signal mul_phase : natural range 0 to samples_per_bit - 1 := 0;
	signal mul_idx : integer range 0 to max_channels - 1 := 0;

	signal sum_lower_real : signed(15 downto 0);
	signal sum_lower_imag : signed(15 downto 0);
	signal sum_upper_real : signed(15 downto 0);
	signal sum_upper_imag : signed(15 downto 0);
	signal sum_valid : std_logic := '0';
	signal sum_idx : integer range 0 to max_channels - 1 := 0;

begin
	multiply: 
	process(clock, reset) is		

		variable phase : phase_array_t;
		variable mlr, mli, mur, mui : signed(19 downto 0);

		variable this_idx : integer;
		variable this_phase : integer;

		variable scaled_in_real : signed(11 downto 0);
		variable scaled_in_imag : signed(11 downto 0);

		begin
			if reset = '1' then

				for i in 0 to max_channels - 1 loop
					phase(i) := 0;
				end loop;
				
				mul_valid <= '0';
				mul_phase <= 0;
				mul_lower_real <= (others => '0');
				mul_lower_imag <= (others => '0');	
				mul_upper_real <= (others => '0');
				mul_upper_imag <= (others => '0');
			
			elsif rising_edge(clock) then

				mul_valid <= '0';

				if in_iq_bus.valid = '1' then
				
					this_idx := to_integer(in_iq_bus.timeslot);
					this_phase := phase(this_idx);
					
					scaled_in_real := resize(in_iq_bus.real, 12);
					scaled_in_imag := resize(in_iq_bus.imag, 12);
				
					mlr := scaled_in_real * FILTER_REF(this_phase).f_lower_real - scaled_in_imag * FILTER_REF(this_phase).f_lower_imag;
					mli := scaled_in_real * FILTER_REF(this_phase).f_lower_imag + scaled_in_imag * FILTER_REF(this_phase).f_lower_real;
					mur := scaled_in_real * FILTER_REF(this_phase).f_upper_real - scaled_in_imag * FILTER_REF(this_phase).f_upper_imag;
					mui := scaled_in_real * FILTER_REF(this_phase).f_upper_imag + scaled_in_imag * FILTER_REF(this_phase).f_upper_real;

					mul_lower_real <= mlr(19 downto 4);
					mul_lower_imag <= mli(19 downto 4);
					mul_upper_real <= mur(19 downto 4);
					mul_upper_imag <= mui(19 downto 4);

					mul_phase <= this_phase;						
					mul_idx <= this_idx;
					mul_valid <= '1';

					if this_phase = 0 then
						phase(this_idx) := 1;
					else
						phase(this_idx) := 0;
					end if;

				end if;
			end if;
		end 
	process;

	accumulate:
	process(clock, reset) is

		variable slr : signed17_array_t;
		variable sli : signed17_array_t;
		variable sur : signed17_array_t;
		variable sui : signed17_array_t;

		variable t_slr: signed(16 downto 0);
		variable t_sli: signed(16 downto 0);
		variable t_sur: signed(16 downto 0);
		variable t_sui: signed(16 downto 0);
		
		begin
			if reset = '1' then
			
				sum_valid <= '0';

				sum_lower_real <= (others => '0');
				sum_lower_imag <= (others => '0');	
				sum_upper_real <= (others => '0');
				sum_upper_imag <= (others => '0');

				for i in 0 to max_channels - 1 loop
				
					slr(i) := (others => '0');
					sli(i) := (others => '0');
					sur(i) := (others => '0');
					sui(i) := (others => '0');

				end loop;

			elsif rising_edge(clock) then

				sum_valid <= '0';
				sum_idx <= 0;

				if mul_valid = '1' then

					if mul_phase = 0 then
					
						slr(mul_idx) := resize(mul_lower_real, 17);
						sli(mul_idx) := resize(mul_lower_imag, 17);
						sur(mul_idx) := resize(mul_upper_real, 17);
						sui(mul_idx) := resize(mul_upper_imag, 17);

					elsif mul_phase = 1 then

						t_slr := slr(mul_idx) + mul_lower_real;
						t_sli := sli(mul_idx) + mul_lower_imag;
						t_sur := sur(mul_idx) + mul_upper_real;
						t_sui := sui(mul_idx) + mul_upper_imag;

						sum_lower_real <= t_slr (16 downto 1);
						sum_lower_imag <= t_sli (16 downto 1);
						sum_upper_real <= t_sur (16 downto 1);
						sum_upper_imag <= t_sui (16 downto 1);

						sum_idx <= mul_idx;
						sum_valid <= '1';

					end if;

				end if;
			end if;
		end
	process;
			

	decision:
	process(clock, reset) is

		variable upper_sq : unsigned(31 downto 0);
		variable lower_sq : unsigned(31 downto 0);
	
		begin
			if reset = '1' then
			
				out_bit_bus.seq <= '0';
				out_bit_bus.valid <= '0';
				out_bit_bus.timeslot <= to_unsigned(0, out_bit_bus.timeslot'length);

			elsif rising_edge(clock) then

				out_bit_bus.seq <= '0';
				out_bit_bus.valid <= '0';
				out_bit_bus.timeslot <= to_unsigned(0, out_bit_bus.timeslot'length);

				if sum_valid = '1' then
				
					upper_sq := unsigned(sum_upper_real * sum_upper_real + sum_upper_imag * sum_upper_imag);
					lower_sq := unsigned(sum_lower_real * sum_lower_real + sum_lower_imag * sum_lower_imag);
				
					if(upper_sq < lower_sq) then
						out_bit_bus.seq <= '1';
					end if;

					out_bit_bus.timeslot <= to_unsigned(sum_idx, out_bit_bus.timeslot'length);
					out_bit_bus.valid <= '1';
				end if;
			end if;
		end
	process;
end rtl;

