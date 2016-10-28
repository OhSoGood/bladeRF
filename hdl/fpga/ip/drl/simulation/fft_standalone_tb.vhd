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

	signal inverse: std_logic_vector(0 downto 0) := (others => '0');
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


	component fft is
		port (
			clk          : in  std_logic                     := 'X';             -- clk
			reset_n      : in  std_logic                     := 'X';             -- reset_n
			sink_valid   : in  std_logic                     := 'X';             -- sink_valid
			sink_ready   : out std_logic;                                        -- sink_ready
			sink_error   : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- sink_error
			sink_sop     : in  std_logic                     := 'X';             -- sink_sop
			sink_eop     : in  std_logic                     := 'X';             -- sink_eop
			sink_real    : in  signed(15 downto 0) := (others => 'X'); -- sink_real
			sink_imag    : in  signed(15 downto 0) := (others => 'X'); -- sink_imag
			fftpts_in    : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- fftpts_in
			inverse      : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- inverse
			source_valid : out std_logic;                                        -- source_valid
			source_ready : in  std_logic                     := 'X';             -- source_ready
			source_error : out std_logic_vector(1 downto 0);                     -- source_error
			source_sop   : out std_logic;                                        -- source_sop
			source_eop   : out std_logic;                                        -- source_eop
			source_real  : out signed(15 downto 0);                    -- source_real
			source_imag  : out signed(15 downto 0);                    -- source_imag
			fftpts_out   : out std_logic_vector(4 downto 0)                      -- fftpts_out
		);
	end component fft;
	
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

	dut : component fft
		port map (
			clk          => clk,          --    clk.clk
			reset_n      => reset_n,      --    rst.reset_n
			sink_valid   => sink_valid,   --   sink.sink_valid
			sink_ready   => sink_ready,   --       .sink_ready
			sink_error   => sink_error,   --       .sink_error
			sink_sop     => sink_sop,     --       .sink_sop
			sink_eop     => sink_eop,     --       .sink_eop
			sink_real    => sink_real,    --       .sink_real
			sink_imag    => sink_imag,    --       .sink_imag
			fftpts_in    => fftpts_in,    --       .fftpts_in
			inverse      => inverse,      --       .inverse
			source_valid => source_valid, -- source.source_valid
			source_ready => source_ready, --       .source_ready
			source_error => source_error, --       .source_error
			source_sop   => source_sop,   --       .source_sop
			source_eop   => source_eop,   --       .source_eop
			source_real  => source_real,  --       .source_real
			source_imag  => source_imag,  --       .source_imag
			fftpts_out   => fftpts_out    --       .fftpts_out
		);


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
