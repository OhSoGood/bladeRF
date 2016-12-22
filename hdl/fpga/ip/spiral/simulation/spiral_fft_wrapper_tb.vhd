--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.btle_common.all;

entity spiral_fft_wrapper_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of spiral_fft_wrapper_tb is

	signal iq_enable: std_logic := '0';
	signal iq_done: std_logic := '0';

	signal clock: std_logic := '0';
	signal reset: std_logic := '0';

	signal in_iq_bus: iq_bus_t;
	signal out_iq_bus: tdm_iq_bus_t;
	
begin


	iq: entity work.btle_iq_streamer 
	generic map(filepath => "simulation\\" & "basic_fft_in.txt")
	port map(
		clock => clock,
		reset => reset,
		enable => iq_enable,
		out_iq_bus => in_iq_bus,
		iq_done => iq_done
	);

	dut: entity work.spiral_fft_wrapper
	generic map (order => 16)
	port map (
		clock => clock,
		reset => reset,
		enable => '1',
		in_iq_bus => in_iq_bus,
		out_iq_bus => out_iq_bus
	);


    clock <= not clock after 15.625 ns;
    reset <= '1', '0' after 100 ns;
    
    stimulus: 
    process
		variable v : integer := 0;
    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until reset = '0';
			wait until rising_edge(clock);

			iq_enable <= '1';

			wait until rising_edge(iq_done);
			for i in 1 to 200  loop
 				wait until rising_edge(clock);
 			end loop;

 			report("End of testbench. All tests passed.");

        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process; 


	checker:
	process(clock, reset)
	    file rx_complex: text open read_mode is "simulation\\" & "basic_fft_out.txt";
	    variable current_line : line;
    	variable i: integer;
    	variable q: integer;
    	variable v : integer;
		begin
			if reset = '1' then

				i := 0;
				q := 0;
				v := 0;
				
			elsif rising_edge(clock) then
				if out_iq_bus.valid = '1' then
				
					if not endfile(rx_complex) then
					
						readline(rx_complex, current_line);
						read(current_line, i);
						read(current_line, q);

						assert (out_iq_bus.real = i) and (out_iq_bus.imag = q)
							report "Complex result mismatch in index " & to_string(v) & " (" & to_string(i)  & " " & to_string(q) & ") vs (" & to_string(to_integer(out_iq_bus.real)) & ", " & to_string(to_integer(out_iq_bus.imag)) & ")."
							severity failure;

						assert out_iq_bus.timeslot = v
							report "Complex bin mismatch: " & to_string(v) & " /= " & to_string(to_integer(out_iq_bus.timeslot))
							severity failure;

						v := v + 1;

						if v = 16 then
							v := 0;
						end if ;
					else
					        				
					end if;
				end if;
			end if;
		end
	process;  
end;
