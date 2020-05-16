----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: InterruptController_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity InterruptController_tb is
--  Port ( );
end InterruptController_tb;

architecture Behavioral of InterruptController_tb is
signal clk : STD_LOGIC := '0';
signal rst : STD_LOGIC;

signal enable_update : STD_LOGIC;
signal exit_interrupt : STD_LOGIC;

signal ibus : STD_LOGIC_VECTOR (15 downto 0);
signal ie : STD_LOGIC_VECTOR (15 downto 0);

signal interrupt : STD_LOGIC;
signal vector : STD_LOGIC_VECTOR (3 downto 0);

begin

uut: entity work.InterruptController(Behavioral)
    port map(
        clk => clk,
        rst => rst,
        
        enable_update => enable_update,
        exit_interrupt => exit_interrupt,
       
        ibus => ibus,
        ie => ie,
       
        interrupt => interrupt,
        vector => vector
    );

clk <= not clk after 4 ns;

process
begin
    -- initial values
    enable_update <= '0';
    exit_interrupt <= '0';
    ibus <= x"0200";
    ie <= x"0200";
    
    -- reset controller
    rst <= '1';
    wait for 8 ns;
    rst <= '0';
    wait for 8 ns;
    
    -- check initial state
    assert(interrupt = '0');
    assert(vector = x"0");
    wait for 8 ns;
    
    -- enable interrupt processing
    enable_update <= '1';
    wait for 4 ns;
    -- interrupt is present on line i9
    assert(interrupt = '1');
    assert(vector = x"9");
    wait for 4 ns;
    
    -- after 1 cycle, interrupt controller moves to an interrupt state
    -- it should no longer outputs the interrupt signal
    assert(interrupt = '0');
    assert(vector = x"0");
    wait for 8 ns;
    
    enable_update <= '0';
    wait for 64 ns;
    assert(interrupt = '0');
    assert(vector = x"0");
    wait for 8 ns;
    
    -- interrupt is cleared
    ibus <= x"0000";
    wait for 4 ns;
    assert(interrupt = '0');
    assert(vector = x"0");
    wait for 4 ns;    
        
    -- exit the interrupt    
    exit_interrupt <= '1';
    wait for 8 ns;
    
    exit_interrupt <= '0';
    assert(interrupt = '0');
    assert(vector = x"0");
    wait for 8 ns;
    
    -- unenabled interrupt comes in
    ibus <= x"0001";
    wait for 4 ns;
    -- interrupt does not occur
    assert(interrupt = '0');
    assert(vector = x"0");
    wait for 4 ns;
    
    assert(interrupt = '0');
    assert(vector = x"0");
    wait for 8 ns;
    
    -- TEST PRIORITY
    ibus <= x"0000";
    wait for 4 ns;
    assert(interrupt = '0');
    assert(vector = x"0");
    wait for 4 ns;
    
    -- accept multiple interrupts
    ie <= x"0202";
    wait for 8 ns;
    
    -- multiple interrupts occur
    -- i1 has priority
    ibus <= x"0202";
    enable_update <= '1';
    wait for 4 ns;
    assert(interrupt = '1');
    assert(vector = x"1");
    wait for 4 ns;
    
    wait;
end process;

end Behavioral;
