----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: loader_tb_isr - Behavioral
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity loader_tb_isr is
--  Port ( );
end loader_tb_isr;

architecture Behavioral of loader_tb_isr is

constant G_DATA_BUS_WIDTH : integer := 8;

signal clk : STD_LOGIC := '0';
signal rst : STD_LOGIC;
signal done : STD_LOGIC;
signal extdout : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);

begin

uut: entity work.loader_isr(Structural)
    generic map (
        G_DATA_BUS_WIDTH => G_DATA_BUS_WIDTH,
        G_PMEM_SIZE => 8,
        G_DMEM_SIZE => 8,
        PROG_LOAD_SIZE => 8,
        PROG_FILE => "isr_prog.hex",
        DATA_LOAD_SIZE => 8,
        DATA_FILE => "isr_data.hex",
        END_READ_LOC => x"0010"
    )
    port map ( clk => clk,
        rst => rst,
        done => done,
        extdout => extdout
    );
    
clk <= not clk after 4 ns;

init_process: process
begin
    rst <= '1';
    wait for 4 ns;
    rst <= '0';
    
    wait;
end process;

end Behavioral;
