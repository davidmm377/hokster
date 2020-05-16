----------------------------------------------------------------------------------
-- Engineer: Tom Conroy
-- Module Name: GPRegisters - Structural
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: General Purpose Registers
--  Contains the r0-7 and a0-7 registers and shadow registers
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

entity GPRegisters is
    Generic ( G_NUM_SHDW_REGS : integer := 2);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           load_shadow: in STD_LOGIC;
           unload_shadow : in STD_LOGIC;
           
           addr1 : in STD_LOGIC_VECTOR (3 downto 0);
           wdata1 : in STD_LOGIC_VECTOR (7 downto 0);
           write1 : in STD_LOGIC;
           out1 : out STD_LOGIC_VECTOR (7 downto 0);
           
           addr2 : in STD_LOGIC_VECTOR (3 downto 0);
           wdata2 : in STD_LOGIC_VECTOR (7 downto 0);
           write2 : in STD_LOGIC;
           out2 : out STD_LOGIC_VECTOR (7 downto 0);
           
           pairaddr : in STD_LOGIC_VECTOR (2 downto 0);
           pairout : out STD_LOGIC_VECTOR (15 downto 0));
end GPRegisters;

architecture Structural of GPRegisters is
signal r_i, r_inext : STD_LOGIC_VECTOR (63 downto 0);

signal a_i, a_inext : STD_LOGIC_VECTOR (63 downto 0);

signal shadow_a_i, shadow_a_inext : STD_LOGIC_VECTOR ((8*G_NUM_SHDW_REGS)-1 downto 0);
signal shadow_r_i, shadow_r_inext : STD_LOGIC_VECTOR ((8*G_NUM_SHDW_REGS)-1 downto 0);

begin

GEN_RI:
for I in 0 to 7 generate
    
    SAVED_RI:
    if I < G_NUM_SHDW_REGS generate
        r_inext (8*(I+1)-1 downto 8*I) <=
            shadow_r_i (8*(I+1)-1 downto 8*I) when unload_shadow = '1' else
            wdata1 when ((addr1 = '0' & STD_LOGIC_VECTOR(to_unsigned(I, 3))) and (write1 = '1')) else
            wdata2 when ((addr2 = '0' & STD_LOGIC_VECTOR(to_unsigned(I, 3))) and (write2 = '1')) else
            r_i (8*(I+1)-1 downto 8*I);
    end generate;
    
    UNSAVED_RI:
    if I >= G_NUM_SHDW_REGS generate
        r_inext (8*(I+1)-1 downto 8*I) <=
            wdata1 when ((addr1 = '0' & STD_LOGIC_VECTOR(to_unsigned(I, 3))) and (write1 = '1')) else
            wdata2 when ((addr2 = '0' & STD_LOGIC_VECTOR(to_unsigned(I, 3))) and (write2 = '1')) else
            r_i (8*(I+1)-1 downto 8*I);
    end generate;
    
    store_r_i: entity work.regn(behavioral)
        generic map(n => 8)
        port map(
            d => r_inext (8*(I+1)-1 downto 8*I),
            clk => clk,
            rst => rst,
            q => r_i (8*(I+1)-1 downto 8*I)
        );
end generate;

GEN_AI:
for I in 0 to 7 generate

    SAVED_AI:
    if I < G_NUM_SHDW_REGS generate
        a_inext (8*(I+1)-1 downto 8*I) <=
            shadow_a_i (8*(I+1)-1 downto 8*I) when unload_shadow = '1' else
            wdata1 when ((addr1 = '1' & STD_LOGIC_VECTOR(to_unsigned(I, 3))) and (write1 = '1')) else
            wdata2 when ((addr2 = '1' & STD_LOGIC_VECTOR(to_unsigned(I, 3))) and (write2 = '1')) else
            a_i (8*(I+1)-1 downto 8*I);
    end generate;
    
    UNSAVED_AI:
    if I >= G_NUM_SHDW_REGS generate
        a_inext (8*(I+1)-1 downto 8*I) <=
            wdata1 when ((addr1 = '1' & STD_LOGIC_VECTOR(to_unsigned(I, 3))) and (write1 = '1')) else
            wdata2 when ((addr2 = '1' & STD_LOGIC_VECTOR(to_unsigned(I, 3))) and (write2 = '1')) else
            a_i (8*(I+1)-1 downto 8*I);
    end generate;
            
    store_a_i: entity work.regn(behavioral)
        generic map(n => 8)
        port map(
            d => a_inext (8*(I+1)-1 downto 8*I),
            clk => clk,
            rst => rst,
            q => a_i (8*(I+1)-1 downto 8*I)
        );
