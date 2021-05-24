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
use work.gb_cu_pkg.all;
use ieee.numeric_std.all;      



entity gb_decoder is
 
  Port ( clk,reset : in std_logic;
         i : in decoder_in; 
         o : out decoder_out
         );
end gb_decoder;



architecture Behavioral of gb_decoder is

    type dec_state is record    
        load_adress : gb_doubleword;    
        branch_adress : gb_doubleword;
        inmediate : gb_doubleword; -- inmediate value
        opcode : gb_word;
        st : cpu_state;
        inst : instruction_state;
        next_i : instruction_state; -- next instruction. For multiclock
        do_branch : std_logic; -- perform branching
        ramwrite : gb_word; -- temporal buffer for memory write
        flags : alu_flags; -- cached flags

        last_int, current_int : std_logic; -- interrupt detector
    end record dec_state;

    constant zero_state : dec_state := (    
        load_adress => x"0000",    
        branch_adress => x"0000",  
        inmediate => x"0000",  
        opcode => x"00", 
        ramwrite => x"00",
        st => sSTART,
        inst => NOOP,
        next_i => NOOP,
        do_branch => '0',
        current_int => '0',
        last_int => '0',
        flags=> zero_alu_flags
    );

    signal r,rin : dec_state;

-- decode an instruction to find the first cpu state to go. 
function decode_instruction_state(data : in gb_word) return instruction_state is
variable prefix : std_logic_vector(1 downto 0);
variable dy, dz: std_logic_vector(2 downto 0 );
begin

    prefix := data(7 downto 6);
    dy := data(5 downto 3);
    dz := data(2 downto 0);

    case (prefix) is 
    when "00" => -- 0
    case (dz) is 
        when "000" =>
        if(dy = "010") then 
            return R_STOP;
        else return NOOP; end if;

        when "001" => 
        if (dy(0) = '0') then
            return I_LD_WIDELOAD;
        else 
            -- ADD HL
            return NOOP;
        end if;
        when "010" => return NOOP;
        when "011" => return NOOP;
        when "100" => return R_ALU_SIMPLE;
        when "101" => return R_ALU_SIMPLE;
        when "110" => 
        if(dy = "110") then  -- (hl) register
            return I_LD_LOAD_MEM; -- load into m(hl)
        else 
            return I_LD_LOAD; -- inmediate load
        end if;
        when others => return NOOP;    
    end case;

    when "01" => -- 1
    if(data = x"76") then 
        return HALT;
    else
        if(dy = "110") then -- (HL), memory write
            return R_LD_MEM_STORE;
        elsif(dz ="110") then -- (HL), memory load
            return R_LD_MEM_LOAD;
        else
            return R_LD; -- prefix 01 is reg loads
        end if;
    end if;
    when "10" => -- 2
   
    case (dy) is -- alu operations
        when "000" => return R_ALU;
        when "001" => return R_ALU;
        when "010" => return R_ALU;
        when "011" => return R_ALU;
        when "100" => return R_ALU;
        when "101" => return R_ALU;
        when "110" => return R_ALU;
        when others => return PREFIX_CD;    
    end case;

    when others => -- 3
    case (dz) is 
        when "000" =>  return NOOP;   
        when "001" => return NOOP;
        when "010" => 
            case (dy) is 
                when "000" => return I_ABS_BRANCH;
                when "001" => return I_ABS_BRANCH;
                when "010" => return I_ABS_BRANCH;
                when "011" => return I_ABS_BRANCH;
                when "100" => return NOOP;
                when "101" => return I_MEM_STORE;
                when "110" => return NOOP;
                when others => return I_MEM_LOAD;    
            end case;

        when "011" => 
            case (dy) is 
                when "000" => return I_ABS_BRANCH;
                when "001" => return PREFIX_CD;
                when others => return NOOP;
            end case;
        when "110" => return I_ALU;

        when others => return NOOP;    
    end case;
    
    
    
    return NOOP;
    end case;
return NOOP;
end decode_instruction_state;



