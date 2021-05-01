----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.03.2021 17:07:09
-- Design Name: 
-- Module Name: gb_writeable_framebuffer - Behavioral
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

entity gb_writeable_framebuffer_mock is
  Port (
    fb_write: in std_logic_vector(7 downto 0);
    fb_read: out std_logic_vector(7 downto 0);
	fb_coord_write,fb_coord_read: in gb_px_coord;   
    clk, write: in std_logic);

end gb_writeable_framebuffer_mock;

architecture Behavioral of gb_writeable_framebuffer_mock is


signal output  : std_logic_vector(7 downto 0);


begin

sync : process (clk,output)
begin
    if rising_edge(clk) then
		
        fb_read <= output;        
	end if;
end process;

comb : process (fb_coord_read)
variable val1,val2,val3  : unsigned(7 downto 0);
begin
    val1 := unsigned(fb_coord_read.y);
    val2 := unsigned(fb_coord_read.x);
    val3 := (val2 + val1) rem 4;

    output <= std_logic_vector(val3);
end process;

end Behavioral;
