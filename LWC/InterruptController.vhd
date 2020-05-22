----------------------------------------------------------------------------------
-- Engineer: Tom Conroy
-- Module Name: InterruptController - Behavioral
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

entity InterruptController is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        
        enable_update : in STD_LOGIC;
        exit_interrupt : in STD_LOGIC;
        
        ibus : in STD_LOGIC_VECTOR (15 downto 0);
        ie : in STD_LOGIC_VECTOR (15 downto 0);
        
        interrupt : out STD_LOGIC;
        vector : out STD_LOGIC_VECTOR (3 downto 0)
    );
end InterruptController;

architecture Behavioral of InterruptController is

signal interrupt_internal : STD_LOGIC;
signal in_interrupt : STD_LOGIC;

begin

process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            in_interrupt <= '0';
        else
            case in_interrupt is
                when '0' =>
                    if enable_update = '1' and interrupt_internal = '1' then
                        in_interrupt <= '1';
                    end if;
                when '1' =>
                    if exit_interrupt = '1' then
                        in_interrupt <= '0';
                    end if;
                when others => in_interrupt <= '0';
            end case;
        end if;
    end if;
end process;

-- priority encoder
process (in_interrupt, enable_update, ibus, ie)
begin
    -- default assignments
    interrupt_internal <= '0';
    vector <= "0000";
    
    if in_interrupt = '0' and enable_update = '1' then
        for I in 15 downto 0 loop
            -- the lowest is the last one to be written, giving priority
            if ibus(I) = '1' and ie(I) = '1' then
                interrupt_internal <= '1';
                vector <= STD_LOGIC_VECTOR(to_unsigned(I, vector'length));
            end if;
        end loop;
    end if;
end process;

interrupt <= interrupt_internal;

end Behavioral;