-- decode instructions to select the correct input for register write.
-- aludata is output from alu
-- regdata is output B from regbank
-- ramdata is last ram loaded word
function select_reg_data(state : in instruction_state; regdata : in reg_out; aludata : in gb_doubleword; ramdata : in gb_word) return gb_word is
begin
    case (state) is 
    -- simple alus.
    when R_ALU|R_ALU_SIMPLE|I_ALU_LOAD =>    
        return aludata(7 downto 0);    
    -- loads
    when R_LD => 
        return regdata.data_B;
    -- loads RAM
    when I_LD_EXEC => 
        return ramdata;
    when I_LD_LOAD_MEM|I_LD_EXEC_MEM => 
        return ramdata;
    when I_MEM_LOAD_EXEC|R_LD_MEM_LOAD_EXEC =>
        return ramdata;
    when I_LD_WIDELOAD_LD1|I_LD_WIDELOAD_LD2 =>
        return ramdata;
    when others => return x"00";
    end case;
end select_reg_data;


--calculate the correct register bank state
function read_registers(state : in dec_state ; data : in gb_word) return reg_in is
    variable inst : instruction_state;
    
variable dy, dz: std_logic_vector(2 downto 0 );
variable ret : reg_in;
variable widereg : widereg_name;
begin
    ret := zero_reg_in;    
    dy := data(5 downto 3);
    dz := data(2 downto 0);

    case data(5 downto 4) is
        when "00" => widereg:= BC;
        when "01" => widereg := DE;
        when "10" => widereg := HL;
        when others => widereg := SP;    
    end case;

    case (state.inst) is 
    -- simple alus. They allways use reg_A
    when R_ALU =>    
    ret.reg_A := A; 
    ret.reg_B := decode_registers_basic(dz);
    ret.reg_wide := WideZero;
    -- inc-dec, allways 1 as B, use it
    when R_ALU_SIMPLE =>    
    ret.reg_A := decode_registers_basic(dy); 
    ret.reg_B := One;
    ret.reg_wide := WideZero;
    -- R2R LD, takes from y and z
    when I_ALU_LOAD =>    
    ret.reg_A := A; 
    ret.reg_B := Zero;
    ret.reg_wide := WideZero;
    when R_LD => 
    ret.reg_A := decode_registers_basic(dy); 
    ret.reg_B := decode_registers_basic(dz);
    ret.reg_wide := WideZero;
    when I_LD_EXEC =>
    ret.reg_A := decode_registers_basic(dy); 
    ret.reg_B := Zero;
    ret.reg_wide := WideZero;
    when I_LD_LOAD_MEM =>
    ret.reg_A := Zero; 
    ret.reg_B := Zero;
    ret.reg_wide :=  HL;
    when I_LD_EXEC_MEM =>
    ret.reg_A := Zero; 
    ret.reg_B := Zero;
    ret.reg_wide :=  HL;
    when R_LD_MEM_STORE => 
    ret.reg_A := decode_registers_basic(dz); 
    ret.reg_B := Zero;
    ret.reg_wide := HL;
    when R_LD_MEM_LOAD_EXEC|R_LD_MEM_LOAD => 
    ret.reg_A := decode_registers_basic(dy); 
    ret.reg_B := Zero;
    ret.reg_wide := HL;
    when I_MEM_LOAD_EXEC|I_MEM_STORE_EXEC =>
    ret.reg_A := A;
    ret.reg_B := Zero;
    ret.reg_wide := WideZero;
    when I_MEM_STORE_LD2 =>
    ret.reg_A := A;
    ret.reg_B := Zero;
    ret.reg_wide := WideZero;
    when I_LD_WIDELOAD_LD1=>
    ret.reg_A := split_widereg(widereg, true);
    ret.reg_B := Zero;
    ret.reg_wide := WideZero;

    when I_LD_WIDELOAD_LD2=>
    ret.reg_A := split_widereg(widereg, false);
    ret.reg_B := Zero;
    ret.reg_wide := WideZero;

    when others => 
    ret.reg_B := Zero;
    ret.reg_B := Zero; -- just default to cero
    ret.reg_wide := WideZero;
    end case;

    return ret;
end read_registers;

