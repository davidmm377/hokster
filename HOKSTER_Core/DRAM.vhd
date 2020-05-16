

-------------------------------------------------------------------------------
--! @file       DRAM.vhd
--! @author     William Diehl
--! @brief      SoftCore
--! @date       9 Sep 2016
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DRAM is

generic( 
	 MEM_SIZE : integer :=16
	 );

PORT(
        clk:IN STD_LOGIC;
        we: IN STD_LOGIC;
        di: IN STD_LOGIC_VECTOR(7 downto 0);
        do: OUT STD_LOGIC_VECTOR(7 downto 0);
        addr:IN STD_LOGIC_VECTOR(MEM_SIZE-1 downto 0)
		);
end DRAM;

architecture behavioral of DRAM is
type ram_type is array (0 to 2**mem_size - 1 ) of std_logic_vector(7 downto 0);
signal RAM:ram_type :=(others=>(others=>'0'));
begin
  process(clk)
   begin
      if rising_edge(clk) then
		  if (we='1')then
		    RAM(to_integer(unsigned(addr(mem_size - 1 downto 0))))<=di;
		  end if;
		 end if;
		end process;
	 do<= RAM(to_integer(unsigned(addr(mem_size - 1 downto 0))));
end behavioral;

