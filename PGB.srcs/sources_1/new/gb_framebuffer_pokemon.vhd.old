----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.03.2021 21:37:26
-- Design Name: 
-- Module Name: gb_framebuffer - Behavioral
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


entity gb_framebuffer is
  Port (
        clk : in std_logic;
        cx,cy : in std_logic_vector(7 downto 0);
        color : out std_logic_vector(7 downto 0) );
end gb_framebuffer;

architecture Behavioral of gb_framebuffer is

constant GB_Y : integer := 160;

component gb_buffered_rom is
Port(clk : in std_logic; 
        idx : in std_logic_vector(15 downto 0);			
			data: out std_logic_vector(7 downto 0));
end component; 

signal index :  std_logic_vector(15 downto 0);
begin
process (cy,cx)
variable Idx, in1  : unsigned(15 downto 0);
variable IX,IY,wdth  : unsigned(7 downto 0);
begin
    IX := unsigned(cx);
    IY := unsigned(cy);
    wdth := to_unsigned(GB_Y,8);
    in1 := (IY * wdth);
    Idx :=  in1 + IX;

    if(Idx > 23039 ) then
        Idx := to_unsigned(0,16);   
    end if;

    index <= std_logic_vector(Idx);
    --color <= ram_block(to_integer(Idx));
end process;

rom: gb_buffered_rom port map (clk => clk,idx => index ,data => color);

end Behavioral;
