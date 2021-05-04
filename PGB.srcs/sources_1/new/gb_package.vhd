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

package gb_package is

  subtype  gb_word IS std_logic_vector (7 DOWNTO 0);
  subtype  gb_doubleword IS std_logic_vector (15 DOWNTO 0);

  type gb_px_coord is record
    x  : gb_word;
    y : gb_word;
  end record gb_px_coord;  

  type gb_2px is record
    data : std_logic_vector(1 downto 0);
  end record gb_2px;  

  type alu_flags is record
    zero       : std_logic;
    subtract   : std_logic;
    half_carry : std_logic;
    full_carry : std_logic;  
  end record alu_flags;



  type alu_operation is (
    o_ADD, 
    o_SUB, 
    o_AND,
    o_OR,
    o_XOR
  );

  type reg_name is (
    A, F,
    B, C,
    D, E,
    H, L
  );

  type reg_in is record 

    reg_A : reg_name; -- register for output 1
    reg_B : reg_name; -- register for output 2
   
    write_enable : std_logic; -- enable writing, to reg A from data

    data :  gb_word; -- data to write to reg-a
    flags : alu_flags; -- input alu flags
    PCin : gb_doubleword; -- PC register in
  end record reg_in;

  

  type reg_out is record 
    data_A, data_B:  gb_word; -- register outputs
    PC  : gb_doubleword;
    flags : alu_flags; -- output alu flags
  end record reg_out;
   


  type alu_in is record 
    op_A :  gb_doubleword;
    op_B :  gb_doubleword;
    mode : alu_operation;
    double : std_logic; -- to use double width logic
    with_carry : std_logic; -- for add/sub with carry ops
  end record alu_in;

  type alu_out is record  
    op_R :  gb_doubleword; --doubleword output
    flags : alu_flags; -- flags
  end record alu_out;

  type ram_in is record  
    addr :  gb_doubleword; 
    data : gb_word; 
    we : std_logic;
  end record ram_in;

  type ram_out is record     
    data : gb_word; 
  end record ram_out;
  
  type decoder_in is record 
    reg :  reg_out;
    alu :  alu_out;
    ram : ram_out;
  end record decoder_in;

  type decoder_out is record 
  reg :  reg_in;
  alu :  alu_in;
  ram : ram_in;
  ramclock : std_logic;
  end record decoder_out;

  type gb_pixel_line is array (7 downto 0) of gb_2px; -- 8 pixel line

  constant zero_ram_in : ram_in := (      
    addr => x"0000", 
    data => x"00", 
    we  => '0'
  );

  constant zero_alu_flags : alu_flags := (      
    zero => '0',                       
    subtract => '0',
    half_carry => '0',
    full_carry => '0'
  );

  constant zero_alu_in : alu_in := (      
    op_A => x"0000",   
    op_B => x"0000",   
    mode => o_ADD,
    double => '0',
    with_carry => '0'
  );

  constant zero_alu_out : alu_out := (      
    op_R => x"0000",                       
    flags => zero_alu_flags
  );

  constant zero_reg_in : reg_in := (
    reg_A => A, 
    reg_B => A, 
    write_enable => '0',
    data => x"00", 
    flags => zero_alu_flags,
    PCin => x"0000"
  );
  constant zero_reg_out : reg_out := (
    data_A => x"00", 
    data_B => x"00", 
    PC => x"0000", 
    flags => zero_alu_flags
  );

  constant zero_decoder_out : decoder_out := (      
    reg => zero_reg_in,                       
    alu => zero_alu_in,
    ram => zero_ram_in,
    ramclock => '0'
  );

end package gb_package;
