----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.03.2021 19:33:04
-- Design Name: 
-- Module Name: gb_ppu - Behavioral
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
use ieee.numeric_std.all;      



entity gb_ppu is
  generic ( MapAdress : integer := 0; TileAdress : integer := 1024) ;
  Port ( pixel_clk,hstart: in std_logic; -- input clocks
         rom_data, vertline: in std_logic_vector(7 downto 0); -- ROM data input 
          
          rom_addr : out std_logic_vector(15 downto 0); -- ram address
          output_enable,rom_load, line_ended,load_sprite: out std_logic; -- requests ram data
          pix_out: out std_logic_vector(1 downto 0); -- palletized pixel 2bit
          pix_out_coord: out gb_px_coord  -- pixel out coordinate                       
         );
end gb_ppu;

architecture Behavioral of gb_ppu is

type STATES is (
Idle, -- nothing is happening
--LineStart, -- line starting
LineEnd, -- line has finished
Preload, -- ready the tileid load
IDload, -- loading tile ID
IDpost,
TileLoad1, -- loading sprite A
TileLoad2, -- loading sprite B
PixelPush, -- calculating final pixels
PixelWait -- waiting until pixel queue is free


);

type ppu_state is record
    pxA,pxB,tile   : std_logic_vector(7 downto 0);    
    
    --wants_load : std_logic;
    pixels, new_pixels :  gb_pixel_line;
    load_addr : std_logic_vector(15 downto 0);  

    pixel_index   : integer range 0 to 8; -- index for the pixel line
    current_x, push_x : unsigned(7 downto 0);
    state : STATES;
end record ppu_state;  


signal r,rin : ppu_state;

function calc_load_tile (
    idx : in integer   
    )
    return std_logic_vector is 
    variable tmp : integer range 0 to 4096;

 begin

    tmp := MapAdress + idx;

    return std_logic_vector(to_unsigned(tmp,16)); 
end calc_load_tile;



function calc_load_sprite (
    idx, line, num : in integer
    )
     return std_logic_vector is 
     variable tmp : integer range 0 to 65535;
    variable vec : std_logic_vector(15 downto 0);
