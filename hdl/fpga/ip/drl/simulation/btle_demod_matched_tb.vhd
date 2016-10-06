--
-- (c) Distributed Radio Limited 2016
--     steve@distributedradio.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.btle_complex.all;

entity btle_demod_matched_tb is
	generic(runner_cfg: string);
end;

library vunit_lib;
context vunit_lib.vunit_context;


architecture testbench of btle_demod_matched_tb is
	constant TB_DATA_PATH: string := "simulation/";

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';

	signal iq_enable : std_logic := '0';
    signal iq_real: signed(15 downto 0) := to_signed(0, 16);
    signal iq_imag: signed(15 downto 0) := to_signed(0, 16);
	signal iq_valid: std_logic := '0';
	signal iq_complete : std_logic := '0';

    signal out_bit: std_logic := '0';
    signal out_valid: std_logic := '0';
    
begin
    duv: entity work.btle_demod_matched 
    port map(
    	clock => clock,
    	reset => reset,
        in_real => iq_real,
        in_imag => iq_imag,
        in_valid => iq_valid,
        out_bit => out_bit,
        out_valid => out_valid
 	);

	iq: entity work.btle_iq_streamer 
	generic map(filepath => TB_DATA_PATH & "tx_symbols.txt")
	port map(
		clock => clock,
		reset => reset,
		enable => iq_enable,
		iq_real => iq_real,
		iq_imag => iq_imag,
		iq_valid => iq_valid,
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
				if out_valid = '1' then
					if not endfile(rx_bits) then
						readline(rx_bits, current_line);
						read(current_line, bit);
						
						assert out_bit = bit report "Demodulated bit was wrong at position " & to_string(i) severity failure;
						i := i + 1;
					else
						assert false report "End of input bitfile" severity failure;
					end if;
				end if;
			end if;
		end
	process;  
end;