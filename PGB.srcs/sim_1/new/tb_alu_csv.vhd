----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.03.2021 20:05:38
-- Design Name: 
-- Module Name: tb_vga - Behavioral
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
use ieee.numeric_std.all;   
library vunit_lib;
context vunit_lib.vunit_context;
use std.textio.all;

library work;
use work.gb_package.all;
use work.csv_file_reader_pkg.all;
use work.testbench_utils.all;

entity tb_alu_csv is
generic (runner_cfg : string);
end tb_alu_csv;

architecture Behavioral of tb_alu_csv is




component gb_alu is

Port ( i : in alu_in;
		o : out alu_out
		);
end component;

signal aluin: alu_in;
signal aluout : alu_out;
--signal outhalf : gb_word;
--signal outhalf_i,out_i, o_fz, o_fn, o_fh, o_fc : integer;

function itou ( b : in integer ) return std_logic is   
begin      
    if b = 1 then return '1'; else return '0'; end if;
end itou;

procedure run_csv( 
  variable csv : inout csv_file_reader_type;
  constant mode : in alu_operation;
  signal ain : out alu_in;
  signal aout : in alu_out
  ) is 
  variable op_res, f_z, f_n, f_h, f_c : integer;
  variable op_A_i,op_B_i, i_db, i_usecarry , i_fc: integer;
  variable name : string ( 256 to 0);
  variable s: line;
begin
  while not csv.end_of_file loop
    wait for 1 ns;
  csv.readline;

  s := new string'("");
  -- READ CSV
  op_A_i := csv.read_integer;
  op_B_i := csv.read_integer;

  i_db := csv.read_integer;
  i_usecarry := csv.read_integer;
  i_fc := csv.read_integer;

  op_res := csv.read_integer;

  f_z := csv.read_integer;
  f_n := csv.read_integer;
  f_h := csv.read_integer;
  f_c := csv.read_integer;    
  
  write(s, csv.read_string);

  -- ALU INPUTS
  ain.op_A <= std_logic_vector(to_unsigned(op_A_i, 16));
  ain.op_B <= std_logic_vector(to_unsigned(op_B_i, 16));

  ain.double <= '1' when i_db = 1 else '0';
  ain.with_carry <='1' when (i_usecarry = 1 and i_fc = 1) else '0';

  ain.mode <= mode;

  -- LOGS
  puts("-- Executing: ", s.all);

  puts("A = ", op_A_i);
  puts("B = ", op_B_i);
  puts("double = ", i_db);
  puts("withcarry = ", i_usecarry);
  puts("carryflag = ", i_fc);
 
  puts("EXPECTED  = ", op_res);

  wait for 1 ns;
 
  puts("GOT  = ", to_integer(unsigned(aout.op_R)));
  puts(" ------------ ");
  -- TEST OUTPUTS
  check_equal(to_integer(unsigned(aout.op_R)), op_res, result(":OP Error: " & s.all));
 
  check_equal(aout.flags.zero, itou(f_z), result(":FZ Error: " & s.all));
  check_equal(aout.flags.subtract, itou(f_n), result(":FN Error: " & s.all));
  check_equal(aout.flags.half_carry, itou(f_h), result(":FH Error: " & s.all));
  if(mode = o_SUB) then 
  check_equal(not aout.flags.full_carry, itou(f_c), result(":FC Error: " & s.all));
  else
  check_equal(aout.flags.full_carry, itou(f_c), result(":FC Error: " & s.all));
  end if;
  end loop;
end run_csv;


begin

alu: gb_alu port map (i => aluin, o => aluout);

main : process
variable csv_file_1,csv_file_2,csv_file_3,csv_file_4,csv_file_5: csv_file_reader_type;
begin
  test_runner_setup(runner, runner_cfg);
	
	aluin.double <= '0';

if run("add") then

  
  csv_file_1.initialize("/mnt/d/FPGA/PGB/PGB.srcs/sim_1/new/data/alu_add_tests.csv");

  --read the first line with column names to skip  
  csv_file_1.readline;

  run_csv(csv_file_1,o_ADD,aluin,aluout); 
end if;



if run("sub") then

  csv_file_2.initialize("/mnt/d/FPGA/PGB/PGB.srcs/sim_1/new/data/alu_sub_tests.csv");

  --read the first line with column names to skip  
  csv_file_2.readline;

  run_csv(csv_file_2,o_SUB,aluin,aluout);
end if;


if run("and") then

  csv_file_3.initialize("/mnt/d/FPGA/PGB/PGB.srcs/sim_1/new/data/alu_and_tests.csv");

  --read the first line with column names to skip  
  csv_file_3.readline;

  run_csv(csv_file_3,o_AND,aluin,aluout);
end if;

if run("or") then

  csv_file_4.initialize("/mnt/d/FPGA/PGB/PGB.srcs/sim_1/new/data/alu_or_tests.csv");

  --read the first line with column names to skip  
  csv_file_4.readline;

  run_csv(csv_file_4,o_OR,aluin,aluout);
end if;

if run("xor") then

  csv_file_5.initialize("/mnt/d/FPGA/PGB/PGB.srcs/sim_1/new/data/alu_xor_tests.csv");

  --read the first line with column names to skip  
  csv_file_5.readline;

  run_csv(csv_file_5,o_XOR,aluin,aluout);
end if;

  test_runner_cleanup(runner); -- Simulation ends here
  end process;


end Behavioral;
