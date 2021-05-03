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

function get_register ( regs : in reg_state; name : in reg_name  ) return gb_doubleword is   
variable res : gb_doubleword;
begin      
   res := x"0000";
case(name) is
    when A => res(7 downto 0) := regs.A;
    when F => res(7 downto 0) := regs.F;
    when B => res(7 downto 0) := regs.B;
    when C => res(7 downto 0) := regs.C;
    when D => res(7 downto 0) := regs.D;
    when E => res(7 downto 0) := regs.E;
    when H => res(7 downto 0) := regs.H;
    when L => res(7 downto 0) := regs.L;
    when AF => res(15 downto 8) := regs.A; res(7 downto 0) := regs.F;
    when BC => res(15 downto 8) := regs.B; res(7 downto 0) := regs.C;
    when DE => res(15 downto 8) := regs.D; res(7 downto 0) := regs.E;
    when HL => res(15 downto 8) := regs.H; res(7 downto 0) := regs.L;
    when others  => res := regs.SP; -- SP is the missing one
end case;

return res;
end get_register;

function set_register ( regs : in reg_state; name : in reg_name; data : in gb_doubleword) return reg_state is   
variable res : reg_state;
begin      
   res := regs;
case(name) is
    when A => res.A :=  data(7 downto 0);
    when F => res.F :=  data(7 downto 0);
    when B => res.B :=  data(7 downto 0);
    when C => res.C :=  data(7 downto 0);
    when D => res.D :=  data(7 downto 0);
    when E => res.E :=  data(7 downto 0);
    when H => res.H :=  data(7 downto 0);
    when L => res.L :=  data(7 downto 0);
    when AF => res.A := data(15 downto 8 ); res.F := data(7 downto 0);
    when BC => res.B := data(15 downto 8 ); res.C := data(7 downto 0);
    when DE => res.D := data(15 downto 8 ); res.E := data(7 downto 0);
    when HL => res.H := data(15 downto 8 ); res.L := data(7 downto 0);
    when others  => res.SP := data; -- SP is the missing one
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
