library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity btle_delay_line is
	generic(
  		W                 : integer := 8; 
  		L                 : integer := 1200
  	);
	port(
  		clock: 		in  std_logic;
  		sync_reset: in  std_logic;
  		in_data: 	in  std_logic_vector(W - 1 downto 0);
  		out_data: 	out std_logic_vector(W - 1 downto 0)
  	);

end btle_delay_line;

architecture rtl of btle_delay_line is

	type t_ram is array (L - 2 downto 0) of std_logic_vector(W - 1 downto 0);
	signal m_ram : t_ram;

	signal r_addr_wr         : integer range 0 to L-2;
	signal r_addr_rd         : integer range 0 to L-2;
	signal r_enable_read     : std_logic;

begin

	p_write : 
	process (clock, sync_reset)
		begin
			if(sync_reset = '1') then

				r_addr_wr <= 0;
      			r_enable_read <= '0';
		
  			elsif rising_edge(clock) then
    			
      			m_ram(r_addr_wr) <= in_data;

      			if(r_addr_wr < L - 2) then
        			r_addr_wr <= r_addr_wr + 1;
      			else
        			r_addr_wr <= 0;
        			r_enable_read <= '1';
      			end if;
  			end if;
		end 
	process p_write;

	p_read : 
	process (clock, sync_reset)
		begin
			if(sync_reset = '1') then

		    	r_addr_rd <= 0;
		    	out_data <= (others => '0');
		      				
  			elsif rising_edge(clock) then

      			if(r_enable_read = '1') then

        			out_data <= m_ram(r_addr_rd);

        			if(r_addr_rd < L - 2) then
          				r_addr_rd <= r_addr_rd + 1;
        			else
          				r_addr_rd <= 0;
        			end if;
        			
    			end if;
    			
  			end if;
		end 
	process p_read;
end rtl;