-- decide the next instruction. For multiclocks. and branches
-- non multiclock instructions have to return noop
function next_instr(inst : in instruction_state; branch : in std_logic) return instruction_state is 
begin
    case (inst) is 
    when I_LD_LOAD => return I_LD_EXEC;
    when I_LD_LOAD_MEM => return I_LD_EXEC_MEM;
    when I_LD_EXEC_MEM => return R_LD_MEM_STORE_WRITE;
    when I_LD_WIDELOAD => return I_LD_WIDELOAD_LD1;
    when I_LD_WIDELOAD_LD1 => return I_LD_WIDELOAD_LD2;

    when R_LD_MEM_STORE => return R_LD_MEM_STORE_WRITE;
    when R_LD_MEM_LOAD => return R_LD_MEM_LOAD_EXEC;

    when I_MEM_LOAD => return I_MEM_LOAD_LD1;
    when I_MEM_LOAD_LD1 => return I_MEM_LOAD_LD2;
    when I_MEM_LOAD_LD2 => return I_MEM_LOAD_EXEC;

    when I_MEM_STORE => return I_MEM_STORE_LD1;
    when I_MEM_STORE_LD1 => return I_MEM_STORE_LD2;
    when I_MEM_STORE_LD2 => return I_MEM_STORE_EXEC;

    when I_ABS_BRANCH => return I_ABS_BRANCH_LD1;
    when I_ABS_BRANCH_LD1 => return I_ABS_BRANCH_LD2;
    when I_ABS_BRANCH_LD2 => --once branch address is loaded it decides if branching or not

        if( branch = '1') then  -- if we have to branch, go to the next state to load PC
            return I_ABS_BRANCH_JMP;
        else 
            return NOOP; -- if not branching we move to the next pc
        end if;
    when I_ALU => return I_ALU_LOAD;
    when others => return NOOP;
    end case;
end next_instr;

-- decide the next adress for the RAM
function calculate_next_addr(inst : in instruction_state; din : in decoder_in ) return gb_doubleword is 
begin
    if(inst = R_STOP) then        
        return din.reg.PC;    
    else
        return std_logic_vector(unsigned(din.reg.PC) + to_unsigned(1,16));
    end if;
end calculate_next_addr;

-- decide the next PC
function calculate_next_PC(inst : in instruction_state; din : in decoder_in; branch_target : in gb_doubleword ) return gb_doubleword is 
begin
    case (inst) is     
    when R_LD_MEM_STORE|R_LD_MEM_LOAD|I_LD_EXEC_MEM|I_MEM_STORE_LD2|I_MEM_LOAD_LD2 => return din.reg.PC; -- when doing mem writes we dont advance PC
    when I_ABS_BRANCH_JMP => return branch_target;
    when R_STOP => return x"0000";
    when others => return std_logic_vector(unsigned(din.reg.PC) + to_unsigned(1,16));
