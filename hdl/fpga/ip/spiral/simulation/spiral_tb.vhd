library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;


entity spiral_fft_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;

architecture testbench of spiral_fft_tb is

	signal clock: std_logic := '0';
	signal reset: std_logic := '0';
	signal next_in: std_logic := '0';
	signal next_out: std_logic := '0';

	signal x0:  signed(15 downto 0);
	signal y0:  signed(15 downto 0);
	signal x1:  signed(15 downto 0);
	signal y1:  signed(15 downto 0);
	signal x2:  signed(15 downto 0);
	signal y2:  signed(15 downto 0);
	signal x3:  signed(15 downto 0);
	signal y3:  signed(15 downto 0);

begin

	dut: entity work.spiral_fft
	port map (
		clk => clock,
		reset => reset,
		next_in => next_in,
		next_out => next_out,
		x0 => x0,
		y0 => y0,
		x1 => x1,
		y1 => y1,
		x2 => x2,
		y2 => y2,
		x3 => x3,
		y3 => y3
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
			wait until rising_edge(clock);
			wait until rising_edge(clock);
			wait until rising_edge(clock);
			wait until rising_edge(clock);

			next_in <= '1';

			wait until rising_edge(clock);
			
			next_in <= '0';
			x0 <= to_signed(0, 16);			
			x1 <= to_signed(0, 16);			
			x2 <= to_signed(392, 16);		
			x3 <= to_signed(0, 16);			
			
			wait until rising_edge(clock);

			x0 <= to_signed(724, 16);		
			x1 <= to_signed(0, 16);			
			x2 <= to_signed(946, 16);		
			x3 <= to_signed(0, 16);			
			
			wait until rising_edge(clock);

			x0 <= to_signed(1024, 16);	
			x1 <= to_signed(0, 16);		
			x2 <= to_signed(946, 16);		
			x3 <= to_signed(0, 16);			
			
			wait until rising_edge(clock);


			x0 <= to_signed(724, 16);		
			x1 <= to_signed(0, 16);		
			x2 <= to_signed(392, 16);	
			x3 <= to_signed(0, 16);		
			
			wait until rising_edge(clock);


			x0 <= to_signed(0, 16);		
			x1 <= to_signed(0, 16);		
			x2 <= to_signed(-392, 16);	
			x3 <= to_signed(0, 16);		
			
			wait until rising_edge(clock);

			x0 <= to_signed(-724, 16);	
			x1 <= to_signed(0, 16);		
			x2 <= to_signed(-946, 16);	
			x3 <= to_signed(0, 16);	
			
			wait until rising_edge(clock);

			x0 <= to_signed(-1024, 16);	
			x1 <= to_signed(0, 16);		
			x2 <= to_signed(-946, 16);	
			x3 <= to_signed(0, 16);		
			
			wait until rising_edge(clock);

			x0 <= to_signed(-724, 16);	
			x1 <= to_signed(0, 16);		
			x2 <= to_signed(-392, 16);	
			x3 <= to_signed(0, 16);	
			
			for i in 1 to 500  loop
 				wait until rising_edge(clock);
 			end loop;

 			report("End of testbench. All tests passed.");

        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process; 

end;


