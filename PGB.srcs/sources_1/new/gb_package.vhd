----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.03.2021 19:39:11
-- Design Name: 
-- Module Name: gb_package - 
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

package gb_package is

 type gb_px_coord is record
    x  : std_logic_vector(7 downto 0);
    y : std_logic_vector(7 downto 0);
  end record gb_px_coord;  

 type gb_2px is record
    data : std_logic_vector(1 downto 0);
  end record gb_2px;  

type gb_pixel_line is array (7 downto 0) of gb_2px; -- 8 pixel line
end package gb_package;
