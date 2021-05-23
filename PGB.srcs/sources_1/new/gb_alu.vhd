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



entity gb_alu is
 
  Port ( i : in alu_in; -- input clocks
         o : out alu_out
         );
end gb_alu;

architecture Behavioral of gb_alu is

begin

comb: process(i)
variable v:  alu_out;

variable Au,Bu : unsigned(7 downto 0);
variable Aub,Bub,carry : unsigned(8 downto 0);
variable FullAccum : unsigned(8 downto 0);
variable HalfAccum : unsigned(4 downto 0);
variable sFullAccum : signed(8 downto 0);
variable sHalfAccum : signed(4 downto 0);
variable result : gb_word;

--variable wants_load: std_logic;
--variable sprite_load_addr,tile_load_addr : std_logic_vector(15 downto 0);

function btol (b : in boolean ) return std_logic is   
begin      
    if b then return '1'; else return '0'; end if;
end btol;

begin

v := zero_alu_out;
result := x"00";
Au := unsigned(i.op_A(7 downto 0));
Bu := unsigned(i.op_B(7 downto 0));


Aub(8) := '0';
Bub(8) := '0';
Aub(7 downto 0) := Au;
Bub(7 downto 0) := Bu; 

carry := to_unsigned(0,9);
if ((i.with_carry) = '1') then 
    carry(0) := '1';
end if;

case(i.mode) is
when o_ADD => 
            
    FullAccum := Aub + Bub + carry;

    HalfAccum := ('0' & Aub(3 downto 0)) + ('0' & Bub(3 downto 0)) + carry(4 downto 0);

    v.flags.full_carry := FullAccum(8);
    v.flags.half_carry := HalfAccum(4);  

    result :=  std_logic_vector(FullAccum(7 downto 0));
    
when o_SUB =>
    FullAccum := Aub - (Bub + carry);
    HalfAccum := ('0' & Aub(3 downto 0)) - ('0' & Bub(3 downto 0)) - carry(4 downto 0);
  
    v.flags.full_carry := not FullAccum(8);
    v.flags.half_carry :=  HalfAccum(4); 

    v.flags.subtract := '1';
    --result := std_logic_vector(sFullAccum(7 downto 0));
    result := std_logic_vector(FullAccum(7 downto 0));
when o_AND => 
    FullAccum(7 downto 0) := Au and Bu;   

    v.flags.half_carry := '1'; -- for some reason AND wants halfcarry at 1

    result := std_logic_vector(FullAccum(7 downto 0));
when o_OR => 
    FullAccum(7 downto 0) := Au or Bu;

    result := std_logic_vector(FullAccum(7 downto 0));
when o_XOR => 
    FullAccum(7 downto 0) := Au xor Bu;   

    result := std_logic_vector(FullAccum(7 downto 0));
end case;

if result = x"00" then 
        v.flags.zero := '1';
else
        v.flags.zero := '0';
end if;

v.op_R(15 downto 8) := x"00";
v.op_R(7 downto 0) := result;


o <= v;

end process;

end Behavioral;
