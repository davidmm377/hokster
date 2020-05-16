----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: ALU_tb - Behavioral
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

entity ALU_tb is
--  Port ( );
end ALU_tb;

architecture Behavioral of ALU_tb is

signal a, b, result_out : UNSIGNED (7 downto 0);
signal sr : STD_LOGIC_VECTOR (7 downto 0);
signal opc2 : alu_opc2Type;
signal sr_out : STD_LOGIC_VECTOR (7 downto 0);
begin

uut: entity work.ALU(Behavioral)
    port map(a => a,
        b => b,
        sr => sr,
        opc2 => opc2,
        result_out => result_out,
        sr_out => sr_out
    );

process
begin
    -- init values
    a <= x"00";
    b <= x"00";
    sr <= x"00";
    opc2 <= opc2_add;
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = x"01"); -- zero flag set
    wait for 4 ns;
    
    -- Test add ---------------------------------------------------------------
    b <= x"01";
    wait for 1 ns;
    assert(result_out = x"01");
    assert(sr_out = x"00");
    wait for 4 ns;
    
    a <= x"23";
    b <= x"0F";
    wait for 1 ns;
    assert(result_out = x"32");
    assert(sr_out = x"00");
    wait for 4 ns;
    
    sr(srC) <= '1'; -- make sure carry doesn't change anything
    wait for 1 ns;
    assert(result_out = x"32");
    assert(sr_out = x"00");
    wait for 4 ns;
    
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"32");
    assert(sr_out = x"00");
    wait for 4 ns;
    
    a <= x"FF";
    b <= x"01";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000101"); -- carry & zero flag set
    wait for 4 ns;
    
    a <= x"FF";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FE");
    assert(sr_out = "00000110"); -- carry & negative flag set
    wait for 4 ns;
    
    a <= x"8F";
    b <= x"04";
    wait for 1 ns;
    assert(result_out = x"93");
    assert(sr_out = "00000010"); -- negative flag set
    wait for 4 ns;
    
    -- Test sub ---------------------------------------------------------------
    opc2 <= opc2_sub;
    a <= x"00";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000001"); -- zero flag set
    wait for 4 ns;
    
    a <= x"01";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"01");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"00";
    b <= x"01";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    a <= x"20";
    b <= x"6b";
    wait for 1 ns;
    assert(result_out = x"B5");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    sr(srC) <= '1'; -- carry in shouldn't matter
    wait for 1 ns;
    assert(result_out = x"B5");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"B5");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    a <= x"8D";
    b <= x"4F";
    wait for 1 ns;
    assert(result_out = x"3e");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    -- Test and ---------------------------------------------------------------
    opc2 <= opc2_and;
    a <= x"00";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000"); -- no flags for this operation
    wait for 4 ns;
    
    a <= x"FF";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"01";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"11";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"66";
    wait for 1 ns;
    assert(result_out = x"24");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"2C");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    -- Test lor ---------------------------------------------------------------
    opc2 <= opc2_lor;
    a <= x"00";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000"); -- no flags for this operation
    wait for 4 ns;
    
    a <= x"FF";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"2C");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"01";
    wait for 1 ns;
    assert(result_out = x"2D");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"11";
    wait for 1 ns;
    assert(result_out = x"3D");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"66";
    wait for 1 ns;
    assert(result_out = x"6E");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"2C";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    -- Test sll ---------------------------------------------------------------
    opc2 <= opc2_sll;
    a <= x"00";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000"); -- no flags for this operation
    wait for 4 ns;
    
    a <= x"00";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"01";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FE");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"02";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FC");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"F8");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"18");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"07";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"80");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"D7";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    -- Test rol ---------------------------------------------------------------
    opc2 <= opc2_rol;
    a <= x"00";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000"); -- no flags for this operation
    wait for 4 ns;
    
    a <= x"00";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"01";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"02";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"19");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"07";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"91");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"D7"; -- D7 mod 8 = 7
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"91");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    -- Test srl ---------------------------------------------------------------
    opc2 <= opc2_srl;
    a <= x"00";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000"); -- no flags for this operation
    wait for 4 ns;
    
    a <= x"00";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"01";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"7F");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"02";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"3F");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"1F");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"04");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"07";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"D7";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    -- Test ror ---------------------------------------------------------------
    opc2 <= opc2_ror;
    a <= x"00";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000"); -- no flags for this operation
    wait for 4 ns;
    
    a <= x"00";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"01";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"02";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"64");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"07";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"46");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"D7"; -- D7 mod 8 = 7
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"46");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    -- Test not ---------------------------------------------------------------
    opc2 <= opc2_not;
    a <= x"00";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000"); -- no flags for this operation
    wait for 4 ns;
    
    a <= x"00";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"01";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FE");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"02";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FD");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FC");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"23";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"DC");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"07";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"F8");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"D7";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"28");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    -- Test xor ---------------------------------------------------------------
    opc2 <= opc2_xor;
    a <= x"00";
    b <= x"00";
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000000"); -- no flags for this operation
    wait for 4 ns;
    
    a <= x"00";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"01";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FE");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"02";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FD");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"FF";
    wait for 1 ns;
    assert(result_out = x"FC");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"03";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"20");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"07";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"24");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"D7";
    b <= x"23";
    wait for 1 ns;
    assert(result_out = x"F4");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    -- Test adc ---------------------------------------------------------------
    opc2 <= opc2_adc;
    a <= x"00";
    b <= x"00";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000001"); -- Zero flag set
    wait for 4 ns;
    
    a <= x"00";
    b <= x"01";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"01");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"02");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"23";
    b <= x"0F";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"32");
    assert(sr_out = x"00");
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"33");
    assert(sr_out = x"00");
    wait for 4 ns;
    
    a <= x"FF";
    b <= x"01";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000101"); -- carry & zero flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"01");
    assert(sr_out = "00000100"); -- carry flag set
    wait for 4 ns;
    
    a <= x"FF";
    b <= x"FF";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"FE");
    assert(sr_out = "00000110"); -- carry & negative flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000110"); -- carry & negative flag set
    wait for 4 ns;
    
    a <= x"8F";
    b <= x"04";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"93");
    assert(sr_out = "00000010"); -- negative flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"94");
    assert(sr_out = "00000010"); -- negative flag set
    wait for 4 ns;
    
    -- Test sbc ---------------------------------------------------------------
    opc2 <= opc2_sbc;
    a <= x"00";
    b <= x"00";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000001"); -- zero flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000110"); -- carry & negative flag set
    wait for 4 ns;
    
    a <= x"01";
    b <= x"00";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"01");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000001"); -- zero flag set
    wait for 4 ns;
    
    a <= x"00";
    b <= x"01";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"FE");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    a <= x"20";
    b <= x"6b";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"B5");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"B4");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    a <= x"8D";
    b <= x"4F";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"3E");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"3D");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"8D";
    b <= x"FF";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"8E");
    assert(sr_out = "00000110"); -- carry and negative flags set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"8D");
    assert(sr_out = "00000110"); -- cary and negative flags set
    wait for 4 ns;
    
    -- Test adi ---------------------------------------------------------------
    opc2 <= opc2_adi;
    a <= x"00";
    b <= x"00";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"01");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"00";
    b <= x"01";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"02");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"02");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"23";
    b <= x"0F";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"33");
    assert(sr_out = x"00");
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"33");
    assert(sr_out = x"00");
    wait for 4 ns;
    
    a <= x"FF";
    b <= x"01";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"01");
    assert(sr_out = "00000100"); -- carry flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"01");
    assert(sr_out = "00000100"); -- carry flag set
    wait for 4 ns;
    
    a <= x"FF";
    b <= x"08";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"08");
    assert(sr_out = "00000100"); -- carry flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"08");
    assert(sr_out = "00000100"); -- carry flag set
    wait for 4 ns;
    
    a <= x"8F";
    b <= x"04";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"94");
    assert(sr_out = "00000010"); -- negative flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"94");
    assert(sr_out = "00000010"); -- negative flag set
    wait for 4 ns;
    
    -- Test sbc ---------------------------------------------------------------
    opc2 <= opc2_sbi;
    a <= x"00";
    b <= x"00";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000110"); -- carry & negative flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"FF");
    assert(sr_out = "00000110"); -- carry & negative flag set
    wait for 4 ns;
    
    a <= x"01";
    b <= x"00";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000001"); -- zero flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"00");
    assert(sr_out = "00000001"); -- zero flag set
    wait for 4 ns;
    
    a <= x"00";
    b <= x"01";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"FE");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"FE");
    assert(sr_out = "00000110"); -- carry (borrow) and negative flag set
    wait for 4 ns;
    
    a <= x"20";
    b <= x"0F";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"10");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"10");
    assert(sr_out = "00000000");
    wait for 4 ns;
    
    a <= x"8D";
    b <= x"0A";
    sr(srC) <= '0';
    wait for 1 ns;
    assert(result_out = x"82");
    assert(sr_out = "00000010"); -- negative flag set
    wait for 4 ns;
    
    sr(srC) <= '1';
    wait for 1 ns;
    assert(result_out = x"82");
    assert(sr_out = "00000010"); -- negative flag set
    wait for 4 ns;
    
    wait;
end process;
end Behavioral;
