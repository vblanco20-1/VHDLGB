----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.02.2021 17:19:18
-- Design Name: 
-- Module Name: clk_divider - Behavioral
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

entity clk_divider is
    generic (N : integer);
    Port ( clk,reset : in STD_LOGIC;
           clk_out : out STD_LOGIC);
end clk_divider;


architecture Behavioral of clk_divider is
signal state : unsigned (N-1 downto 0);
signal next_state : unsigned (N-1 downto 0);

begin

clk_out <= state(N-1);

--update current state to next state at the clock
sync: process(clk,reset)
begin
    if(reset = '1') then
        state <= to_unsigned(0,N);
    elsif clk'event and clk='1' then
        state<= next_state;
    end if; 
end process sync;

-- whenever e is 1, update state
change: process(state)
begin
    next_state <= state + 1;    
end process change;

end Behavioral;

