----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: lwc_loader_controller - Behavioral
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: State and control logic of the lwc_loader
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.SoftCoreConstants.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lwc_loader_controller is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           count : in STD_LOGIC_VECTOR (3 downto 0);
           start : in STD_LOGIC;
           header : in headerType;
           
           ready : out STD_LOGIC;
           clear_counter : out STD_LOGIC;
           enable_counter : out STD_LOGIC;
           
           progloadend : in STD_LOGIC;
           progload : out STD_LOGIC;
           
           dataloadend : in STD_LOGIC;
           dataload : out STD_LOGIC;
           
           plaintextload : out STD_LOGIC;
           keyload : out STD_LOGIC;
           cipherload : out STD_LOGIC;
           
           runend : in STD_LOGIC;
           runstart : out STD_LOGIC;
           
           dataread : out STD_LOGIC);
end lwc_loader_controller;

architecture Behavioral of lwc_loader_controller is

type Loader_State_Type is (IDLE, LOAD_PROG, LOAD_DATA,
    LOAD_KEY, LOAD_PLAINTEXT, START_CORE, RUN, READ_DATA);
signal loader_state : Loader_State_Type;

begin

process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            loader_state <= IDLE;
        else
            case loader_state is
                when IDLE =>
                    if start = '1' then
                        case header is
                            when HEADER_CIPHER =>
                                loader_state <= LOAD_PROG;
                            when HEADER_KEY =>
                                loader_state <= LOAD_KEY;
                            when HEADER_PLAINTEXT =>
                                loader_state <= LOAD_PLAINTEXT;
                            when others =>
                                loader_state <= IDLE;
                        end case;
                    end if;
                when LOAD_PROG =>
                    if progloadend = '1' then
                        loader_state <= LOAD_DATA;
                    end if;
                when LOAD_DATA =>
                    if dataloadend = '1' then
                        loader_state <= IDLE;
                    end if;
                when LOAD_KEY =>
                    if count = x"F" then
                        loader_state <= IDLE;
                    end if;
                when LOAD_PLAINTEXT =>
                    if count = x"F" then
                        loader_state <= START_CORE;
                    end if;
                when START_CORE =>
                    loader_state <= RUN;
                when RUN =>
                    if runend = '1' then
                        loader_state <= READ_DATA;
                    end if;
                when READ_DATA =>
                    if count = x"F" then
                        loader_state <= IDLE;
                    end if;
                when others => loader_state <= IDLE;
            end case;
        end if;
    end if;
end process;

ready <= '1' when
    (loader_state = IDLE  and start = '1') or
    loader_state = LOAD_KEY or
    loader_state = LOAD_PLAINTEXT
    else '0';
    
clear_counter <= '1' when loader_state = IDLE and
    (start = '0' or header = HEADER_CIPHER)
    else '0';

enable_counter <= '1' when
    (loader_state = IDLE and start = '1' and header /= HEADER_CIPHER) or
    loader_state = LOAD_KEY or
    loader_state = LOAD_PLAINTEXT or
    loader_state = READ_DATA
    else '0';
    
cipherload <= '1' when
    loader_state = IDLE and start = '1' and header = HEADER_CIPHER
    else '0';
    
progload <= '1' when loader_state = LOAD_PROG else '0';

dataload <= '1' when loader_state = LOAD_DATA else '0';

plaintextload <= '1' when
    (loader_state = IDLE and start = '1' and header = HEADER_PLAINTEXT) or
    loader_state = LOAD_PLAINTEXT
    else '0';
    
keyload <= '1' when
    (loader_state = IDLE and start = '1' and header = HEADER_KEY) or
    loader_state = LOAD_KEY
    else '0';
    
runstart <= '1' when loader_state = START_CORE else '0';

dataread <= '1' when loader_state = READ_DATA else '0';

end Behavioral;
