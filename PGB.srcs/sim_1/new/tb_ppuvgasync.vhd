----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.03.2021 20:05:38
-- Design Name: 
-- Module Name: tb_vga - Behavioral
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

library vunit_lib;
context vunit_lib.vunit_context;

library work;
use work.gb_package.all;

entity tb_ppuvgasync is
generic (runner_cfg : string);
end tb_ppuvgasync;

architecture Behavioral of tb_ppuvgasync is

component gb_ppu_vgasync is
  Port (
    pixel_clk,hsync,vsync, render_done: in std_logic;
    ppu_start: out std_logic;
    ppu_vertline: out std_logic_vector(7 downto 0)
	);
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



signal hsync,vsync,pixel_clk , render_done, ppu_start: std_logic;
signal ppu_vertline,rom_data: std_logic_vector(7 downto 0);
begin



hsync_p: process
begin 
	hsync <= '1';
	wait for 10 ns;
	hsync <= '0';
	wait for 10 * 200 ns;
end process;

vsync_p: process
begin 
	vsync <= '1';
	wait for 10 ns;
	vsync <= '0';
	wait for 10 * 200 * 160 ns;
end process;

clock_p: process
begin 
	pixel_clk <= '1';
	wait for 5 ns;
	pixel_clk <= '0';
	wait for 5 ns;
end process;

rom_data<= "00000000";
sync: gb_ppu_vgasync port map(pixel_clk => pixel_clk,hsync=>hsync, vsync=>vsync,render_done=>render_done,ppu_start=>ppu_start,ppu_vertline=>ppu_vertline );
--vga: vgacore port map (reset=>resett,clk_in=> pixel_clock,hsyncb => Hsync,vsyncb => Vsync,rgb => vga_rgb);

ppu: gb_ppu 
generic map (MapAdress => 0,TileAdress => 4096 )
port map (
	pixel_clk=>pixel_clk,--pixel_clock,
	hstart=> ppu_start,
	--rom_addr=>rom_addr,
	rom_data => rom_data,
	vertline => ppu_vertline,
	line_ended => render_done--,
	--rom_load=>rom_load,
	--load_sprite => load_sprite,
	--pix_out => pix_out, -- palletized pixel 2bit
	--pix_out_coord=>ppu_coord       -- pixel out coordinate           
);


main : process
begin
  test_runner_setup(runner, runner_cfg);
  report "Hello world!";

 if run("donothing") then

   wait for 10 * 200 * 160 * 2 ns;
   end if;

 test_runner_cleanup(runner); -- Simulation ends here
  end process;


end Behavioral;
