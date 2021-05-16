----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.03.2021 13:48:43
-- Design Name: 
-- Module Name: mainboard - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.gb_package.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mainboard is
Port (  sw : in STD_LOGIC_VECTOR (15 downto 0);
           
           clk_source: in STD_LOGIC;
           led : out STD_LOGIC_VECTOR (15 downto 0);
           
           Vsync: buffer STD_LOGIC;     
           Hsync: buffer STD_LOGIC;   
           vgaGreen,vgaRed,vgaBlue : out STD_LOGIC_VECTOR (3 downto 0)
           );
end mainboard;

architecture Behavioral of mainboard is


component  gb_display is
	port
	(
		reset: in std_logic;
		clk_in: in std_logic;

		fb_data: in std_logic_vector(1 downto 0);
		fb_coord: out gb_px_coord;
		fb_read: out std_logic;

		hsyncb: out std_logic;	
		vsyncb: out std_logic;	
		rgb: out std_logic_vector(11 downto 0) 
	);
end component;

component gb_writeable_framebuffer is
  Port (
    fb_write: in std_logic_vector(7 downto 0);
    fb_read: out std_logic_vector(7 downto 0);
	fb_coord_write,fb_coord_read: in gb_px_coord;   
    clk, write: in std_logic
);

end component;

component clk_divider is
    generic (N : integer);
    Port ( clk,reset : in STD_LOGIC;
           clk_out : out STD_LOGIC);
end component;
component gb_ppu is
  generic ( MapAdress : integer := 0; TileAdress : integer := 1024) ;
  Port ( pixel_clk,hstart: in std_logic; -- input clocks
         rom_data, vertline: in std_logic_vector(7 downto 0); -- ROM data input 
          
          rom_addr : out std_logic_vector(15 downto 0); -- ram address
          output_enable,rom_load, line_ended,load_sprite: out std_logic; -- requests ram data
          pix_out: out std_logic_vector(1 downto 0); -- palletized pixel 2bit
          pix_out_coord: out gb_px_coord  -- pixel out coordinate                       
         );
end component;

component gb_tetrismap_rom is
Port(clk : in std_logic; 
idx : in std_logic_vector(15 downto 0);
			data: out std_logic_vector(7 downto 0));
end component; 

component gb_tetrissprites_rom is
Port(clk : in std_logic; 
idx : in std_logic_vector(15 downto 0);
			data: out std_logic_vector(7 downto 0));
end component; 

component gb_ppu_vgasync is
  Port (
    pixel_clk,hsync,vsync, render_done: in std_logic;
    ppu_start: out std_logic;
    ppu_vertline: out std_logic_vector(7 downto 0)
	);

end component;

component gb_alu is

Port ( i : in alu_in;
	o : out alu_out
	);
end component;

component gb_reg is

Port ( clk,reset : in std_logic;
		i : in reg_in; -- input clocks
		o : out reg_out
		);
end component;
	
component gb_decoder is 
Port ( clk,reset : in std_logic;
		i : in decoder_in; 
		o : out decoder_out
		);
end component;

component gb_ram is
		Port(
			mem_clock,clock, ppu_drawing : in std_logic; 

			i_ppu, i_cpu : in ram_in;
			o_ppu,o_cpu: out ram_out);

end component; 


signal pixel_clock,ram_clock,draw_clock,reset, pc1,pc2,pc3,rom_load,hb,write_framebuffer,hstart,output_enable : std_logic;
signal vga_rgb : std_logic_vector(11 downto 0);
signal	fb_data:  std_logic_vector(1 downto 0);
signal	fb_coord, ppu_coord, vga_coord:  gb_px_coord; 

signal	fb_read,fb_write:  std_logic_vector(7 downto 0);
signal wants_read: std_logic;

signal ppu_line : integer;
signal ppu_vline : std_logic_vector(7 downto 0);

signal rom_data,sprite_data,map_data : std_logic_vector(7 downto 0);
signal pix_out : std_logic_vector(1 downto 0);
signal rom_addr,sprite_addr,tile_addr : std_logic_vector(15 downto 0);
signal load_sprite ,render_done: std_logic;
signal pix_out_coord:  gb_px_coord ;

