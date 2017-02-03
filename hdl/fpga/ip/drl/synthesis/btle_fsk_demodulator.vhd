-- Copyright (c) 2013 Nuand LLC
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

library work ;
	use work.btle_common.all;
    use work.cordic_p.all ;

entity btle_fsk_demodulator is
	generic (
		MAX_TIMESLOTS : positive := 1
	);
  	port (
    	clock       :   in  std_logic ;
    	reset       :   in  std_logic ;

    	in_real     :   in  signed(15 downto 0) ;
    	in_imag     :   in  signed(15 downto 0) ;
    	in_valid    :   in  std_logic ;
    	in_timeslot :   in  timeslot_t;

    	out_symbol  :   out signed(15 downto 0) ;
    	out_valid   :   out std_logic;
    	out_timeslot:   out timeslot_t
  ) ;
end entity ; -- fsk_demodulator

architecture arch of btle_fsk_demodulator is

	type z_results_t is record
    	prev_z           : signed(15 downto 0) ;
    	delta_z          : signed(15 downto 0) ;
	end record;

	type unwrapped_results_array_t is array (0 to MAX_TIMESLOTS - 1) of signed(15 downto 0) ;
	type z_results_array_t is array (0 to MAX_TIMESLOTS - 1) of z_results_t;

    signal delta_z_valid    : std_logic ;
    signal delta_z_timeslot : timeslot_t ;
	signal z_results  : z_results_array_t;
	signal unwrapped_z : unwrapped_results_array_t;

    signal cordic_inputs: 		cordic_xyz_t ;
    signal cordic_outputs: 		cordic_xyz_t ;

    signal unwrapped_valid  : std_logic ;
    signal unwrapped_timeslot : timeslot_t ;
    
begin

    U_cordic : entity work.cordic
      port map (
        clock   => clock,
        reset   => reset,
        mode    => CORDIC_VECTORING,
        inputs  => cordic_inputs,
        outputs => cordic_outputs
      ) ;

	feed_cordic: process(clock, reset)
	begin
        if( reset = '1' ) then
        
			cordic_inputs <= ( x => (others =>'0'), y => (others =>'0'), z => (others =>'0'), valid => '0', timeslot => (others =>'0') ) ;

        elsif ( rising_edge( clock ) ) then

			cordic_inputs.valid <= '0';
			
        	if in_valid = '1' then
				cordic_inputs <= ( x => in_real, y => in_imag, z => (others =>'0'), valid => in_valid, timeslot => in_timeslot) ;
        	end if;
        end if;
	end process;


    find_derivative : process(clock, reset)
    begin
        if( reset = '1' ) then

            delta_z_valid <= '0' ;
            delta_z_timeslot <= (others =>'0') ;

			for i in 0 to MAX_TIMESLOTS - 1 loop
		    	z_results(i).prev_z <= (others => '0');
		    	z_results(i).delta_z <= (others => '0');
			end loop;
			
        elsif( rising_edge( clock ) ) then

            delta_z_valid <= '0';
            delta_z_timeslot <= (others => '0');
            
            if( cordic_outputs.valid = '1' ) then

				delta_z_valid <= '1';
            	delta_z_timeslot <= cordic_outputs.timeslot;
            	z_results(to_integer(cordic_outputs.timeslot)).prev_z <= cordic_outputs.z ;
                z_results(to_integer(cordic_outputs.timeslot)).delta_z <= cordic_outputs.z - z_results(to_integer(cordic_outputs.timeslot)).prev_z ;

            end if ;
        end if ;
    end process ;

    unwrap : process(clock, reset)

	variable dz_ts: integer range 0 to MAX_TIMESLOTS - 1;
	
    begin
        if( reset = '1' ) then
        
            unwrapped_valid <= '0' ;
            unwrapped_timeslot <= (others => '0');

			for i in 0 to MAX_TIMESLOTS - 1 loop
		    	unwrapped_z(i) <= (others => '0');
			end loop;

        elsif( rising_edge( clock ) ) then
        
            unwrapped_valid <= '0';
			unwrapped_timeslot <= (others => '0');
			
            if delta_z_valid = '1' then

            	dz_ts := to_integer(delta_z_timeslot);

				unwrapped_valid <= '1';
            	unwrapped_timeslot <= delta_z_timeslot;
            	
            	if z_results(dz_ts).delta_z > 4096 then
                	unwrapped_z(dz_ts) <= z_results(dz_ts).delta_z - 8192 ;
            	elsif z_results(dz_ts).delta_z < -4096 then
                	unwrapped_z(dz_ts) <= z_results(dz_ts).delta_z + 8192 ;
            	else
                	unwrapped_z(dz_ts) <= z_results(dz_ts).delta_z ;
            	end if ;
            end if;
        end if ;
    end process ;

	output:
	process(clock, reset)
		begin
        	if( reset = '1' ) then

            	out_symbol <= (others => '0');
				out_valid <= '0';
				out_timeslot <= (others => '0');
				
        	elsif( rising_edge( clock ) ) then

				out_valid <= '0';
				
				if unwrapped_valid = '1' then

					out_symbol <= unwrapped_z(to_integer(unwrapped_timeslot));
					out_timeslot <= unwrapped_timeslot;
					out_valid <= '1';

				end if;        	
        	end if;
		end 
	process;

end architecture ; -- arch
