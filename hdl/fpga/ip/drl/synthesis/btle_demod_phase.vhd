--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.btle_common.all;

entity btle_demod_phase is
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
end btle_demod_phase;


architecture rtl of btle_demod_phase is

	type fsk_demod_output_t is record
		symbol:   signed(15 downto 0);
		timeslot: timeslot_t;
		valid:    std_logic;
	end record;

	signal filtered_iq_bus: tdm_iq_bus_t;
	signal decimated_iq_bus: tdm_iq_bus_t;
	signal fsk_output : fsk_demod_output_t;

    constant FIR_TAPS2 : real_array_t := (
 		0.0,
		-0.000100538344543,
		0.0,
 		0.000387037706656,
 		0.0,
		-0.001021402764262,
 		0.0,
 		0.002228554058301,
 		0.0,
		-0.004309013739577,
 		0.0,
 		0.007661071732386,
 		0.0,
		-0.012841319952088,
 		0.0,
 		0.020735593738450,
 		0.0,
		-0.033069171276803,
 		0.0,
 		0.054201906591155,
 		0.0,
		-0.100171002350344,
 		0.0,
 		0.316288048325624,
 		0.500000000000000,
 		0.316288048325624,
 		0.0,
		-0.100171002350344,
 		0.0,
 		0.054201906591155,
 		0.0,
		-0.033069171276803,
 		0.0,
 		0.020735593738450,
 		0.0,
		-0.012841319952088,
 		0.0,
 		0.007661071732386,
 		0.0,
		-0.004309013739577,
 		0.0,
 		0.002228554058301,
 		0.0,
		-0.001021402764262,
 		0.0,
 		0.000387037706656,
 		0.0,
		-0.000100538344543
	);


    constant FIR_TAPS : real_array_t := (
 		-0.0017,	0.0,	0.0029,		0.0,	-0.0067,	0.0,	0.0141,		0.0,	-0.0268,	0.0,	0.0491,		0.0,	-0.0969,	0.0,	0.3156,
		0.5008,		
		0.3156,		0.0,   -0.0969,		0.0,	 0.0491,	0.0,	-0.0268,	0.0,	0.0141,		0.0,	-0.0067,	0.0,	 0.0029,	0.0,	-0.0017
	);
	
begin

    U_filter_re: entity work.btle_fir_filter(systolic)
        generic map (
        	MAX_TIMESLOTS => max_channels,
            H => FIR_TAPS
        )
        port map(
            clock => clock,
            reset => reset,

            in_sample => in_iq_bus.real,
            in_valid => in_iq_bus.valid,
            in_timeslot => in_iq_bus.timeslot,

            out_sample => filtered_iq_bus.real,
            out_valid => filtered_iq_bus.valid,
            out_timeslot => filtered_iq_bus.timeslot
        );
        
    U_filter_im: entity work.btle_fir_filter(systolic)
        generic map (
        	MAX_TIMESLOTS => max_channels,
            H => FIR_TAPS
        )
        port map(
            clock => clock,
            reset => reset,

            in_sample => in_iq_bus.imag,
            in_valid => in_iq_bus.valid,
 			in_timeslot => in_iq_bus.timeslot,
 			
            out_sample => filtered_iq_bus.imag,
            out_valid => open,
            out_timeslot => open
        );


	U_fsk: entity work.btle_fsk_demodulator
		generic map (
			MAX_TIMESLOTS => max_channels
		)
  		port map (
    		clock => clock,
    		reset => reset,

    		in_real =>  decimated_iq_bus.real,
    		in_imag =>  decimated_iq_bus.imag,
    		in_valid => decimated_iq_bus.valid,
    		in_timeslot => decimated_iq_bus.timeslot,

    		out_symbol =>   fsk_output.symbol,
    		out_valid => 	fsk_output.valid,
    		out_timeslot => fsk_output.timeslot
  		);

	decimate: 
	process(clock, reset) is		
		type phase_array_t is array (0 to max_channels - 1) of natural range 0 to samples_per_bit - 1;

		variable phases: phase_array_t;
		variable this_ts : integer range 0 to max_channels - 1;
		variable this_phase : integer range 0 to samples_per_bit - 1;

		begin
			if reset = '1' then

				for i in 0 to max_channels - 1 loop
					phases(i) := 0;
				end loop;

				decimated_iq_bus <= ((others => '0'), (others => '0'), '0', (others => '0'));
		
			elsif rising_edge(clock) then

				decimated_iq_bus <= ((others => '0'), (others => '0'), '0', (others => '0'));
				
				if filtered_iq_bus.valid = '1' then

					this_ts := to_integer(filtered_iq_bus.timeslot);

					if phases(this_ts) = samples_per_bit - 1 then
						decimated_iq_bus.real <= filtered_iq_bus.real;
						decimated_iq_bus.imag <= filtered_iq_bus.imag;
						decimated_iq_bus.timeslot <= filtered_iq_bus.timeslot;
						decimated_iq_bus.valid <= '1';
						phases(this_ts) := 0;
					else 
						phases(this_ts) := phases(this_ts) + 1;
					end if;	
				end if;
			end if;
		end 
	process;


	output_decision:
	process(clock, reset) is		
		begin
			if reset = '1' then

				out_bit_bus.seq <= '0';
				out_bit_bus.timeslot <=  (others => '0');
				out_bit_bus.valid <= '0';

			elsif rising_edge(clock) then

				out_bit_bus.valid <= '0';
				
				if fsk_output.valid = '1' then

					if fsk_output.symbol >= 0 then
						out_bit_bus.seq <= '1';
					else
						out_bit_bus.seq <= '0';
					end if;
					
					out_bit_bus.timeslot <= fsk_output.timeslot;
					out_bit_bus.valid <= '1';

				end if;
			end if;
		end 
	process;

end rtl;

