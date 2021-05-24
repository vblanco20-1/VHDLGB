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

entity gb_ppu_vgasync is
  Port (
    pixel_clk,hsync,vsync, render_done: in std_logic;
    ppu_start, frame_ended: out std_logic;
    ppu_vertline: out std_logic_vector(7 downto 0)
	);

end gb_ppu_vgasync;

architecture Behavioral of gb_ppu_vgasync is

type STATES is (
Idle, -- nothing is happening
LineStart, -- preload line
LineRender, -- render line
LineEnd, --post render
FrameEnd-- frame finished
);

type sync_state is record
    hcnt, vcnt: integer;    
    state : STATES;
end record sync_state;  

signal r, rin: sync_state;
begin

sync : process (pixel_clk)
begin
    if rising_edge(pixel_clk) then		
        r <= rin;
	end if;
end process;

comb : process (r,hsync,vsync, render_done)
variable sc  : sync_state;
variable fe : std_logic;
variable val1,val2,val3  : unsigned(7 downto 0);
begin

    fe := '0';
sc := r;
case r.state is

when Idle => -- idle state waits for vsync to get triggered
    if vsync = '1' then
        sc.state := LineStart;
        sc.hcnt := 0;
        sc.vcnt := 0;        
    end if;
    
when LineStart => -- line start counts 8 cycles to let ppu begin
    sc.hcnt := sc.hcnt+1;
    if(r.hcnt >= 8) then 
        sc.state := LineRender; 
    end if;
when LineRender => -- line render counts until ppu signaled finish
    sc.hcnt := r.hcnt+1;
    if(render_done = '1') then 
        sc.state := LineEnd; 
    end if;
when LineEnd => -- wait until hsync, restart to idle if end of frame
     --if(hsync = '1') then         
        sc.vcnt := r.vcnt + 1;
        if(r.vcnt >= 144) then 
            sc.state := FrameEnd;
           
        else
            sc.state := LineStart;
        end if;
    --end if;
when FrameEnd => -- loop the vcount back to zero to give time for the cpu interrupt
    fe := '1';
    sc.vcnt := r.vcnt - 1;
    if(r.vcnt = 0) then 
        sc.state := Idle;
    end if;
end case;

rin <= sc;
frame_ended <= fe;
ppu_vertline <= std_logic_vector(to_unsigned(r.vcnt mod 255, ppu_vertline'length));

case r.state is
    when LineStart => ppu_start <= '1';
    when others => ppu_start <= '0';
end case;

end process;

end Behavioral;
