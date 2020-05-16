----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: loader_controller - Behavioral
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: based on loader_controller from SoftCore by William Diehl
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

entity loader_controller is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           progloadend	  : in STD_LOGIC;
           progload : out STD_LOGIC;
           
           dataloadend   : in STD_LOGIC;
           dataload : out STD_LOGIC;
           
           datareadend   : in STD_LOGIC;
           dataread : out STD_LOGIC;
           
           runend	:  in STD_LOGIC;
           runstart : out STD_LOGIC);
end loader_controller;

architecture Behavioral of loader_controller is
type Loader_State_Type is (LOAD_PROG, LOAD_DATA, START, RUN, READ_DATA, IDLE);
signal loader_state : Loader_State_Type;

begin

process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            loader_state <= LOAD_PROG;
        else
            case loader_state is
                when LOAD_PROG =>
                    if progloadend = '1' then
                        loader_state <= LOAD_DATA;
                    end if;
                when LOAD_DATA =>
                    if dataloadend = '1' then
                        loader_state <= START;
                    end if;
                when START =>
                    loader_state <= RUN;
                when RUN =>
                    if runend = '1' then
                        loader_state <= READ_DATA;
                    end if;
                when READ_DATA =>
                    if datareadend = '1' then
                        loader_state <= IDLE;
                    end if;
                when others => loader_state <= IDLE;
            end case;
        end if;
    end if;
end process;

progload <= '1' when (loader_state = LOAD_PROG) else '0';
dataload <= '1' when (loader_state = LOAD_DATA) else '0';
runstart <= '1' when (loader_state = START) else '0';
dataread <= '1' when (loader_state = READ_DATA) else '0';

end Behavioral;
