
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.gb_package.all;

entity gb_ram is
Port(
	mem_clock,clock : in std_logic; 
			i : in ram_in;
			o: out ram_out);
end gb_ram; 

architecture Behavioral of gb_ram is

component blockram is
Port(clock : in std_logic;  
			i : in ram_in;
			o: out ram_out);
end component; 

component gb_tetris_rom is
	Port(clk : in std_logic; 
	idx : in std_logic_vector(15 downto 0);
				data: out std_logic_vector(7 downto 0));
end component; 

type ram_state is record 
        data : gb_word;
end record ram_state;

signal r,rin: ram_state;
signal v_rmin, b_rmin: ram_in;
signal v_rmout, b_rmax : ram_out;
signal rom_idx : gb_doubleword;
signal rom_data : gb_word;
begin

rom: gb_tetris_rom port map (clk=>clock, idx => rom_idx, data => rom_data);
v_ram: blockram port map (clock=>clock, i => v_rmin, o => v_rmout);

sync : process (mem_clock,rin)
begin
	if rising_edge(mem_clock) then		
		r <= rin;
	end if;
end process;

comb : process (r,i,v_rmout,rom_data)
variable v : ram_state;
begin	
	v := r;

	if(i.addr(15) = '0') then
		v.data := rom_data;
	else
		v.data := v_rmout.data;
	end if;

	rin <= v;
	rom_idx <= i.addr;
	v_rmin.we <= i.we;
	v_rmin.data <= i.data;
	v_rmin.addr(15 downto 14) <= "00";
	v_rmin.addr(13 downto 0) <= i.addr(13 downto 0);
	o.data <= r.data;
end process;
end Behavioral;