--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;


entity btle_iq_tracer_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;




architecture testbench of btle_iq_tracer_tb is

	signal iq_enable: std_logic := '0';
	signal iq_done: std_logic := '0';
	
	signal clock: std_logic := '0';
	signal reset: std_logic := '0';
	
	signal in_imag : signed (15 downto 0) := (others => '0');
	signal in_real : signed (15 downto 0) := (others => '0');	
	signal in_valid: std_logic := '0';

	signal out_real:  signed (15 downto 0) := (others => '0');
	signal out_imag:  signed (15 downto 0) := (others => '0');
	signal out_valid: std_logic := '0';


begin

	iq: entity work.btle_iq_streamer 
	generic map(filepath => "simulation\\" & "aa_samples.txt")
	port map(
		clock => clock,
		reset => reset,
		enable => iq_enable,
		iq_real => in_real,
		iq_imag => in_imag,
		iq_valid => in_valid,
		iq_done => iq_done
	);


	dut: entity work.btle_iq_tracer
	port map(
		clock => clock,
		reset => reset,

		in_real => in_real,
		in_imag => in_imag,
		in_valid => in_valid,

		out_real => out_real,
		out_imag => out_imag,
		out_valid => out_valid
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


end testbench ;

