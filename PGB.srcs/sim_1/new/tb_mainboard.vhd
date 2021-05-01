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

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_mainboard is
generic (runner_cfg : string);
end tb_mainboard;

architecture Behavioral of tb_mainboard is


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

component vgacore is
	port
	(
		reset: in std_logic;	
		clk_in: in std_logic;
		hsyncb: buffer std_logic;	
		vsyncb: out std_logic;	
		rgb: out std_logic_vector(11 downto 0) 
	);
end component;

component gb_writeable_framebuffer is
  Port (
    fb_write: in std_logic_vector(7 downto 0);
    fb_read: out std_logic_vector(7 downto 0);
	fb_coord: in gb_px_coord;
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


signal Vsync,Hsync, pixel_clock,reset, pc1,pc2,pc3,rom_load,hb,write_framebuffer,hstart,output_enable : std_logic;
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
signal load_sprite : std_logic;
signal pix_out_coord:  gb_px_coord ;

begin

clock: process
begin
	pixel_clock <= '1';
	wait for 10 ns;
	pixel_clock <= '0';
	wait for 10 ns;
end process;

pline: process(hsync,vsync) begin

	if rising_edge(vsync) then 
		ppu_line <= 0;
	elsif rising_edge(hsync) then

		if ppu_line < 144 and ppu_line >= 0 then 
			ppu_line <= ppu_line + 1;
		else
			ppu_line <= 0;
		end if;
	end if;
end process;


pline2: process(ppu_line) 
variable vl : unsigned(7 downto 0);
begin

	if ppu_line < 144 then 
		vl := to_unsigned(ppu_line rem 256,8);
		ppu_vline <= std_logic_vector(vl);
	else 
		ppu_vline <= "00000000";
	end if;
end process;

main : process
begin
  test_runner_setup(runner, runner_cfg);
  
   if run("donothing") then
  
    hstart <= '1';

    wait for 20 ns;

    hstart <= '0';

    wait for 1 ms;

   end if;

  test_runner_cleanup(runner); -- Simulation ends here
end process;

reset <= '0';
hsync <= hb;
fb_data <= fb_read(1 downto 0);

write_framebuffer <= (not wants_read) and output_enable;
fb_coord <= vga_coord when wants_read = '1' else ppu_coord;

hstart <= '0' when hb = '1' else '1';

--vga: vgacore port map (reset=>reset,clk_in=> pixel_clock,hsyncb => Hsync,vsyncb => Vsync,rgb => vga_rgb);
 fb : gb_writeable_framebuffer port map (
	clk=>pixel_clock,
	fb_coord => fb_coord,
	fb_read=>fb_read,
	fb_write=>fb_write,
	write=>write_framebuffer
);

rsprites : gb_tetrissprites_rom port map (pixel_clock,sprite_addr,sprite_data);
rtiles : gb_tetrismap_rom port map (pixel_clock,tile_addr,map_data);

fb_write(7 downto 2) <= "000000";
fb_write(1 downto 0) <= pix_out;

sprite_addr(11 downto 0) <= rom_addr(11 downto 0);
tile_addr(11 downto 0) <= rom_addr(11 downto 0) ;
sprite_addr(15 downto 12) <= "0000";
tile_addr(15 downto 12) <= "0000";

rom_data <= map_data when load_sprite = '0' else sprite_data;


ppu: gb_ppu 
generic map (MapAdress => 0,TileAdress => 4096 )
port map (
	pixel_clk=>pixel_clock,
	hstart=> '1',--hstart,
	rom_addr=>rom_addr,
	rom_data => rom_data,
	vertline => ppu_vline,
	output_enable => output_enable,
	rom_load=>rom_load,
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
 
 
--div2: clk_divider generic map (N => 3) port map (clk=> clk_source,  reset=>reset,clk_out=> pixel_clock);
end Behavioral;
