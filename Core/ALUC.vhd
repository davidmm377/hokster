---------------------------------------------------------------------------------- 
-- Engineer: Tom Conroy

-- Module Name: ALUC - Structural
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALUC is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           a : in STD_LOGIC_VECTOR (7 downto 0);
           b : in STD_LOGIC_VECTOR (7 downto 0);
           Im : in STD_LOGIC_VECTOR (3 downto 0);
           opc2 : in STD_LOGIC_VECTOR (3 downto 0);
           sr : in STD_LOGIC_VECTOR (7 downto 0);
           sr_out : out STD_LOGIC_VECTOR (7 downto 0);
           result : out STD_LOGIC_VECTOR (7 downto 0);
           wait_req : out STD_LOGIC);
end ALUC;

architecture Structural of ALUC is

component asb_ise is
    Port ( a : in STD_LOGIC_VECTOR (7 downto 0);
           sr : in STD_LOGIC_VECTOR (7 downto 0);
           sr_out : out STD_LOGIC_VECTOR (7 downto 0);
           result : out STD_LOGIC_VECTOR (7 downto 0);
           w : out STD_LOGIC
    );
end component;

component aib_ise is
    Port ( a : in STD_LOGIC_VECTOR (7 downto 0);
           sr : in STD_LOGIC_VECTOR (7 downto 0);
           sr_out : out STD_LOGIC_VECTOR (7 downto 0);
           result : out STD_LOGIC_VECTOR (7 downto 0);
           w : out STD_LOGIC
    );
end component;

component amc_ise is
    Port (  clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            start : in STD_LOGIC;
            a : in STD_LOGIC_VECTOR (7 downto 0);
            b : in STD_LOGIC_VECTOR (7 downto 0);
            sr : in STD_LOGIC_VECTOR (7 downto 0);
            sr_out : out STD_LOGIC_VECTOR (7 downto 0);
            result : out STD_LOGIC_VECTOR (7 downto 0);
            wait_req : out STD_LOGIC
    );
end component;

component aic_ise is
    Port (  clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            start : in STD_LOGIC;
            a : in STD_LOGIC_VECTOR (7 downto 0);
            b : in STD_LOGIC_VECTOR (7 downto 0);
            sr : in STD_LOGIC_VECTOR (7 downto 0);
            sr_out : out STD_LOGIC_VECTOR (7 downto 0);
            result : out STD_LOGIC_VECTOR (7 downto 0);
            wait_req : out STD_LOGIC
    );
end component;
    
component swd_ise is
    Port (  clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            start : in STD_LOGIC;
            a : in STD_LOGIC_VECTOR (7 downto 0);
            b : in STD_LOGIC_VECTOR (7 downto 0);
            sr : in STD_LOGIC_VECTOR (7 downto 0);
            sr_out : out STD_LOGIC_VECTOR (7 downto 0);
            result : out STD_LOGIC_VECTOR (7 downto 0);
            wait_req : out STD_LOGIC
    );
end component;

component gsp_ise is
    Port (  clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            start : in STD_LOGIC;
            a : in STD_LOGIC_VECTOR (7 downto 0);
            b : in STD_LOGIC_VECTOR (7 downto 0);
            sr : in STD_LOGIC_VECTOR (7 downto 0);
            sr_out : out STD_LOGIC_VECTOR (7 downto 0);
            result : out STD_LOGIC_VECTOR (7 downto 0);
            wait_req : out STD_LOGIC
    );
end component;

component gip_ise is
    Port (  clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            start : in STD_LOGIC;
            a : in STD_LOGIC_VECTOR (7 downto 0);
            b : in STD_LOGIC_VECTOR (7 downto 0);
            sr : in STD_LOGIC_VECTOR (7 downto 0);
            sr_out : out STD_LOGIC_VECTOR (7 downto 0);
            result : out STD_LOGIC_VECTOR (7 downto 0);
            wait_req : out STD_LOGIC
    );