end case;
end calculate_next_PC;

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
variable op : split_opcode;
variable sg : cpu_op_signals;
variable halted, unlock : boolean;
begin

    v := r;
    ov := zero_decoder_out;

    v.st := next_cpu_state(r.st);
    
    --unlock halting once we detect rising edge
    unlock := r.current_int = '1' and r.last_int = '0';

    halted := r.inst = HALT and not unlock;
    
    -- read instruction
    if(r.st = sFETCH and not halted) then 
        -- if next is noop, its not a multiclock instruction
        if(r.next_i = NOOP) then 
            v.inst := decode_instruction_state(i.ram.data);
            if(is_root_state(v.inst)) then   
                v.opcode := i.ram.data;
            end if;
        else 
            v.inst := r.next_i;
        end if;
    end if;

    op := read_op(r.opcode);
    sg := decode_op(op);

    

    if(r.st = sFETCH) then 
        --update the interrupt logic by the fetch stage
        v.last_int := r.current_int;
        v.current_int := i.request_interrupt;

        if(halted and unlock ) then 
            v.inst := NOOP;
        end if;

        v.flags := i.reg.flags;
        if(r.inst = I_LD_LOAD_MEM) then 
            v.ramwrite := i.ram.data;
        elsif (r.inst = I_MEM_LOAD or r.inst = I_MEM_STORE) then 
            v.inmediate(7 downto 0) := i.ram.data;
        elsif (r.inst = I_MEM_LOAD_LD1 or r.inst = I_MEM_STORE_LD1) then 
            v.inmediate(15 downto 8) := i.ram.data;       
        end if;
    end if;

    if(r.st = sEXEC) then  -- decide branching target
        --at the time we have ram input with the OP
        case(r.inst) is 
        when I_ABS_BRANCH =>  
            --if should_branch(decode_branch_type(v.opcode),i.reg.flags) then
            if should_branch(sg.cond,r.flags) then 
              
                 v.do_branch := '1';
            else
                 v.do_branch := '0';
            end if;
        when I_ABS_BRANCH_LD1 =>
            v.branch_adress(7 downto 0) := i.ram.data;
        when I_ABS_BRANCH_LD2 =>
            v.branch_adress(15 downto 8) := i.ram.data;
        when I_ABS_BRANCH_JMP =>
            v.branch_adress := r.branch_adress;
        when others =>
            v.branch_adress := x"0000";
            v.do_branch := '0';
        end case;
    end if;

    v.next_i := next_instr(r.inst,r.do_branch);
    

    -- read registers
    ov.reg := read_registers(r,r.opcode);

    -- we write at the write substate if the instruction has writeback
    -- unless its an alu operation, then we have early write at EXEC stage
    if( ((r.st = sWrite) and instruction_has_reg_write(r.inst)) or 
    ((r.st = sExec) and instruction_has_early_reg_write(r.inst))         
    ) then 
     
        if (r.inst = R_ALU or r.inst = I_ALU_LOAD) and op.y = "111" then 
            ov.reg.write_enable := '0';
        else
            ov.reg.write_enable := '1';        
        end if;
    else
        ov.reg.write_enable := '0';
    end if;

    -- we have write enabled for flags at the exec stage to match the alu output
    iF(r.st = sExec and writes_flags(r.inst)) then 
        ov.reg.flag_write  := '1';  
    else 
        ov.reg.flag_write := '0';
    end if;
   
    ov.reg.data := select_reg_data(r.inst, i.reg,i.alu.op_R, i.ram.data);

    -- advance the PC at the last state, to be ready for next fetch    
    if(r.st = sWAIT and not halted) then
        
        ov.reg.PCIn := calculate_next_PC(r.inst,i, r.branch_adress);
    elsif (r.st = sSTART) then       
        ov.reg.PCIn := x"0000";        
    else
        ov.reg.PCIn := i.reg.PC;
    end if;

    ov.reg.flags := i.alu.flags; 

     -- alu mode 
    if r.inst = R_ALU or r.inst = I_ALU_LOAD then 
        ov.alu.mode := sg.alu_op;--decode_alu_mode(op.y);
        
        if(op.y = "001" or op.y = "011") then
            ov.alu.with_carry := '1' and r.flags.full_carry;
        else
            ov.alu.with_carry := '0';
        end if;
    elsif r.inst = R_ALU_SIMPLE then 
        case (op.z) is 
            when "100" => ov.alu.mode := o_ADD; -- inc
            when "101" => ov.alu.mode := o_SUB; -- sub
            when others => ov.alu.mode := o_OR;
        end case;  

        ov.alu.with_carry := '0';
    else
        ov.alu.with_carry := '0';
        ov.alu.mode := o_OR;
    end if;
   

    ov.alu.double := '0';
    ov.alu.op_A(7 downto 0) := i.reg.data_A;

    -- inmediate alu has the op from RAM
    if(r.inst = I_ALU_LOAD) then 
        ov.alu.op_B(7 downto 0) := i.ram.data;
    else
        ov.alu.op_B(7 downto 0) := i.reg.data_B;
    end if;

    ov.ram.addr := r.load_adress;

    -- ram outputs
    if(r.st = sSTART) then        
        v.load_adress := x"0000";    
        
    elsif(r.st = sEXEC) then -- calculate next adress at EXEC stage

        case r.inst is 

            when I_ABS_BRANCH_JMP => 
                v.load_adress := r.branch_adress;

            when R_LD_MEM_STORE|I_LD_EXEC_MEM|R_LD_MEM_LOAD =>
                v.load_adress := i.reg.wide;

            when I_MEM_LOAD_LD2|I_MEM_STORE_LD2 =>
                 v.load_adress := r.inmediate;

            when others =>
                if halted then 
                    v.load_adress := i.reg.PC;
                else
                    v.load_adress := calculate_next_addr(r.inst,i);
                end if;
        end case;

    end  if;

    
    
    if(writes_to_ram(r.inst)) then 
        ov.ram.we  := '1';
    else
        ov.ram.we  := '0';
    end if;
     
    if(r.inst = I_LD_EXEC_MEM) then 
        ov.ram.data := r.ramwrite;    
    else     
        ov.ram.data := i.reg.data_A;
    end if;

    -- clock syncronization. We want the value to update at the wait/exec stages
    if(r.st = sFETCH or r.st = sWAIT) then
        ov.ramclock := '1';
    else
        ov.ramclock := '0';
    end if;

    if reset = '1' then
        rin <= zero_state;
    else    
        rin <= v;   
    end if;

o <= ov;
end process;

end Behavioral;
