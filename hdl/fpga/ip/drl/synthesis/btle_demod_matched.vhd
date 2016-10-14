--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity btle_demod_matched is
	generic(
		samples_per_bit : natural := 2
	);
	port(
		clock:			in std_logic;
		reset:			in std_logic;

		-- input signal
		in_real:		in signed(15 downto 0);
		in_imag:		in signed(15 downto 0);
		in_valid:       in std_logic;

		-- output bits
		out_bit:		out std_logic := '0';
		out_valid:		out std_logic := '0'
	);
end btle_demod_matched;


architecture rtl of btle_demod_matched is

	type filter_ref_type is record
		f_upper_real: signed(15 downto 0);
		f_upper_imag: signed(15 downto 0);
		f_lower_real: signed(15 downto 0);
		f_lower_imag: signed(15 downto 0);
	end record;
	
	type filter_ref_array_type is array (natural range <>) of
		filter_ref_type;

	constant FILTER_REF: filter_ref_array_type := (
    	( to_signed(8191, 16),    to_signed(0, 16), 		to_signed(8191, 16),  to_signed(0, 16) ),
		( to_signed(5792, 16),    to_signed(5792, 16), 		to_signed(5792, 16),  to_signed(-5792, 16) )    	  	
	);


	signal mul_lower_real: signed(31 downto 0);
	signal mul_lower_imag: signed(31 downto 0);
	signal mul_upper_real: signed(31 downto 0);
	signal mul_upper_imag: signed(31 downto 0);
	signal mul_valid : std_logic := '0';
	signal mul_phase : natural range 0 to samples_per_bit - 1 := 0;

	signal sum_lower_real : signed(15 downto 0);
	signal sum_lower_imag : signed(15 downto 0);
	signal sum_upper_real : signed(15 downto 0);
	signal sum_upper_imag : signed(15 downto 0);
	signal sum_valid : std_logic := '0';

begin
	multiply: 
	process(clock, reset) is		

		variable phase : natural range 0 to samples_per_bit - 1;

		begin
			if reset = '1' then

				phase := 0;
				
				mul_valid <= '0';
				mul_phase <= phase;
				mul_lower_real <= (others => '0');
				mul_lower_imag <= (others => '0');	
				mul_upper_real <= (others => '0');
				mul_upper_imag <= (others => '0');
			
			elsif rising_edge(clock) then

				mul_valid <= '0';

				if in_valid = '1' then

					mul_lower_real <= in_real * FILTER_REF(phase).f_lower_real - in_imag * FILTER_REF(phase).f_lower_imag;
					mul_lower_imag <= in_real * FILTER_REF(phase).f_lower_imag + in_imag * FILTER_REF(phase).f_lower_real;
					mul_upper_real <= in_real * FILTER_REF(phase).f_upper_real - in_imag * FILTER_REF(phase).f_upper_imag;
					mul_upper_imag <= in_real * FILTER_REF(phase).f_upper_imag + in_imag * FILTER_REF(phase).f_upper_real;

					mul_phase <= phase;						
					mul_valid <= '1';

					if phase = 0 then
						phase := 1;
					else
						phase := 0;
					end if;

				end if;
			end if;
		end 
	process;

	accumulate:
	process(clock, reset) is

		variable slr : signed(31 downto 0);
		variable sli : signed(31 downto 0);
		variable sur : signed(31 downto 0);
		variable sui : signed(31 downto 0);
	
		begin
			if reset = '1' then
			
				sum_valid <= '0';
				sum_lower_real <= (others => '0');
				sum_lower_imag <= (others => '0');	
				sum_upper_real <= (others => '0');
				sum_upper_imag <= (others => '0');

			elsif rising_edge(clock) then

				sum_valid <= '0';

				if mul_valid = '1' then

					if mul_phase = 0 then
					
						slr := (others => '0');
						sli := (others => '0');
						sur := (others => '0');
						sui := (others => '0');

					end if;

					slr := slr + mul_lower_real;
					sli := sli + mul_lower_imag;
					sur := sur + mul_upper_real;
					sui := sui + mul_upper_imag;

					if mul_phase = 1 then
					
						sum_lower_real <= slr (31 downto 16);
						sum_lower_imag <= sli (31 downto 16);
						sum_upper_real <= sur (31 downto 16);
						sum_upper_imag <= sui (31 downto 16);

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
			
				out_bit <= '0';
				out_valid <= '0';

			elsif rising_edge(clock) then

				out_valid <= '0';
				out_bit <= '0';

				if sum_valid = '1' then
				
					upper_sq := unsigned(sum_upper_real * sum_upper_real + sum_upper_imag * sum_upper_imag);
					lower_sq := unsigned(sum_lower_real * sum_lower_real + sum_lower_imag * sum_lower_imag);
				
					if(upper_sq < lower_sq) then
						out_bit <= '1';
					end if;

					out_valid <= '1';
				end if;
			end if;
		end
	process;
end rtl;