end component;

signal start0, start1, start2, start3, start4,
    start5, start6 : STD_LOGIC;
    
signal sr_out0, sr_out1, sr_out2, sr_out3,
    sr_out4, sr_out5, sr_out6 : STD_LOGIC_VECTOR (7 downto 0);
    
signal result0, result1, result2, result3,
    result4, result5, result6 : STD_LOGIC_VECTOR (7 downto 0);
    
signal wait_req0, wait_req1, wait_req2, wait_req3, wait_req4,
    wait_req5, wait_req6 : STD_LOGIC;
begin

start0 <= '1' when start = '1' and opc2 = x"0" else '0';
start1 <= '1' when start = '1' and opc2 = x"1" else '0';
start2 <= '1' when start = '1' and opc2 = x"2" else '0';
start3 <= '1' when start = '1' and opc2 = x"3" else '0';
start4 <= '1' when start = '1' and opc2 = x"4" else '0';
start5 <= '1' when start = '1' and opc2 = x"5" else '0';
start6 <= '1' when start = '1' and opc2 = x"6" else '0';

-------------------------------------------------------------------------------
-- ENTER ISE MODULES HERE
-- CHOOSE ISE opc2 value x (0 through 15)
-- connect clk, rst, {a or Im}, b, sr to module
-- connect startx, sr_outx, resultx, and wait_reqx to module

-- opc2 = 0
asb: asb_ise
    port map (
        a => a,
        sr => sr,
        sr_out => sr_out0,
        result => result0,
        w => wait_req0
    );
     
---- opc2 = 1
--aib: aib_ise
--    port map (
--        a => a,
--        sr => sr,
--        sr_out => sr_out1,
--        result => result1,
--        w => wait_req1
--    );

-- opc2 = 2
amc: amc_ise
    port map (
        clk => clk,
        rst => rst,
        start => start2,
        a => a,
        b => b,
        sr => sr,
        sr_out => sr_out2,
        result => result2,
        wait_req => wait_req2
    );
    
---- opc2 = 3
--aic: aic_ise
--    port map (
--        clk => clk,
--        rst => rst,
--        start => start3,
--        a => a,
--        b => b,
--        sr => sr,
--        sr_out => sr_out3,
--        result => result3,
--        wait_req => wait_req3
--    );

-- opc2 = 4
swd: swd_ise
    port map (
        clk => clk,
        rst => rst,
        start => start4,
        a => a,
        b => b,
        sr => sr,
        sr_out => sr_out4,
        result => result4,
        wait_req => wait_req4
    );
    
-- opc2 = 5
gsp: gsp_ise
    port map (
        clk => clk,
        rst => rst,
        start => start5,
        a => a,
        b => b,
        sr => sr,
        sr_out => sr_out5,
        result => result5,
        wait_req => wait_req5
    );
    
---- opc2 = 6
--gip: gip_ise
--    port map (
--        clk => clk,
--        rst => rst,
--        start => start6,
--        a => a,
--        b => b,
--        sr => sr,
--        sr_out => sr_out6,
--        result => result6,
--        wait_req => wait_req6
--    );
-------------------------------------------------------------------------------

with opc2 select
    sr_out <=   sr_out0 when x"0",
                --sr_out1 when x"1",
                sr_out2 when x"2",
                --sr_out3 when x"3",
                sr_out4 when x"4",
                sr_out5 when others; --when x"5",
                --sr_out6 when others;
                
with opc2 select
    result <=   result0 when x"0",
                result1 when x"1",
                result2 when x"2",
                result3 when x"3",
                result4 when x"4",
                result5 when x"5",
                result6 when others;
                
wait_req <= wait_req0 or
            --wait_req1 or
            wait_req2 or
            --wait_req3 or
            wait_req4 or
            wait_req5; --or
            -- wait_req6;
                    
end Structural;
