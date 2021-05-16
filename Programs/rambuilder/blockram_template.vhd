
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.gb_package.all;


-- CODE GENERATED
entity $ramname is
Port(
	clock : in std_logic; 
			i : in ram_in;
			o: out ram_out);
end $ramname; 

architecture Behavioral of $ramname is
constant DATA_WIDTH : integer := 8;	
constant RAM_SIZE : integer := $ramsize;
TYPE mem_type IS ARRAY(0 TO RAM_SIZE-1) OF std_logic_vector((DATA_WIDTH-1) DOWNTO 0); 

signal nx_idx,idx  : integer;


signal ram_block : mem_type :=  (
	$ramdata
	
	);

signal out_dt: std_logic_vector((DATA_WIDTH-1) DOWNTO 0); 
		
attribute ram_style  : string;

begin
sync : process (clock,i)
begin
	if rising_edge(clock) then
		
		if i.we = '1' then		
			ram_block(nx_idx) <= i.data;   
		end if; 
		o.data <= ram_block(nx_idx);
	end if;
end process;

comb : process (i)
begin	
	nx_idx <= to_integer(unsigned(i.addr));
end process;
end Behavioral;