end generate;
    
with load_shadow select
    shadow_a_inext <=
        a_i (8*(G_NUM_SHDW_REGS)-1 downto 0) when '1',
        shadow_a_i when others;
                        
store_shadow_a_i: entity work.regn(behavioral)
    generic map(n => 8*G_NUM_SHDW_REGS)
    port map(
        d => shadow_a_inext,
        clk => clk,
        rst => rst,
        q => shadow_a_i
    );

with load_shadow select
    shadow_r_inext <=
        r_i (8*(G_NUM_SHDW_REGS)-1 downto 0) when '1',
        shadow_r_i when others;
                        
store_shadow_r_i: entity work.regn(behavioral)
    generic map(n => 8*G_NUM_SHDW_REGS)
    port map(
        d => shadow_r_inext,
        clk => clk,
        rst => rst,
        q => shadow_r_i
    );

with addr1 select
    out1 <= r_i (7 downto 0) when r0addr,
            r_i (15 downto 8) when r1addr,
            r_i (23 downto 16) when r2addr,
            r_i (31 downto 24) when r3addr,
            r_i (39 downto 32) when r4addr,
            r_i (47 downto 40) when r5addr,
            r_i (55 downto 48) when r6addr,
            r_i (63 downto 56) when r7addr,
            a_i (7 downto 0) when a0addr,
            a_i (15 downto 8) when a1addr,
            a_i (23 downto 16) when a2addr,
            a_i (31 downto 24) when a3addr,
            a_i (39 downto 32) when a4addr,
            a_i (47 downto 40) when a5addr,
            a_i (55 downto 48) when a6addr,
            a_i (63 downto 56) when others;
            
with addr2 select
    out2 <= r_i (7 downto 0) when r0addr,
            r_i (15 downto 8) when r1addr,
            r_i (23 downto 16) when r2addr,
            r_i (31 downto 24) when r3addr,
            r_i (39 downto 32) when r4addr,
            r_i (47 downto 40) when r5addr,
            r_i (55 downto 48) when r6addr,
            r_i (63 downto 56) when r7addr,
            a_i (7 downto 0) when a0addr,
            a_i (15 downto 8) when a1addr,
            a_i (23 downto 16) when a2addr,
            a_i (31 downto 24) when a3addr,
            a_i (39 downto 32) when a4addr,
            a_i (47 downto 40) when a5addr,
            a_i (55 downto 48) when a6addr,
            a_i (63 downto 56) when others;
            
with pairaddr select
    pairout <=  a_i (7 downto 0) & r_i (7 downto 0) when r0addr(2 downto 0),
                a_i (15 downto 8) & r_i (15 downto 8) when r1addr(2 downto 0),
                a_i (23 downto 16) & r_i (23 downto 16) when r2addr(2 downto 0),
                a_i (31 downto 24) & r_i (31 downto 24) when r3addr(2 downto 0),
                a_i (39 downto 32) & r_i (39 downto 32) when r4addr(2 downto 0),
                a_i (47 downto 40) & r_i (47 downto 40) when r5addr(2 downto 0),
                a_i (55 downto 48) & r_i (55 downto 48) when r6addr(2 downto 0),
                a_i (63 downto 56) & r_i (63 downto 56) when others;
                
end Structural;
