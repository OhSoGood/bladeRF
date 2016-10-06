--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.btle_iq_streamer;

entity fft_standalone_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of fft_standalone_tb is

	signal iq_enable: std_logic := '0';

	signal clk: std_logic := '0';
	signal reset_n: std_logic := '0';
	signal fftpts_in : std_logic_vector (4 downto 0) := (others => '0'); 
	signal fftpts_out : std_logic_vector (4 downto 0):= (others => '0'); 

	signal inverse: std_logic := '0';
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
	
begin


	iq: entity work.btle_iq_streamer 
	generic map(filepath => "simulation\\" & "basic_fft_in.txt")
	port map(
		clock => clk,
		reset => not reset_n,
		enable => iq_enable,
		iq_real => sink_real,
		iq_imag => sink_imag,
		iq_valid => sink_valid,
		iq_done => open
	);

	dut: entity work.fft_ii_0_example_design_core
	port map(
		clk => clk,
		fftpts_in => fftpts_in,
		fftpts_out => fftpts_out,
		inverse => inverse,
		reset_n => reset_n,
		sink_eop => sink_eop,
		sink_error => sink_error,
		sink_imag => sink_imag,
		sink_ready => sink_ready,
		sink_real => sink_real,
		sink_sop => sink_sop,
		sink_valid => sink_valid,
		source_eop => source_eop,
		source_error => source_error,
		source_imag => source_imag,
		source_sop => source_sop,
		source_valid => source_valid,
		source_ready => source_ready,
		source_real => source_real);


    clk <= not clk after 15.625 ns;
    reset_n <= '0', '1' after 100 ns;
    
    stimulus: 
    process

    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until reset_n = '1';
			wait until rising_edge(clk);

			fftpts_in <= "10000";
			source_ready <= '1';

			iq_enable <= '1';
			wait until rising_edge(clk);

 			sink_sop <= '1';
 			wait until rising_edge(clk);
 			sink_sop <= '0';

 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 		 	wait until rising_edge(clk);	 			 			
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 		 	wait until rising_edge(clk);	
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 		 	wait until rising_edge(clk);	
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);

 			sink_eop <= '1';
 			wait until rising_edge(clk);
 			sink_eop <= '0';

 						sink_sop <= '1';
 			wait until rising_edge(clk);
 			sink_sop <= '0';

 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 		 	wait until rising_edge(clk);	 			 			
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 		 	wait until rising_edge(clk);	
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 		 	wait until rising_edge(clk);	
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);

 			sink_eop <= '1';
 			wait until rising_edge(clk);
 			sink_eop <= '0';

 						sink_sop <= '1';
 			wait until rising_edge(clk);
 			sink_sop <= '0';

 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 		 	wait until rising_edge(clk);	 			 			
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 		 	wait until rising_edge(clk);	
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);
 		 	wait until rising_edge(clk);	
 			wait until rising_edge(clk);
 			wait until rising_edge(clk);

 			sink_eop <= '1';
 			wait until rising_edge(clk);
 			sink_eop <= '0';

 			

			for i in 1 to 100  loop
 				wait until rising_edge(clk);
 			end loop;

						
        	report("End of testbench. All tests passed.");

        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process; 
end testbench;
