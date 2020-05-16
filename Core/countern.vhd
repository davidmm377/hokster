----------------------------------------------------------------------------------
-- Engineer: Tom Conroy
-- 
-- Design Name: 
-- Module Name: countern - Behavioral
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: Simple N-bit counter
--  rst resets the counter to 0
--  counter increments when enable = 1
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity countern is
    Generic ( N : integer := 8);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           enable : in STD_LOGIC;
           count : out STD_LOGIC_VECTOR (N-1 downto 0));
end countern;

architecture Structural of countern is
signal next_count, count_internal : STD_LOGIC_VECTOR (N-1 downto 0);
begin

next_count <= STD_LOGIC_VECTOR(UNSIGNED(count_internal) + 1)
    when enable = '1' else count_internal;

store_count: entity work.regn(behavioral)
    generic map(N => N)
    port map(
        d => next_count,
        clk => clk,
        rst => rst,
        q => count_internal
    );
    
count <= count_internal;

end Structural;
