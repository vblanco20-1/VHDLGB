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



entity gb_reg is
 
  Port ( clk,reset : in std_logic;
         i : in reg_in; -- input clocks
         o : out reg_out
         );
end gb_reg;



architecture Behavioral of gb_reg is

    type reg_state is record 

        A, F, B, C, D, E, H, L : gb_word;
        PC, SP: gb_doubleword;
        
    end record reg_state;

    signal r,rin : reg_state;

    constant zero_registers : reg_state := (      
        A => x"00",  
        F => x"00",  
        B => x"00",  
        C => x"00",  
        D => x"00",  
        E => x"00",    
        H => x"00",                    
        L => x"00", 
        PC => x"0000", 
        SP => x"0000"
      );

function get_register ( regs : in reg_state; name : in reg_name  ) return gb_word is   
variable res : gb_word;
begin      
   res := x"00";
case(name) is
    when A => res := regs.A;
    when F => res := regs.F;
    when B => res := regs.B;
    when C => res := regs.C;
    when D => res := regs.D;
    when E => res := regs.E;
    when H => res := regs.H;
    when L => res := regs.L;
    when SP =>res := regs.SP(7 downto 0);
    when One => res := x"01";
    when others  =>  res := x"00";-- Zero is the missing one
end case;

return res;
end get_register;

function set_register ( regs : in reg_state; name : in reg_name; data : in gb_word) return reg_state is   
variable res : reg_state;
begin      
   res := regs;
case(name) is
    when A => res.A :=  data;
    when F => res.F :=  data;
    when B => res.B :=  data;
    when C => res.C :=  data;
    when D => res.D :=  data;
    when E => res.E :=  data;
    when H => res.H :=  data;
    when L => res.L :=  data;    
    when SP => res.SP := data;
    when others  => res.A := regs.A; -- dummy. never happens
end case;

return res;
end set_register;

function pack_flag_reg (f : in alu_flags ) return gb_word is   
variable res : gb_word;
begin 
    
    res(7) := f.zero;
    res(6) := f.subtract;
    res(5) := f.half_carry;
    res(4) := f.full_carry;
    res(3 downto 0) := "0000";

return res;
end pack_flag_reg;

function unpack_flag_reg (f : in gb_word ) return alu_flags is   
variable res : alu_flags;
begin 
    
    res.zero := f(7);
    res.subtract := f(6);
    res.half_carry := f(5);
    res.full_carry := f(4);

return res;
end unpack_flag_reg;

begin

    
sync: process(i,clk,rin)
begin
    if rising_edge(clk) then 
        r <= rin;
    end if;
end process;

comb: process(i,reset,r)
variable v : reg_state;
variable ov : reg_out;
begin



if reset = '1' then 
    v := zero_registers;
    ov := zero_reg_out;
else 
    v := r;
    ov := zero_reg_out;

    if(i.write_enable = '1') then 
        v := set_register(r,i.reg_A,i.data);
    end if;

    -- we allways update the flag register on the clock unless its being overwritten manually
    
    --if( not (i.write_enable = '1' and (i.reg_A = F) )) then
        v.F := pack_flag_reg(i.flags);
    --end if;

    -- PC updates every clock
    v.PC := i.PCin;

    ov.data_A := get_register(r,i.reg_A);
    ov.data_B := get_register(r,i.reg_B);

    ov.flags := unpack_flag_reg(r.F);
    ov.PC := r.PC;
end if;


rin <= v;
o <= ov;
end process;

end Behavioral;
