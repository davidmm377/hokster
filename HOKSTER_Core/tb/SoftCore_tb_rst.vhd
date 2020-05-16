----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: SoftCore_tb_rst - Behavioral
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

entity SoftCore_tb_rst is
--  Port ( );
end SoftCore_tb_rst;

architecture Behavioral of SoftCore_tb_rst is
signal clk : STD_LOGIC := '0';
signal rst : STD_LOGIC;

signal start : STD_LOGIC;
signal extpaddr : STD_LOGIC_VECTOR (11 downto 0);
signal extprogin : STD_LOGIC_VECTOR (7 downto 0);
signal extprogload : STD_LOGIC;

signal extdaddr : STD_LOGIC_VECTOR (15 downto 0);
signal extdin : STD_LOGIC_VECTOR (7 downto 0);
signal extdataload : STD_LOGIC;
signal extdaddrsel : STD_LOGIC;

signal auxdout : STD_LOGIC_VECTOR (7 downto 0);
signal auxdoutsel : STD_LOGIC;
signal auxdin : STD_LOGIC_VECTOR (7 downto 0);
signal auxdaddr : STD_LOGIC_VECTOR (15 downto 0);

signal ibus : STD_LOGIC_VECTOR (15 downto 0);

signal sbus : STD_LOGIC_VECTOR (7 downto 0);
signal extdout : STD_LOGIC_VECTOR (7 downto 0);

begin

uut: entity work.SoftCore(Structural)
    generic map ( G_DATA_BUS_WIDTH => 8,
              G_PMEM_SIZE => 8,
              G_DMEM_SIZE => 8
    )
    port map ( clk => clk,
           rst => rst,
           
           start => start,
           extpaddr => extpaddr,
           extprogin => extprogin,
           extprogload => extprogload,
           
           extdaddr => extdaddr,
           extdin => extdin,
           extdataload => extdataload,
           extdaddrsel => extdaddrsel,
           
           auxdout => auxdout,
           auxdoutsel => auxdoutsel,
           auxdin => auxdin,
           auxdaddr => auxdaddr,
           
           ibus => ibus,
           
           sbus => sbus,
           extdout => extdout
    );

clk <= not clk after 4 ns;

process
begin
    wait for 8 ns;
    rst <= '1';
    wait for 8 ns;
    rst <= '0';
    
    -- pc should not be updating
    wait for 128 ns;
    
    start <= '1';
    wait for 8 ns;
    start <= '0';
    
    -- pc should be updating
    wait for 128 ns;
    
    rst <= '1';
    wait for 8 ns;
    rst <= '0';
    
    -- pc should not be updating
    wait;
end process;

end Behavioral;
