
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.gb_package.all;


-- CODE GENERATED
entity snake_ram is
Port(
	clock : in std_logic; 
			i : in ram_in;
			o: out ram_out);
end snake_ram; 

architecture Behavioral of snake_ram is
constant DATA_WIDTH : integer := 8;	
constant RAM_SIZE : integer := 256;
TYPE mem_type IS ARRAY(0 TO RAM_SIZE-1) OF std_logic_vector((DATA_WIDTH-1) DOWNTO 0); 

signal nx_idx,idx  : integer;


signal ram_block : mem_type :=  (
	x"00",x"00",x"00",x"c3",x"3f",x"00",x"00",x"00",x"c3",x"0b",x"00",x"00",x"00",x"26",x"99",x"2e",x"04",x"06",x"11",x"70",x"2c",x"06",x"0e",x"70",x"2c",x"06",x"15",x"70",x"2c",x"06",x"15",x"70",x"2c",x"06",x"18",x"70",x"2c",x"06",x"25",x"70",x"2c",x"06",x"20",x"70",x"2c",x"06",x"18",x"70",x"2c",x"06",x"1b",x"70",x"2c",x"06",x"15",x"70",x"2c",x"06",x"0d",x"70",x"2c",x"c3",x"0b",x"00",x"00",x"3e",x"cc",x"00",x"c3",x"0b",x"00",x"00",x"76",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"
	
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
variable local_addr : gb_doubleword;
begin	

	local_addr(14 downto 0) := i.addr(14 downto 0);
	local_addr(15) :=  '0'; 
	nx_idx <= to_integer(unsigned(local_addr));
end process;
end Behavioral;