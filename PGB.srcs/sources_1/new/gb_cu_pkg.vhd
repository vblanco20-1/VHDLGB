----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.03.2021 19:39:11
-- Design Name: 
-- Module Name: gb_package - 
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

package gb_cu_pkg is
 -- R for pure-registers singlestate ops.
    -- I for inmediate ops 
    type instruction_state is (
       NOOP, HALT,R_STOP,

       -- simple register alus. Always stores on A
       R_ALU,  
       -- for dec/inc
       R_ALU_SIMPLE,   

      -- inmediate alu
       I_ALU, I_ALU_LOAD, 
      -- control flow
       I_ABS_BRANCH, I_ABS_BRANCH_LD1 , I_ABS_BRANCH_LD2, I_ABS_BRANCH_JMP, -- absulte 16 bit branch 

       PREFIX_CD,
       -- register based load
       R_LD,
       -- register load, but write mem
       R_LD_MEM, R_LD_MEM_WRITE,

       I_LD_LOAD, I_LD_EXEC,
       I_LD_LOAD_MEM, I_LD_EXEC_MEM
    );
  type cpu_state is (
      sSTART,
      sFETCH, 
      sEXEC, 
      sWRITE,
      sWAIT
  );

  type branch_mode is (
    bAll, -- allways jump
    bNever,
    bNZ, 
    bZ,
    bNC,
    bC
  );

  type split_opcode is record    
        prefix : std_logic_vector(1 downto 0);    
        y : std_logic_vector(2 downto 0);    
        z : std_logic_vector(2 downto 0); 

        p : std_logic_vector(1 downto 0);
        q : std_logic;
  end record split_opcode;

  -- these map directly into the opcode table. 
  -- all of them  decoded just from opcode
  type cpu_op_signals is record    
  alu_op : alu_operation;
  ry : reg_name;
  rz : reg_name;
  rp2 : widereg_name;
  rp : widereg_name;
  cond : branch_mode;
  end record cpu_op_signals;


  function decode_alu_mode(op : std_logic_vector(2 downto 0)) return alu_operation;
  function read_op(op : in gb_word) return split_opcode;
  function decode_op(op : in split_opcode) return cpu_op_signals;
  function is_root_state(inst : instruction_state) return boolean;
  function writes_flags(inst : instruction_state) return boolean;
  function should_branch(m : in branch_mode; flags : in alu_flags) return boolean;
  function next_cpu_state (s : in cpu_state ) return cpu_state;
  function decode_registers_basic(index: in std_logic_vector(2 downto 0)) return reg_name;

end package gb_cu_pkg;

package body gb_cu_pkg is 

function read_op(op : in gb_word) return split_opcode is 
variable v: split_opcode;
begin   
  v.prefix := op(7 downto 6);
  v.y := op(5 downto 3);
  v.z := op(2 downto 0);
  v.p := op(5 downto 4);
  v.q := op(3);  
return v;
end read_op;

function next_cpu_state (s : in cpu_state ) return cpu_state is   
begin     
 case (s) is 
    when sSTART => return sFETCH;
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
      when "110" => return MHL; -- this is  for memory loads careful
      when others => return A; -- "111"
      end case;
  end decode_registers_basic;

  function should_branch(m : in branch_mode; flags : in alu_flags) return boolean is 
  begin 
  case (m) is
    when bNC => return (flags.full_carry = '0');  
    when bC =>  return (flags.full_carry = '1');  
    when bNZ => return (flags.zero = '0');  
    when bZ => return (flags.zero = '1'); 
    when bNever => return false; 
    when others => return true; -- for All, allways branch
  end case;
  end should_branch;

  function is_root_state(inst : instruction_state) return boolean is 
  begin 
  case (inst) is
    when I_ABS_BRANCH_LD1| I_ABS_BRANCH_LD2| I_ABS_BRANCH_JMP => return false;   
    when I_LD_EXEC => return false; 
    when others => return true; -- for All, allways branch
  end case;
  end is_root_state;

  function writes_flags(inst : instruction_state) return boolean is 
  begin 
  case (inst) is
    -- alu allways writes flags
    when R_ALU|R_ALU_SIMPLE|I_ALU_LOAD => 
      return true;       
    when others => return false;
  end case;
  end writes_flags;

  function decode_alu_mode(op : std_logic_vector(2 downto 0)) return alu_operation is 
  begin 
  case (op) is
   when "000" => return o_ADD;
   when "001" => return o_ADD;
   when "010" => return o_SUB;
   when "011" => return o_SUB;
   when "100" => return o_AND;
   when "101" => return o_XOR;
   when "110" => return o_OR;
   when others => return o_SUB;
  end case;
  end decode_alu_mode;


  function decode_op(op : in split_opcode) return cpu_op_signals is 
  variable v: cpu_op_signals;

  begin

    v.alu_op := decode_alu_mode(op.y);
    v.ry := decode_registers_basic(op.y);
    v.rz := decode_registers_basic(op.z);

    case op.p is
      when "00" => 
      v.rp2 := BC;
      v.rp := BC;
      when "01" => 
      v.rp2 := DE;
      v.rp := DE;
      when "10" => 
      v.rp2 := HL;
      v.rp := HL;
      when others =>
      v.rp2 := AF;
      v.rp := SP;    
    end case;
   

    if(op.z(0) = '0') then 
      case op.y(1 downto 0) is
        when "00" => 
        v.cond := bNZ;
        when "01" => 
        v.cond := bZ;
        when "10" => 
        v.cond := bNC;
        when others =>
        v.cond := bC;
      end case;
    else
      v.cond := bAll;
    end if;

    return v;
  end decode_op;
end gb_cu_pkg;