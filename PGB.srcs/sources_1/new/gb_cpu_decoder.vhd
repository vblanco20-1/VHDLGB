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
       -- inc/dec alus
       R_ALU_INC,
       R_ALU_DEC,
        
       PREFIX_CD,
       -- register based load
       R_LD,

       I_LD_LOAD, I_LD_EXEC
    );

    type dec_state is record 

        st : cpu_state;
        inst : instruction_state;
        next_i : instruction_state; -- next instruction. For multiclock
    end record dec_state;

    constant zero_state : dec_state := (      
        st => sFETCH,                       
        inst => NOOP,
        next_i => NOOP
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
    when "110" => return A; -- this is  for memory loads careful
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
    
    when R_ALU_INC => return o_ADD;
    when R_ALU_DEC => return o_SUB;
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
    when "00" =>
    case (dz) is 
        when "000" => return NOOP;
        when "001" => return NOOP;
        when "010" => return NOOP;
        when "011" => return NOOP;
        when "100" => return R_ALU_INC;
        when "101" => return R_ALU_DEC;
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

-- decode instructions to decide if the instruction does register writeback or not
function instruction_has_reg_write(state : in instruction_state) return boolean is
begin
    case (state) is 
    -- simple alus.
    when R_ALU_ADD|R_ALU_ADC|R_ALU_SUB|R_ALU_SBC|R_ALU_AND|R_ALU_OR|R_ALU_XOR =>    
        return true;
    -- inc/dec
    when R_ALU_INC|R_ALU_DEC =>    
        return true;
    -- loads
    when R_LD|I_LD_EXEC => 
        return true;
    when others => return false;
    end case;
end instruction_has_reg_write;

-- decode instructions to select the correct input for register write.
-- aludata is output from alu
-- regdata is output B from regbank
-- ramdata is last ram loaded word
function select_reg_data(state : in instruction_state; regdata : in gb_word; aludata : in gb_doubleword; ramdata : in gb_word) return gb_word is
begin
    case (state) is 
    -- simple alus.
    when R_ALU_ADD|R_ALU_ADC|R_ALU_SUB|R_ALU_SBC|R_ALU_AND|R_ALU_OR|R_ALU_XOR =>    
        return aludata(7 downto 0);
    -- inc/dec.
    when R_ALU_INC|R_ALU_DEC =>    
    return aludata(7 downto 0);
    -- loads
    when R_LD => 
        return regdata;
    -- loads RAM
    when I_LD_EXEC => 
        return ramdata;
    when others => return x"00";
    end case;
end select_reg_data;


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
    -- simple alus. They allways use reg_A
    when R_ALU_ADD|R_ALU_ADC|R_ALU_SUB|R_ALU_SBC|R_ALU_AND|R_ALU_OR|R_ALU_XOR =>
    
    ret.reg_A := A; 
    ret.reg_B := decode_registers_basic(dz);

    -- inc-dec, allways 1 as B, so use default-A
    when R_ALU_INC|R_ALU_DEC =>    
    ret.reg_A := decode_registers_basic(dy); 
    ret.reg_B := A;
    -- R2R LD, takes from y and z
    when R_LD => 
    ret.reg_A := decode_registers_basic(dy); 
    ret.reg_B := decode_registers_basic(dz);

    when others => ret.write_enable := '0'; -- just default to OR when nothing happens
    end case;

    return ret;
end read_registers;

-- decide the next instruction. For multiclocks.
-- non multiclock instructions have to return noop
function next_instr(inst : in instruction_state) return instruction_state is 
begin
    case (inst) is 
    when I_LD_LOAD => return I_LD_EXEC;
    when others => return NOOP;
    end case;
end next_instr;

-- decide the next adress for the RAM
function calculate_next_addr(inst : in instruction_state; din : in decoder_in ) return gb_doubleword is 
begin
    return  std_logic_vector(unsigned(din.reg.PC) + to_unsigned(1,16));
end calculate_next_addr;

-- decide if the instruction state writes to Ram
function writes_to_ram(inst : instruction_state) return boolean is 
begin
    return false;
end writes_to_ram;

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
    if(r.st = sFETCH) then 
        -- if next is noop, its not a multiclock instruction
        if(r.next_i = NOOP) then 
            v.inst := decode_instruction_state(i.ram.data);
        else 
            v.inst := r.next_i;
        end if;
    end if;
    

    -- read registers
    ov.reg := read_registers(v,i.ram.data);

    -- we write at the write substate if the instruction has writeback
    if((r.st = sWrite) and instruction_has_reg_write(v.inst)) then 
        ov.reg.write_enable := '1';
    else
        ov.reg.write_enable := '0';
    end if;
   
    ov.reg.data := select_reg_data(v.inst, i.reg.data_A,i.alu.op_R,  i.ram.data);
    -- advance the PC at the last substate
    if(r.st = sWAIT) then 
        ov.reg.PCIn := std_logic_vector(unsigned(i.reg.PC) + to_unsigned(1,16));
    else 
        ov.reg.PCIn := i.reg.PC;
    end if;
    ov.reg.flags := i.alu.flags; 

     -- alu outputs
    ov.alu.mode := instruction_to_alu(v.inst);
    ov.alu.double := '0';
    ov.alu.flags := i.reg.flags;
    ov.alu.op_A(7 downto 0) := i.reg.data_A;

    if(v.inst = R_ALU_INC or v.inst = R_ALU_DEC)   then 
        ov.alu.op_B(7 downto 0) := "00000001";
    else
        ov.alu.op_B(7 downto 0) := i.reg.data_B;
    end if;
    

    -- ram outputs
    ov.ram.addr := calculate_next_addr(v.inst,i);
    if(writes_to_ram(v.inst)) then 
        ov.ram.we  := '1';
    else
        ov.ram.we  := '0';
    end if;
     
    ov.ram.data := x"00";

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
