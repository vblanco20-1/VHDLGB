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

library vunit_lib;
context vunit_lib.vunit_context;


library work;
use work.gb_package.all;

entity tb_alu is
generic (runner_cfg : string);
end tb_alu;

architecture Behavioral of tb_alu is

component gb_alu is

Port ( i : in alu_in;
		o : out alu_out
		);
end component;

signal aluin: alu_in;
signal aluout : alu_out;
signal outhalf : gb_word;
begin



outhalf <= aluout.op_R(7 downto 0);


alu: gb_alu port map (i => aluin, o => aluout);


main : process
begin
  test_runner_setup(runner, runner_cfg);
	
	--setup
	aluin.op_A <= x"0000";
	aluin.op_B <= x"0000";
	aluin.double <= '0';
	aluin.with_carry <= '0';
	aluin.flags <= zero_alu_flags;

if run("add") then
------- -------
  aluin.mode <= o_ADD;

  wait for 1 ns;

  check_equal(outhalf,  std_logic_vector'(x"00"), result("0 + 0 = 0"));
  check_equal(aluout.flags.zero,  '1', result("0 + 0 zero flag"));
  check_equal(aluout.flags.full_carry and aluout.flags.half_carry and aluout.flags.subtract,  '0', result("0 + 0 other flags must be null"));
------- -------
  aluin.with_carry <= '1';
  aluin.flags.full_carry <= '1';

  wait for 1 ns;

  check_equal(outhalf,  std_logic_vector'(x"01"), result("0 + 0(carry 1) = 1"));
  check_equal(aluout.flags.zero,  '0', result("0 + 0(carry) zero flag"));
  check_equal(aluout.flags.full_carry and aluout.flags.half_carry and aluout.flags.subtract,  '0', result("0 + 0(carry) other flags must be null"));
  
------- -------
  aluin.flags.full_carry <= '0';

  wait for 1 ns;

  check_equal(outhalf,  std_logic_vector'(x"00"), result("0 + 0(carry 0) = 0"));
  check_equal(aluout.flags.zero,  '1', result("0 + 0(carry 0) zero flag"));
  check_equal(aluout.flags.full_carry and aluout.flags.half_carry and aluout.flags.subtract,  '0', result("0 + 0(carry 0) other flags must be null"));

 ------- -------
  aluin.op_A <= x"000F"; -- 15
  aluin.op_B <= x"0001"; -- 1
  wait for 1 ns;

  check_equal(outhalf,  std_logic_vector'(x"10"), result("15 + 1 = 16"));
  check_equal(aluout.flags.half_carry,  '1', result("15 + 1 = 16 hcarry flag"));
  check_equal(aluout.flags.full_carry and aluout.flags.zero  and aluout.flags.subtract,'0', result("15 + 1 = 16 other flags must be null"));


------- -------
aluin.op_A <= x"000F"; -- 15
aluin.op_B <= x"0000"; -- 0
aluin.flags.full_carry <= '1';

wait for 1 ns;

check_equal(outhalf,  std_logic_vector'(x"10"), result("15 + 0(carry) = 16"));
check_equal(aluout.flags.half_carry,  '1', result("15 + 0(carry) = 16 hcarry flag"));
check_equal(aluout.flags.full_carry and aluout.flags.zero  and aluout.flags.subtract,'0', result("15 + 1 = 16 other flags must be null"));

------- -------
aluin.op_A <= x"00FF"; -- 255
aluin.op_B <= x"0001"; -- 1
aluin.flags.full_carry <= '0';

wait for 1 ns;

check_equal(outhalf,  std_logic_vector'(x"00"), result("255 + 1 = 0(wrap)"));
check_equal(aluout.flags.full_carry,  '1', result("255 + 1 = 0(wrap) = 0"));
check_equal(aluout.flags.zero,  '1', result("255 + 1 = 0(wrap) = 0"));
check_equal(aluout.flags.half_carry  and aluout.flags.subtract,'0', result("255 + 1 = 0(wrap) = 0"));

end if;

  test_runner_cleanup(runner); -- Simulation ends here
  end process;


end Behavioral;
