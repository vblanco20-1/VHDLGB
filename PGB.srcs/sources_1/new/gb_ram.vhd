
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.gb_package.all;

entity gb_ram is
Port(
	mem_clock,clock, ppu_drawing : in std_logic; 

			i_ppu, i_cpu : in ram_in;
			o_ppu,o_cpu: out ram_out);
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
component snake_ram is
	Port(clock : in std_logic;  
				i : in ram_in;
				o: out ram_out);
	end component; 


component tetris_vram is
	Port(
		clock : in std_logic; 
				i : in ram_in;
				o: out ram_out);
end component; 

type ram_state is record 
        data,ppu_data : gb_word;
		
end record ram_state;

signal r,rin: ram_state;
signal w_rmin, b_rmin , v_rmin: ram_in;
signal w_rmout, b_rmout , v_rmout: ram_out;
signal rom_idx , sprite_addr, tile_addr: gb_doubleword;
signal rom_data : gb_word;
begin
-- 0 to 32k
--rom: snake_ram port map (clk=>clock, idx => rom_idx, data => rom_data);
rom: snake_ram port map (clock=>clock, i => b_rmin, o => b_rmout);
-- 40k to 48k
work_ram: blockram port map (clock=>clock, i => w_rmin, o => w_rmout);
-- 32k to 40k (8 kb)
vram:  tetris_vram port map (clock=>clock, i => v_rmin, o => v_rmout);



sync : process (mem_clock,rin)
begin
	if rising_edge(mem_clock) then		
		r <= rin;
	end if;
end process;

comb : process (r,i_ppu,i_cpu,v_rmout,w_rmout,b_rmout,rom_data)
variable v : ram_state;
variable cpu_addr : gb_doubleword;
variable ppu_addr : gb_doubleword;
variable w_r, w_v : std_logic;
begin	
	v := r;

	w_r := '0';
	w_v := '0';

	v.ppu_data := v_rmout.data;

	if(i_cpu.addr(15) = '0') then
		v.data :=  b_rmout.data;--rom_data;
	else
		if(unsigned(i_cpu.addr) >= x"8000") then
			
			v.data := v_rmout.data;
		else			
			v.data := w_rmout.data;

		end if;		
	end if;

	rin <= v;

	-- rom and workram allways connect to the cpu adress
	rom_idx <= i_cpu.addr;
	b_rmin.addr <= i_cpu.addr;
	b_rmin.we <= '0';
	w_rmin.addr <= i_cpu.addr;
	w_rmin.we <= '0';
	w_rmin.data <= i_cpu.data;
	
	-- when the ppu is drawing the cpu cant access vram
	if( ppu_drawing = '1')then
		v_rmin.addr <= i_ppu.addr;		
		v_rmin.data <= x"00";	
		v_rmin.we <= '0';
	else
		v_rmin.addr <= i_cpu.addr;
		v_rmin.data <= i_cpu.data;	
		v_rmin.we <= i_cpu.we;
	end if;

	o_cpu.data <= r.data;
	o_ppu.data <= r.ppu_data;
end process;
end Behavioral;