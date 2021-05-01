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

entity gb_writeable_framebuffer is
  Port (
    fb_write: in std_logic_vector(7 downto 0);
    fb_read: out std_logic_vector(7 downto 0);
	fb_coord_write,fb_coord_read: in gb_px_coord;   
    clk, write: in std_logic);

end gb_writeable_framebuffer;

architecture Behavioral of gb_writeable_framebuffer is


constant LINE_WIDTH : integer := 256;	
constant HEIGHT : integer := 144;	

constant DATA_WIDTH : integer := 8;	
constant RAM_SIZE : integer := LINE_WIDTH * HEIGHT;

TYPE mem_type IS ARRAY(0 TO RAM_SIZE-1) OF std_logic_vector((DATA_WIDTH-1) DOWNTO 0); 

signal mem_idx_read,mem_idx_write  : integer;

signal ram_block : mem_type;
attribute ram_style  : string;
attribute ram_style of ram_block : signal is "block";
begin

sync : process (clk,write,fb_write,mem_idx_read,mem_idx_write)
begin
    if rising_edge(clk) then
		if write = '1' then
        ram_block(mem_idx_write) <= fb_write;
        end if;

        fb_read <= ram_block(mem_idx_read);        
	end if;
end process;

comb : process (fb_coord_read,fb_coord_write)
variable intidread,intidwrite  : unsigned(15 downto 0);
begin
    intidread(15 downto 8) := unsigned(fb_coord_read.y);
    intidread(7 downto 0) := unsigned(fb_coord_read.x);

    mem_idx_read <= to_integer(intidread);

    intidwrite(15 downto 8) := unsigned(fb_coord_write.y);
    intidwrite(7 downto 0) := unsigned(fb_coord_write.x);   

    mem_idx_write <= to_integer(intidwrite);
end process;

end Behavioral;
