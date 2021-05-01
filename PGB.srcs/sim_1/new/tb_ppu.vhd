----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.03.2021 20:57:02
-- Design Name: 
-- Module Name: tb_ppu - Behavioral
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

library work;
use work.gb_package.all;
use IEEE.NUMERIC_STD.ALL;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_ppu is
generic (runner_cfg : string);
end tb_ppu;

architecture Behavioral of tb_ppu is


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

signal pixel_clock,ram_clock,hstart,rom_load,output_enable : std_logic;
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

--cramlock: process
--begin
--wait for 0.1 ns;
--ram_clock <= '1';
--wait for 10 ns;
--ram_clock <= '0';
--wait for 9.9 ns;
--end process;

ram_clock <= pixel_clock;
rsprites : gb_tetrissprites_rom port map (ram_clock,sprite_addr,sprite_data);
rtiles : gb_tetrismap_rom port map (ram_clock,tile_addr,map_data);

ppu: gb_ppu 
generic map (MapAdress => 0,TileAdress => 4096 )
port map (
pixel_clk=>pixel_clock,
hstart=> hstart,
rom_addr=>rom_addr,
rom_data => rom_data,vertline => "00001101",
output_enable => output_enable,rom_load=>rom_load,
load_sprite => load_sprite,
 pix_out => pix_out, -- palletized pixel 2bit
   pix_out_coord=>pix_out_coord       -- pixel out coordinate           
);

sprite_addr(11 downto 0) <= rom_addr(11 downto 0);
tile_addr(11 downto 0) <= rom_addr(11 downto 0) ;
sprite_addr(15 downto 12) <= "0000";
tile_addr(15 downto 12) <= "0000";

rom_data <= map_data when load_sprite = '0' else sprite_data;

main : process
begin
  test_runner_setup(runner, runner_cfg);
  
   if run("donothing") then
  
    hstart <= '1';
    wait for 20 ns;

    hstart <= '0';

    wait for 0.1 ms;

   end if;

 test_runner_cleanup(runner); -- Simulation ends here
  end process;


end Behavioral;