begin

    --first bit is pair
    if(num = 1) then 
        vec(0) := '1';
    else
        vec(0) := '0';
    end if;
    --next 3 bits are sprite row    
    vec(3 downto 1) := std_logic_vector(to_unsigned(line,3));
    --rest is tile index
    vec(11 downto 4) := std_logic_vector(to_unsigned(idx,8));
    vec(15 downto 12) := "0000";
    tmp :=to_integer(unsigned(vec)) + TileAdress;
    return std_logic_vector(to_unsigned(tmp, vec'length));--vec;
end calc_load_sprite;

function tile_index (
    cx,cy : in integer -- pixel coordinates
    )
    return integer is 
    variable idx : std_logic_vector(11 downto 0);
    variable ux,uy : unsigned(7 downto 0);

    variable ux2,uy2 : unsigned(7 downto 0);

     variable ix,iy : integer;
    variable ulx,uly : std_logic_vector(7 downto 0);
 begin
    ux := to_unsigned(cx,8);
    uy := to_unsigned(cy,8);

    ux2(4 downto 0) := ux(7 downto 3);
    uy2(4 downto 0) := uy(7 downto 3);

    ulx := std_logic_vector(ux2);
    uly := std_logic_vector(uy2);   

    idx(4 downto 0) := ulx(4 downto 0);
    idx(9 downto 5) := uly(4 downto 0);

    
    return to_integer(unsigned(idx));
end tile_index;

function tile_index_uvec (
    cx,cy : in unsigned(7 downto 0) -- pixel coordinates
    )
    return integer is 
    variable TMPx,TMPy : unsigned(7 downto 0);
    begin
        TMPx := unsigned(cx) ;
        TMPy := unsigned(cy);

    return tile_index(to_integer(TMPx),to_integer(TMPy));    

end tile_index_uvec;

function tile_index_vector (
    cx,cy : in std_logic_vector(7 downto 0) -- pixel coordinates
    )
    return std_logic_vector is 
    variable TMPx,TMPy : std_logic_vector(7 downto 0);
    begin
        TMPx(3 downto 0) := cx(6 downto 3);--unsigned(cx) ;
        TMPx(7 downto 4) := cy(6 downto 3);

    return TMPx;    

end tile_index_vector;

begin


sync: process(pixel_clk) begin
    if rising_edge(pixel_clk) then 
        r <= rin;
    end if;
end process;

comb: process(hstart,rom_data, vertline,r)
variable st:  ppu_state;
variable tilex,tiley: integer;
variable wants_load: std_logic;
variable vline : unsigned(7 downto 0);
variable sprite_load_addr,tile_load_addr : std_logic_vector(15 downto 0);
begin
    st := r;    

    vline := unsigned(vertline);
    sprite_load_addr := calc_load_sprite(to_integer(unsigned(r.tile)),to_integer(vline),0);
    tile_load_addr := calc_load_tile(tile_index_uvec(r.current_x,vline));

    case (r.state) is
    when Idle => if hstart = '1' then
        st.state := Preload; -- begin execution        
        st.current_x := "00000000"; -- zero the x coord
        st.pixel_index := 8; -- zero the pixel index
        st.push_x := to_unsigned(0, r.push_x'length);
    end if;
    
    when Preload =>
        st.state := IDload;
        
    when IDload => -- calculate tile index for load
     
        st.state := IDpost;

    when IDpost =>   
        
        st.tile := rom_data;     
        st.state := TileLoad1;
    when TileLoad1 => 
             
        st.state := TileLoad2;
    when TileLoad2 => 
         
        st.pxA := rom_data;    
        st.state := PixelPush;        
    when PixelPush =>  
        st.pxB := rom_data;     
        
        st.state := PixelWait;
        
       -- st.push_x := r.current_x;
        for i in 0 to 7 loop            
            st.new_pixels(7-i).data(1) := r.pxB(i);
            st.new_pixels(7-i).data(0) := r.pxA(i);
        end loop;        

    when PixelWait =>

        -- queue is fully pushed once pixel index is 8
        if r.pixel_index = 8 then 
           st.pixels := r.new_pixels;
           st.pixel_index := 0;

            st.current_x := r.current_x + 8;

            if(unsigned(st.current_x) < to_unsigned(170,8)) then
                 st.state := Preload;
            else 
                 st.state := LineEnd;
            end if;
        else

        end if;
    when LineEnd => st.state := Idle;
    end case;   
    
    --calculate load location
    case r.state is
        when Preload =>     
             st.load_addr := tile_load_addr;
        when IDload =>     
            
        when IDpost =>         
            st.load_addr := sprite_load_addr;  
            
        when TileLoad1 => 
            st.load_addr := sprite_load_addr or "0000000000000001";         
           
        when others => rom_addr <= tile_load_addr;
    end case; 

    rom_addr <= r.load_addr; -- ram address
    case r.state is
        when Preload => rom_load <= '1'; 
        when IDload => rom_load <= '1'; 
        when TileLoad1 => rom_load <= '1';
        when TileLoad2 => rom_load <= '1';
        when Idle => rom_load <= '0';
        when others => rom_load <= '1';
    end case;

    case r.state is       
        when IDpost =>  load_sprite <= '0';
        when TileLoad1 =>  load_sprite <= '1';
        when TileLoad2 =>  load_sprite <= '1';
        when PixelPush => load_sprite <= '1';
        when others =>  load_sprite <= '0';
    end case;

    -- push pixels until pixel-index is 8
    if(r.pixel_index /= 8  and r.state /= Idle) then 

        st.pixel_index := r.pixel_index + 1;
        st.push_x := r.push_x +1;
        output_enable <= '1';
        pix_out(1)<= r.pixels(r.pixel_index).data(0);
        pix_out(0) <= r.pixels(r.pixel_index).data(1);
        pix_out_coord.x <= std_logic_vector(r.push_x);--td_logic_vector(r.push_x + r.pixel_index);
        pix_out_coord.y <= vertline;
    else
        output_enable <= '0';
        pix_out <= "00";            
        pix_out_coord.x <= "00000000";
        pix_out_coord.y <= "00000000";
    end if;

    case r.state is
        when LineEnd => 
            line_ended <= '1';
        when others => 
            line_ended <= '0';
    end case;

    --rom_load <= wants_load;
    -- requests ram data
    rin <= st;
end process;

end Behavioral;
