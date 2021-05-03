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



entity gb_decoder is
 
  Port ( clk,reset : in std_logic;
         i : in decoder_in; 
         o : out decoder_out
         );
end gb_decoder;



architecture Behavioral of gb_decoder is

    type cpu_state is (
        sFETCH, 
        sEXEC, 
        sWRITE,
        sWAIT
    );

    -- R for pure-registers singlestate ops.
    -- I for inmediate ops 
    type instruction_state is (
       NOOP,

       -- simple register alus. Always stores on A
       R_ALU_ADD,
       R_ALU_ADC,
       R_ALU_SUB,
       R_ALU_SBC,
       R_ALU_AND,
       R_ALU_OR,
       R_ALU_XOR,
        
       PREFIX_CD,
       -- register based load
       R_LD,

       I_LD_LOAD, I_LD_EXEC
    );

    type dec_state is record 

        st : cpu_state;
        inst : instruction_state;
    end record dec_state;

    constant zero_state : dec_state := (      
        st => sFETCH,                       
        inst => NOOP
      );

    signal r,rin : dec_state;


    
function next_cpu_state (s : in cpu_state ) return cpu_state is   
begin     
 case (s) is 
    when sFETCH => return sEXEC;
    when sEXEC => return sWRITE;
    when sWRITE => return sWAIT;
    when sWAIT => return sFETCH;
 end case;
end next_cpu_state;

function decode_registers_basic(index: in std_logic_vector(2 downto 0)) return reg_name is
begin
    case (index) is 
    when "000" => return B;
    when "001" => return C;
    when "010" => return D;
    when "011" => return E;
    when "100" => return H;
    when "101" => return L;
    when "110" => return HL; -- this is  for memory loads careful
    when others => return A; -- "111"
    end case;
end decode_registers_basic;

--calculate the correct alu operation according to a given instruction state
function instruction_to_alu(state : in instruction_state) return alu_operation is
begin
    case (state) is 
    when R_ALU_ADD => return o_ADD;
    when R_ALU_ADC => return o_ADD;
    when R_ALU_SUB => return o_SUB;
    when R_ALU_SBC => return o_SUB;
    when R_ALU_AND => return o_AND;
    when R_ALU_OR => return o_OR;
    when R_ALU_XOR => return o_XOR;
    when others => return o_OR; -- just default to OR when nothing happens
    end case;
end instruction_to_alu;

-- decode an instruction to find the first cpu state to go. 
function decode_instruction_state(data : in gb_word) return instruction_state is
variable prefix : std_logic_vector(1 downto 0);
variable dy, dz: std_logic_vector(2 downto 0 );
begin
    prefix := data(7 downto 6);
    dy := data(5 downto 3);
    dz := data(2 downto 0);

    case (prefix) is 
    when "00" => return NOOP;
    case (dz) is 
        when "000" => return NOOP;
        when "001" => return NOOP;
        when "010" => return NOOP;
        when "011" => return NOOP;
        when "100" => return NOOP;
        when "101" => return NOOP;
        when "110" => return I_LD_LOAD; -- inmediate load
        when others => return NOOP;    
    end case;

    when "01" => return R_LD; -- prefix 01 is allways reg loads
    when "10" => 
   
    case (dy) is -- alu operations
        when "000" => return R_ALU_ADD;
        when "001" => return R_ALU_ADC;
        when "010" => return R_ALU_SUB;
        when "011" => return R_ALU_SBC;
        when "100" => return R_ALU_AND;
        when "101" => return R_ALU_XOR;
        when "110" => return R_ALU_OR;
        when others => return PREFIX_CD;    
    end case;

    when others => return NOOP;
    end case;
return NOOP;
end decode_instruction_state;

--calculate the correct register bank state
function read_registers(state : in dec_state ; data : in gb_word) return reg_in is
    variable inst : instruction_state;
    
variable dy, dz: std_logic_vector(2 downto 0 );
variable ret : reg_in;
begin
    ret := zero_reg_in;    
    dy := data(5 downto 3);
    dz := data(2 downto 0);

    case (state.inst) is 
    -- simple alus
    when R_ALU_ADD|R_ALU_ADC|R_ALU_SUB|R_ALU_SBC|R_ALU_AND|R_ALU_OR|R_ALU_XOR =>
    
    ret.reg_A := decode_registers_basic(dy);
    ret.reg_B := decode_registers_basic(dz);

    when others => ret.write_enable := '0'; -- just default to OR when nothing happens
    end case;
end read_registers;



begin    
sync: process(i,clk,rin)
begin
    if rising_edge(clk) then 
        r <= rin;
    end if;
end process;

comb: process(i,reset,r)
variable v : dec_state;
variable ov : decoder_out;
begin

    v := r;
    ov := zero_decoder_out;

if reset = '1' then 
    v := zero_state;
else 
    v.st := next_cpu_state(r.st);

    -- read instruction
    v.inst := decode_instruction_state(i.ram.data);

    -- read registers
    ov.reg := read_registers(v,i.ram.data);

    if(r.st = sWrite) then 
        ov.reg.write_enable := '1';
    else
        ov.reg.write_enable := '0';
    end if;
   
    ov.reg.data := i.alu.op_R;
    ov.reg.PCIn := i.reg.PC;
    ov.reg.flags := i.alu.flags; 

    ov.alu.mode := instruction_to_alu(v.inst);
    ov.alu.double := '0';
    ov.alu.flags := i.reg.flags;
    ov.alu.op_A := i.reg.data_A;
    ov.alu.op_B := i.reg.data_B;

    if(v.inst = R_ALU_ADC or v.inst = R_ALU_ADC) then
        ov.alu.with_carry := '1';
    else
        ov.alu.with_carry := '0';
    end if;
end if;

rin <= v;
o <= ov;
end process;

end Behavioral;
