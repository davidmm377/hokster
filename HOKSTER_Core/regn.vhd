
-------------------------------------------------------------------------------
--! @file       regn.vhd
--! @author     William Diehl
--! @brief      
--! @date       9 Sep 2016
--! @modified   13 Feb 2020 by Tom Conroy
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY regn IS
    GENERIC (N:INTEGER :=16);
    PORT(D : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
         CLK  : IN STD_LOGIC;
         RST  : IN STD_LOGIC;
         Q    : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END regn;

ARCHITECTURE behavioral OF regn IS
BEGIN
    PROCESS (CLK)
        BEGIN
            
        IF rising_edge(CLK) THEN
            IF (RST = '1') THEN
                Q <= (OTHERS => '0');
            ELSE
                Q <= D;
            END IF;
        END IF;
    END PROCESS;
END behavioral;