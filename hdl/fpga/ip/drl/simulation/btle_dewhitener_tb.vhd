--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity btle_dewhitener_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_dewhitener_tb is
	constant TB_DATA_PATH: string := "simulation/";
	
    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    signal seq_restart: std_logic := '0';
   	signal in_valid: std_logic := '1';
    signal out_seq: std_logic := '0';
	signal out_valid: std_logic := '0';
	signal test_done: std_logic := '0';

begin
    duv: entity work.btle_dewhitener 
     port map(
    	clock => clock,
    	reset => reset,
    	in_restart => seq_restart,
       	in_seq => '0',
       	in_valid => in_valid,
       	in_ch_idx => to_unsigned(37, 6),
        out_seq => out_seq,
        out_valid => out_valid
        );

    clock <= not clock after 500 ns;
    reset <= '1', '0' after 20 ns;

    stimulus: 
    process
    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until not reset;
			wait until rising_edge(clock);

			in_valid <= '1';

			wait until rising_edge(clock);
			
			wait until test_done = '1';				

		    report("End of testbench. All tests passed.");
        	test_runner_cleanup(runner);
        	std.env.finish;
			
    	end 
    process; 


	checker:
	process(clock, reset)

	    file rx_bits: text open read_mode is TB_DATA_PATH & "dew37.txt";

		variable f_status: FILE_OPEN_STATUS;
	    variable current_line : line;
    	variable bit: std_logic;
		variable i: integer;

		begin
			if reset = '1' then

				seq_restart <= '0';
				test_done <= '0';
				i := 1;

			elsif rising_edge(clock) then

				if out_valid = '1' then

					test_done <= '0';
					seq_restart <= '0';

					if not endfile (rx_bits) then 
					
						readline(rx_bits, current_line);
						read(current_line, bit);

						assert out_seq = bit report "Demodulated bit was wrong at position " & to_string(i) severity failure;

						if i = 335 then
							seq_restart <= '1';
						end if;

						i := i + 1;

					else

						report "End of file, compared " & to_string(i) & " bits."; 
						test_done <= '1';

					end if;
				end if;
			end if;
		end
	process;  

end;
