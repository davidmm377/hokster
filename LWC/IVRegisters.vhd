----------------------------------------------------------------------------------
-- Engineer: Tom Conroy
-- Module Name: IVRegisters - Structural
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
use work.SoftCoreConstants.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity IVRegisters is
    Generic ( G_NUM_IV_REGS : integer := 4
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           addr : in STD_LOGIC_VECTOR (3 downto 0);
           wdata : in STD_LOGIC_VECTOR (7 downto 0);
           write : in STD_LOGIC;
           iv : out STD_LOGIC_VECTOR (7 downto 0)
    );
end IVRegisters;

architecture Structural of IVRegisters is
signal iv_i, iv_inext : STD_LOGIC_VECTOR (127 downto 0);
begin

GEN_IV:
for I in 0 to 15 generate
    GEN_REG:
    if I < G_NUM_IV_REGS generate
        iv_inext (8*(I+1)-1 downto 8*I) <=
            wdata when ((addr = STD_LOGIC_VECTOR(to_unsigned(I, 4))) and (write = '1')) else
            iv_i (8*(I+1)-1 downto 8*I);
                
        store_iv_i: entity work.regn(behavioral)
            generic map(n => 8)
            port map(
                d => iv_inext (8*(I+1)-1 downto 8*I),
                clk => clk,
                rst => rst,
                q => iv_i (8*(I+1)-1 downto 8*I)
            );
    end generate;
    
    GEN_PLACEHOLDER:
    if I >= G_NUM_IV_REGS generate
        iv_i (8*(I+1)-1 downto 8*I) <= x"00";
    end generate;
end generate;
    
with addr select
    iv <=   iv_i (7 downto 0) when x"0",
            iv_i (15 downto 8) when x"1",
            iv_i (23 downto 16) when x"2",
            iv_i (31 downto 24) when x"3",
            iv_i (39 downto 32) when x"4",
            iv_i (47 downto 40) when x"5",
            iv_i (55 downto 48) when x"6",
            iv_i (63 downto 56) when x"7",
            iv_i (71 downto 64) when x"8",
            iv_i (79 downto 72) when x"9",
            iv_i (87 downto 80) when x"a",
            iv_i (95 downto 88) when x"b",
            iv_i (103 downto 96) when x"c",
            iv_i (111 downto 104) when x"d",
            iv_i (119 downto 112) when x"e",
            iv_i (127 downto 120) when others;
            
end Structural;
