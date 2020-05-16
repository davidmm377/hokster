----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Module Name: ALU - Structural
-- Project Name: HOKSTER Core
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

entity ALU is
    Port ( a : in UNSIGNED (7 downto 0);
           b : in UNSIGNED (7 downto 0);
           sr : in STD_LOGIC_VECTOR (7 downto 0);
           opc2 : in alu_opc2Type;
           result_out : out UNSIGNED (7 downto 0);
           sr_out : out STD_LOGIC_VECTOR (7 downto 0));
end ALU;

architecture Behavioral of ALU is

signal Cin : STD_LOGIC;
signal aINC : UNSIGNED (8 downto 0);
signal bC : UNSIGNED (8 downto 0);

signal addC : STD_LOGIC;
signal addresult : UNSIGNED (8 downto 0);

signal subC : STD_LOGIC;
signal subresult : UNSIGNED (8 downto 0);

signal andresult : UNSIGNED (7 downto 0);

signal lorresult : UNSIGNED (7 downto 0);

signal sllresult : UNSIGNED (7 downto 0);

signal rolresult : UNSIGNED (7 downto 0);

signal srlresult : UNSIGNED (7 downto 0);

signal rorresult : UNSIGNED (7 downto 0);

signal notresult : UNSIGNED (7 downto 0);

signal xorresult : UNSIGNED (7 downto 0);

signal result : UNSIGNED (7 downto 0);
signal resultN, resultZ : STD_LOGIC;

signal sbiC : STD_LOGIC;
signal sbiresult : UNSIGNED (8 downto 0);

begin

with opc2 select
    Cin <=  sr(srC) when opc2_adc,
            sr(srC) when opc2_sbc,
            '1' when opc2_adi,
            '1' when opc2_sbi,
            '0' when others;
            
aINC <= ('0' & a) + (x"00" & '1');
bC <= ('0' & b) + (x"00" & Cin);

addresult <= ('0' & a) + bC;
addC <= addresult(8);

subresult <= ('0' & a) - bC;
subC <= '1' when ('0' & a) < bC else '0';

andresult <= a and b;

lorresult <= a or b;

sllresult <= SHIFT_LEFT(b, to_integer(a));

rolresult <= ROTATE_LEFT(b, to_integer(a));

srlresult <= SHIFT_RIGHT(b, to_integer(a));

rorresult <= ROTATE_RIGHT(b, to_integer(a));

notresult <= not a;

xorresult <= a xor b;

sbiresult <= ('0' & b) - aINC;
sbiC <= '1' when ('0' & b) < aINC else '0';

with opc2 select
    result <=   addresult (7 downto 0) when opc2_add,
                subresult (7 downto 0) when opc2_sub,
                andresult when opc2_and,
                lorresult when opc2_lor,
                sllresult when opc2_sll,
                rolresult when opc2_rol,
                srlresult when opc2_srl,
                rorresult when opc2_ror,
                notresult when opc2_not,
                xorresult when opc2_xor,
                addresult (7 downto 0) when opc2_adc,
                subresult (7 downto 0) when opc2_sbc,
                addresult (7 downto 0) when opc2_adi,
                sbiresult (7 downto 0) when opc2_sbi,
                a when others;
                
result_out <= result;
resultN <= result(7);
resultZ <= '1' when result = x"00" else '0';
       
with opc2 select
    sr_out <=   "00000" & addC & resultN & resultZ when opc2_add,
                "00000" & subC & resultN & resultZ when opc2_sub,
                "00000" & addC & resultN & resultZ when opc2_adc,
                "00000" & subC & resultN & resultZ when opc2_sbc,
                "00000" & addC & resultN & resultZ when opc2_adi,
                "00000" & sbiC & resultN & resultZ when opc2_sbi,
                sr when others;
                
end Behavioral;
