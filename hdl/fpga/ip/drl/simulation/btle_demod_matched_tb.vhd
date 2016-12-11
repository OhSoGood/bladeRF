--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.btle_complex.all;
use work.btle_common.all;

entity btle_demod_matched_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_demod_matched_tb is
	constant TB_DATA_PATH: string := "simulation/";

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';

	signal iq_enable: std_logic := '0';
	signal iq_complete: std_logic := '0';

	signal iq_bus: iq_bus_t;
	signal bit_bus: tdm_bit_bus_t;
	
    
begin
    duv: entity work.btle_demod_matched 
	generic map( samples_per_bit => 2, max_channels => 16)
    port map(
    	clock => clock,
    	reset => reset,
        in_iq_bus.valid => iq_bus.valid,
        in_iq_bus.real => iq_bus.real,
       	in_iq_bus.imag => iq_bus.imag,
       	in_iq_bus.timeslot => to_unsigned(5, 5),
        out_bit_bus => bit_bus
 	);

	iq: entity work.btle_iq_streamer 
	generic map(filepath => TB_DATA_PATH & "tx_symbols.txt")
	port map(
		clock => clock,
		reset => reset,
		enable => iq_enable,
		out_iq_bus => iq_bus,
		iq_done => iq_complete
	);

    clock <= not clock after 500 ns;
    reset <= '1', '0' after 20 ns;

    stimulus: 
    process

    	begin
			test_runner_setup(runner, runner_cfg);
			
		   	wait until not reset;

			iq_enable <= '1';			
			wait until iq_complete;
			iq_enable <= '0';
			
        	report("End of testbench. All tests passed.");

        	test_runner_cleanup(runner);
        	std.env.finish;
    	end 
    process;

	checker:
	process(clock, reset)
	    file rx_bits: text open read_mode is TB_DATA_PATH & "rx_bits.txt";
	    variable current_line : line;
    	variable bit: std_logic;
		variable i : integer;
		begin
			if reset = '1' then
			
				i := 0;

			elsif rising_edge(clock) then
				if bit_bus.valid = '1' then
					if not endfile(rx_bits) then
						readline(rx_bits, current_line);
						read(current_line, bit);
						
						assert bit_bus.seq = bit report "Demodulated bit was wrong at position " & to_string(i) severity failure;
						i := i + 1;
					else
						assert false report "End of input bitfile" severity failure;
					end if;
				end if;
			end if;
		end
	process;  
end;