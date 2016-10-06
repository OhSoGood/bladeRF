library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.btle_complex.all;

entity btle_complex_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;

architecture testbench of btle_complex_tb is

begin
    checker: 
    process
    	begin
			test_runner_setup(runner, runner_cfg);
        	report("Testing entity: btle_complex addition");
		
			assert add((0,0),(0,0)) = (0,0)
				report "Error: add((0,0),(0,0)) /= (0,0)"
				severity failure;

			assert add((1,0),(0,0)) = (1,0)
				report "Error: mul((1,0),(0,0) /= (1,0)"
				severity failure;
			
			assert add((0,1),(0,0)) = (0,1)
				report "Error: add((0,1),(0,0) /= (0,1)"
				severity failure;
			
			assert add((1,1),(1,1)) = (2,2)
				report "Error: add((1,1),(1,1) /= (2,2)"
				severity failure;

			assert add((-1,-1),(1,1)) = (0,0)
				report "Error: add((-1,-1),(1,1) /= (0,0)"
				severity failure;

			assert add((-2**30,-2**30),(2**30-1,2**30-1)) = (-1,-1)
				report "Error: add((-2**30,-2**30),(2**30-1,2**30-1)) = (-1,-1)"
				severity failure;


        	report("Testing entity: btle_complex multiplication");
        	
			assert mul((0,0),(0,0),0) = (0,0)
				report "Error: mul((0,0),(0,0)) /= (0,0)"
				severity failure;

			assert mul((1,0),(1,0),0) = (1,0)
				report "Error: mul((1,0),(1,0) /= (1,0)"
				severity failure;

			assert mul((0,1),(0,1),0) = (-1,0)
				report "Error: mul((0,1),(0,1)) /= (0,-1)"
				severity failure;

			assert mul((-1,-1),(-1,-1),0) = (0,2)
				report "Error: mul((-1,-1),(-1,-1)) /= (0,2)"
				severity failure;

			assert mul((16383,16383),(16383,16383),0) = (0,536805378)
				report "Error: mul((16383,16383),(16383,16383)) = (0,536805378)"
				severity failure;

			assert mul((-16384,-16384),(-16384,-16384),0) = (0,536870912)
				report "Error: mul((-16384,-16384),(-16384,-16384)) = (0,536870912)"
				severity failure;

        	report("End of testbench. All tests passed.");
        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process;
end;