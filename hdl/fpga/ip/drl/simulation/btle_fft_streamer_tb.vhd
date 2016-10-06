--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;


entity btle_fft_streamer_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_fft_streamer_tb is

	signal iq_enable: std_logic := '0';
	signal iq_done: std_logic := '0';

	signal clock: std_logic := '0';
	signal reset_n: std_logic := '0';
	
	signal in_imag : signed (15 downto 0) := (others => '0');
	signal in_real : signed (15 downto 0) := (others => '0');	
	signal in_valid: std_logic := '0';

	signal out_real:  signed (15 downto 0) := (others => '0');
	signal out_imag:  signed (15 downto 0) := (others => '0');
	signal out_bin_idx: unsigned (4 downto 0) := (others => '0');
	signal out_valid: std_logic := '0';
	
begin


	iq: entity work.btle_iq_streamer 
	generic map(filepath => "simulation\\" & "basic_fft_in.txt")
	port map(
		clock => clock,
		reset => not reset_n,
		enable => iq_enable,
		iq_real => in_real,
		iq_imag => in_imag,
		iq_valid => in_valid,
		iq_done => iq_done
	);

	dut: entity work.btle_fft_streamer
	generic map (order => 16)
	port map(
		clock => clock,
		reset_n => reset_n,
		enable => '1',
		in_real => in_real,
		in_imag => in_imag,
		in_valid => in_valid,

		out_bin_idx => out_bin_idx,
		out_real => out_real,
		out_imag => out_imag,
		out_valid => out_valid
		);


    clock <= not clock after 15.625 ns;
    reset_n <= '0', '1' after 100 ns;
    
    stimulus: 
    process
		variable v : integer := 0;
    	begin
			test_runner_setup(runner, runner_cfg);

		   	wait until reset_n = '1';
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
	process(clock, reset_n)
	    file rx_complex: text open read_mode is "simulation\\" & "basic_fft_out.txt";
	    variable current_line : line;
    	variable i: integer;
    	variable q: integer;
    	variable v : integer;
		begin
			if reset_n = '0' then

				i := 0;
				q := 0;
				v := 0;
				
			elsif rising_edge(clock) then
				if out_valid = '1' then
				
					if not endfile(rx_complex) then
					
						readline(rx_complex, current_line);
						read(current_line, i);
						read(current_line, q);

						assert (out_real = i) and (out_imag = q)
							report "Complex result mismatch in index " & to_string(v) & " (" & to_string(i)  & " " & to_string(q) & ") vs (" & to_string(to_integer(out_real)) & ", " & to_string(to_integer(out_imag)) & ")."
							severity failure;

						assert out_bin_idx = v
							report "Complex bin mismatch: " & to_string(v) & " /= " & to_string(to_integer(out_bin_idx))
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
