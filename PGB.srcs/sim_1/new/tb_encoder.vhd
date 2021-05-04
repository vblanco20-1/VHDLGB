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
use IEEE.NUMERIC_STD.ALL;
library vunit_lib;
context vunit_lib.vunit_context;


library work;
use work.gb_package.all;

entity tb_encoder is
generic (runner_cfg : string);
end tb_encoder;

architecture Behavioral of tb_encoder is

component gb_alu is

Port ( i : in alu_in;
		o : out alu_out
		);
end component;

component gb_reg is
 
  Port ( clk,reset : in std_logic;
         i : in reg_in; -- input clocks
         o : out reg_out
         );
end component;

component gb_decoder is 
  Port ( clk,reset : in std_logic;
         i : in decoder_in; 
         o : out decoder_out
         );
end component;

signal aluin: alu_in;
signal aluout : alu_out;
signal regin: reg_in;
signal regout : reg_out;
signal decin: decoder_in;
signal decout : decoder_out;

signal outhalf : gb_word;
signal ramdata : gb_word;
signal reset,clock,wantsclock, read_reg,ramclock : std_logic;
signal regin_tb : reg_in;

signal use_tbram  : std_logic; 

signal tr_idx , tr_saved_idx: std_logic_vector(15 downto 0);
signal tr_data: gb_word;
signal tr_nextdata: gb_word;
TYPE mem_type IS ARRAY(0 TO 10) OF gb_word; 



signal test_block_1 : mem_type := (
--x"c3",x"0c",x"02",x"00",x"00",x"00",x"00",x"00"
x"00",x"3E",x"33",x"7F",x"7F",x"00",x"76",x"76",x"00",x"00",x"00");


begin

ramsync : process (ramclock,tr_nextdata,tr_idx)
begin
  if rising_edge(ramclock) then
      --tr_data <= tr_nextdata;
      tr_saved_idx <= tr_idx;
	end if;
end process;

ramcomb : process (tr_saved_idx)
variable intid  : unsigned(15 downto 0);
variable intdx : integer;
begin
  intid := unsigned(tr_saved_idx);
  intdx := to_integer(intid);
  tr_data <= test_block_1(intdx);
end process;




outhalf <= aluout.op_R(7 downto 0);


alu: gb_alu port map (i => aluin, o => aluout);
reg: gb_reg port map (clk=> clock, reset => reset, i => regin, o => regout);
dec: gb_decoder port map (clk=> clock, reset => reset, i => decin, o => decout);

--rA <=  << signal .reg.r.A : gb_word >> ;

decin.reg <= regout;
decin.alu <= aluout;
decin.ram.data <= ramdata when use_tbram = '0' else tr_data;

tr_idx <= decout.ram.addr;

ramclock <= decout.ramclock;
regin_tb <= zero_reg_in;

regin <= decout.reg when read_reg = '0' else regin_tb ;

aluin <= decout.alu;


clock_p: process
begin 
	clock <= '1' and wantsclock;
	wait for 1 ns;
	clock <= '0';
	wait for 1 ns;
end process;


main : process
begin
  test_runner_setup(runner, runner_cfg);
	use_tbram <= '0';
	if run("add_basic") then
  read_reg <= '0';
  wantsclock <= '1';
  reset <= '1';
  ramdata <= x"0C"; -- INC C
  wait for 2 ns;
  reset <= '0';
  wait for 8 ns; -- 1 cycle
  ramdata <= x"89"; -- ADC A,C
  wait for 8 ns; -- 1 cycle
  ramdata <= x"81"; -- ADD A,C
  wait for 8 ns; -- 1 cycle

  wantsclock <= '0';

  read_reg <= '1';

  wait for 2 ns;
  check_equal( regout.data_A ,std_logic_vector'(x"02"), result("SHould give 2"));
  end if;
  if run("ld_basic") then
    read_reg <= '0';
    wantsclock <= '1';
    reset <= '1';
    ramdata <= x"0C"; -- INC C C = 1, A = 0
    wait for 2 ns;
    reset <= '0';
    wait for 8 ns; -- 1 cycle
    ramdata <= x"89"; -- ADC A,C C = 1, A = 1
    wait for 8 ns; -- 1 cycle
    ramdata <= x"81"; -- ADD A,C C = 1, A = 2
    wait for 8 ns; -- 1 cycle
    ramdata <= x"4F"; -- LD C,A C = 2, A = 2
    wait for 8 ns; -- 1 cycle
    ramdata <= x"81"; -- ADD A,C C = 2, A = 4
    wait for 8 ns;

    wantsclock <= '0';
  
    read_reg <= '1';
  
    wait for 2 ns;
    check_equal( regout.data_A ,std_logic_vector'(x"04"), result("SHould give 4"));  
  end if;

  if run("ld_inst") then
    read_reg <= '0';
    wantsclock <= '1';
    reset <= '1';
    ramdata <= x"3E"; -- LD A , imm
    wait for 2 ns;
    reset <= '0';
    wait for 8 ns; -- 1 cycle
    ramdata <= x"33"; -- imm = 0x33
    wait for 8 ns; -- 1 cycle

    wantsclock <= '0';
  
    read_reg <= '1';
  
    wait for 2 ns;
    check_equal( regout.data_A ,std_logic_vector'(x"33"), result("SHould give x33"));  
  end if;

  if run("noops") then
    read_reg <= '0';
    wantsclock <= '1';
    reset <= '1';
    ramdata <= x"00"; -- Noop
    wait for 2 ns;
    reset <= '0';
    wait for 8 ns; -- 1 cycle

    check_equal( decout.ram.addr ,std_logic_vector'(x"0001"), result("CPU should try to read 1"));  

    ramdata <= x"00"; -- Noop
    wait for 8 ns; -- 1 cycle

    check_equal( decout.ram.addr ,std_logic_vector'(x"0002"), result("CPU should try to read 2"));  

    ramdata <= x"76"; -- HALT
    wait for 8 ns; -- 1 cycle

    check_equal( regout.PC ,std_logic_vector'(x"0002"), result("PC should stay at 2: 1"));  
    wait for 8 ns; -- 1 cycle

    check_equal( regout.PC ,std_logic_vector'(x"0002"), result("PC should stay at 2: 2"));  
     
    wait for 24 ns;
    check_equal( regout.PC ,std_logic_vector'(x"0002"), result("PC should stay at 2: 3"));  
  end if;

  if run("stest") then
    use_tbram <= '1';
    read_reg <= '0';
    wantsclock <= '1';
    reset <= '1';
    --ramdata <= x"00"; -- Noop
    wait for 4 ns;
    reset <= '0';
    wait for 8 ns; -- 1 cycle

    --check_equal( decout.ram.addr ,std_logic_vector'(x"0001"), result("CPU should try to read 1"));  

    --ramdata <= x"00"; -- Noop
    wait for 8 ns; -- 1 cycle

    --check_equal( decout.ram.addr ,std_logic_vector'(x"0002"), result("CPU should try to read 2"));  
     
    wait for 50 ns;
    read_reg <= '1';
  
    wait for 2 ns;
    check_equal( regout.data_A ,std_logic_vector'(x"33"), result("SHould give x33"));   
  end if;


  test_runner_cleanup(runner); -- Simulation ends here
  end process;


end Behavioral;
