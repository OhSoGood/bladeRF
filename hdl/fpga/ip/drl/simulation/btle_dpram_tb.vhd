--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;


entity btle_dpram_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_dpram_tb is

		signal clock: 		std_logic := '0';
		signal reset:		std_logic := '0';

		signal wr_data:		std_logic_vector(31 downto 0);
		signal wr_addr: 	unsigned(9 downto 0);
		signal wr_en:		std_logic := '0';

		signal rd_addr:		unsigned(9 downto 0);
		signal rd_data:		std_logic_vector(31 DOWNTO 0);
	
begin


	dut: entity work.btle_dpram

	port map(
		clock 		=> 	clock,
		reset 		=> 	reset,
		in_wr_data	=>	wr_data,
		in_wr_addr	=>  wr_addr,
		in_wr_en	=>  wr_en,
		in_rd_addr	=>	rd_addr,
		out_rd_data	=>  rd_data
		);

    clock <= not clock after 15.625 ns;
    reset <= '1', '0' after 100 ns;
    
    stimulus: 
    process
		variable v : integer := 1020;
    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until reset = '0';
			wait until rising_edge(clock);

			for i in 1020 to 1030  loop
 				wait until rising_edge(clock);

 				wr_addr <= to_unsigned(i, wr_addr'length);
 				wr_data <= std_logic_vector(to_unsigned(i, wr_data'length));
 				wr_en <= '1';

 			end loop;

 			wait until rising_edge(clock);
 			wait until rising_edge(clock);
 			wait until rising_edge(clock);

			rd_addr <= to_unsigned(v mod 1024, rd_addr'length);
			v := v + 1;
 			wait until rising_edge(clock);

			rd_addr <= to_unsigned(v mod 1024, rd_addr'length);
			v := v + 1;
 			wait until rising_edge(clock);

			for i in 1 to 9 loop
			
				assert to_integer(unsigned(rd_data)) = v - 2
					report "Addr:" & to_string(v - 2) & " Data:" & to_string(rd_data)
						severity failure;

				rd_addr <= to_unsigned(v mod 1024, rd_addr'length);
				v := v + 1;

				wait until rising_edge(clock);

			end loop;
			

 			report("End of testbench. All tests passed.");

        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process; 

end;
