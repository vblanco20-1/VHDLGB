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

entity tb_vga is
generic (runner_cfg : string);
end tb_vga;

architecture Behavioral of tb_vga is

component vgacore is
	port
	(
		reset: in std_logic;	
		clk_in: in std_logic;
		hsyncb: out std_logic;	
		vsyncb: out std_logic;	
		rgb: out std_logic_vector(11 downto 0) 
	);
	
end component;

signal pixel_clock,resett,HSync,VSync: std_logic;
signal vga_rgb : std_logic_vector(11 downto 0);
begin






vga: vgacore port map (reset=>resett,clk_in=> pixel_clock,hsyncb => Hsync,vsyncb => Vsync,rgb => vga_rgb);


main : process
begin
  test_runner_setup(runner, runner_cfg);
  report "Hello world!";
	Hsync <= '0';
	resett <= '1';
	wait for 150 ns;
	resett <= '0';
	wait for 150 ns;
	resett <= '1';
wait for 150 ns;
	resett <= '0';
 if run("donothing") then

   wait for 17 ms;
   end if;

 test_runner_cleanup(runner); -- Simulation ends here
  end process;


end Behavioral;