signal aluin: alu_in;
signal aluout : alu_out;
signal regin: reg_in;
signal regout : reg_out;
signal decin: decoder_in;
signal decout : decoder_out;
signal rmin, rmin_ppu: ram_in;
signal rmout, rmout_ppu : ram_out;
signal is_draw : std_logic;
begin

reset <= sw(0);
led(0) <= '0';
vgaRed <= vga_rgb(3 downto 0);
--vgaRed(3) <= rom_load;

vgaGreen <= vga_rgb(7 downto 4);

vgaBlue <= vga_rgb(11 downto 8);
hsync <= hb;
fb_data <= fb_read(1 downto 0);

write_framebuffer <=(not wants_read);
--fb_coord <= vga_coord when wants_read = '1' else ppu_coord;

--hstart <= not wants_read;
 

fb_write(7 downto 2) <= "000000";
fb_write(1 downto 0) <= pix_out;
--vga: vgacore port map (reset=>reset,clk_in=> pixel_clock,hsyncb => Hsync,vsyncb => Vsync,rgb => vga_rgb);
 fb : gb_writeable_framebuffer port map (
	clk=>draw_clock,
	fb_coord_read => vga_coord,
	fb_coord_write => ppu_coord,
	fb_read=>fb_read,
	fb_write=>fb_write,
	write=>output_enable
);
ram_clock <= decout.ramclock;--draw_clock;
draw_clock <= ram_clock;
--rsprites : gb_tetrissprites_rom port map (draw_clock,sprite_addr,sprite_data);
--rtiles : gb_tetrismap_rom port map (draw_clock,tile_addr,map_data);
is_draw <= rom_load and sw(1);
ram: gb_ram port map (mem_clock=> ram_clock,clock=>clk_source,  
ppu_drawing => is_draw,

i_cpu => rmin, o_cpu => rmout,
i_ppu => rmin_ppu, o_ppu => rmout_ppu
);
alu: gb_alu port map (i => aluin, o => aluout);
reg: gb_reg port map (clk=> clk_source, reset => reset, i => regin, o => regout);
dec: gb_decoder port map (clk=> clk_source, reset => reset, i => decin, o => decout);

led(15 downto 8) <= regout.data_A;
led(7 downto 1) <= regout.PC(7 downto 1);

decin.ram <= rmout;
decin.reg <= regout;
decin.alu <= aluout;

regin <= decout.reg;
aluin <= decout.alu;
rmin <= decout.ram;


rmin_ppu.data <= x"00";
rmin_ppu.addr(15) <= '1';
rmin_ppu.addr(14 downto 0) <= rom_addr(14 downto 0);
rmin_ppu.we <= '0';

rom_data <= rmout_ppu.data;

sync: gb_ppu_vgasync port map(pixel_clk => draw_clock,hsync=>hsync, vsync=>vsync,render_done=>render_done,ppu_start=>hstart,ppu_vertline=>ppu_vline );


ppu: gb_ppu 
generic map (MapAdress => 6144,TileAdress => 0 )
port map (
	pixel_clk=>draw_clock,
	hstart=> hstart,
	rom_addr=>rom_addr,
	rom_data => rom_data,
	vertline => ppu_vline,
	output_enable => output_enable,
	rom_load=>rom_load,
	line_ended => render_done,
	load_sprite => load_sprite,
	pix_out => pix_out, -- palletized pixel 2bit
	pix_out_coord=>ppu_coord       -- pixel out coordinate           
);

vga: gb_display port map (
	reset=>reset,clk_in=> pixel_clock,
	hsyncb => hb,vsyncb => Vsync,rgb => vga_rgb, 
	fb_data=>fb_data, 
	fb_coord=>vga_coord,
	fb_read=>wants_read
);
 

--div1: clk_divider generic map (N => 2) port map (clk=> clk_source,  reset=>reset,clk_out=> draw_clock);
div2: clk_divider generic map (N => 3) port map (clk=> clk_source,  reset=>reset,clk_out=> pixel_clock);
end Behavioral;
