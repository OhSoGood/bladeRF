

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spiral_fft is
	port (
		clk          : in  std_logic                     := '0';
		reset	     : in  std_logic                     := '0';
		next_in      : in  std_logic                     := '0';
		next_out     : out std_logic;                           

		x0    		 : in  signed(15 downto 0) := (others => '0');
		y0    		 : out signed(15 downto 0);
		x1    		 : in  signed(15 downto 0) := (others => '0');
		y1    		 : out signed(15 downto 0);
		x2    		 : in  signed(15 downto 0) := (others => '0');
		y2    		 : out signed(15 downto 0);
		x3    		 : in  signed(15 downto 0) := (others => '0');
		y3    		 : out signed(15 downto 0)
	);
end entity spiral_fft;

architecture rtl of spiral_fft is
	component dft_npb is
		port (
			clk          : in  std_logic                     := '0';
			reset	     : in  std_logic                     := '0';
			next_i       : in  std_logic                     := '0';
			next_out     : out std_logic;                           

			x0    		 : in  signed(15 downto 0) := (others => '0');
			y0    		 : out signed(15 downto 0);
			x1    		 : in  signed(15 downto 0) := (others => '0');
			y1    		 : out signed(15 downto 0);
			x2    		 : in  signed(15 downto 0) := (others => '0');
			y2    		 : out signed(15 downto 0);
			x3    		 : in  signed(15 downto 0) := (others => '0');
			y3    		 : out signed(15 downto 0)
		);
	end component dft_npb;

begin

	u_dft_top : component dft_npb
		port map (
			clk          => clk,
			reset        => reset,
			next_i   	 => next_in,
			next_out     => next_out,
			x0   	     => x0,
			y0     		 => y0,
			x1     		 => x1,
			y1    		 => y1,
			x2    		 => x2, 
			y2    		 => y2,
			x3           => x3,
			y3 			 => y3
		);

end architecture rtl; 

