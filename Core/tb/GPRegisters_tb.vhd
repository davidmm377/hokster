----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: GPRegisters_tb - Behavioral
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

entity GPRegisters_tb is
--  Port ( );
end GPRegisters_tb;

architecture Behavioral of GPRegisters_tb is
signal clk : STD_LOGIC :='0';
signal rst : STD_LOGIC;
signal gpr_addr1 : STD_LOGIC_VECTOR (3 downto 0);
signal gpr_wdata1 : STD_LOGIC_VECTOR (7 downto 0);
signal gpr_write1 : STD_LOGIC;
signal gpr_out1 : STD_LOGIC_VECTOR (7 downto 0);

signal gpr_addr2 : STD_LOGIC_VECTOR (3 downto 0);
signal gpr_wdata2 : STD_LOGIC_VECTOR (7 downto 0);
signal gpr_write2 : STD_LOGIC;
signal gpr_out2 : STD_LOGIC_VECTOR (7 downto 0);

signal gpr_pairaddr : STD_LOGIC_VECTOR (2 downto 0);
signal gpr_pairout : STD_LOGIC_VECTOR (15 downto 0);

begin

uut: entity work.GPRegisters(Structural)
    port map(
        clk => clk,
        rst => rst,
        
        load_shadow => '0',
        unload_shadow => '0',
        
        addr1 => gpr_addr1,
        wdata1 => gpr_wdata1,
        write1 => gpr_write1,
        out1 => gpr_out1,
       
        addr2 => gpr_addr2,
        wdata2 => gpr_wdata2,
        write2 => gpr_write2,
        out2 => gpr_out2,
       
        pairaddr => gpr_pairaddr,
        pairout => gpr_pairout
    );

clk <= not clk after 4 ns;

process
begin
    rst <= '1';
    wait for 8 ns;
    rst <= '0';
    wait for 8 ns;
    
    -- check all registers for reset values on both interfaces
    for i in 0 to 15 loop
        wait for 8 ns;
        gpr_addr1 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr1'length));
        gpr_addr2 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr2'length));
        assert((gpr_out1 = "00000000") and (gpr_out2 = "00000000"));
    end loop;
    for i in 0 to 7 loop
        wait for 8 ns;
        gpr_pairaddr <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_pairaddr'length));
        assert(gpr_pairout = x"0000");
    end loop;
    for i in 0 to 7 loop
        wait for 4 ns;
        gpr_pairaddr <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_pairaddr'length));
        wait for 4 ns;
        assert(gpr_pairout = x"0000");
    end loop;
    
    -- check writing values to registers through interface 1
    gpr_wdata1 <= x"FF";
    for i in 0 to 15 loop
        gpr_write1 <= '1';
        gpr_addr1 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr1'length));
        wait for 8 ns;
    end loop;
    gpr_write1 <= '0';
    for i in 0 to 15 loop
        wait for 4 ns;
        gpr_addr1 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr1'length));
        gpr_addr2 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr2'length));
        wait for 4 ns;
        assert((gpr_out1 = x"FF") and (gpr_out2 = x"FF"));
    end loop;
    for i in 0 to 7 loop
        wait for 4 ns;
        gpr_pairaddr <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_pairaddr'length));
        wait for 4 ns;
        assert(gpr_pairout = x"FFFF");
    end loop;
    wait for 8 ns;
    
    -- check writing values to registers through interface 2
    gpr_wdata2 <= x"DE";
    for i in 0 to 15 loop
        gpr_write2 <= '1';
        gpr_addr2 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr2'length));
        wait for 8 ns;
    end loop;
    gpr_write2 <= '0';
    for i in 0 to 15 loop
        wait for 4 ns;
        gpr_addr1 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr1'length));
        gpr_addr2 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr2'length));
        wait for 4 ns;
        assert((gpr_out1 = x"DE") and (gpr_out2 = x"DE"));
    end loop;
    for i in 0 to 7 loop
        wait for 4 ns;
        gpr_pairaddr <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_pairaddr'length));
        wait for 4 ns;
        assert(gpr_pairout = x"DEDE");
    end loop;
    wait for 8 ns;
    
    -- check all registers for reset values on both interfaces
    rst <= '1';
    wait for 8 ns;
    rst <= '0';
    wait for 8 ns;
    
    for i in 0 to 15 loop
        wait for 8 ns;
        gpr_addr1 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr1'length));
        gpr_addr2 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr2'length));
        assert((gpr_out1 = "00000000") and (gpr_out2 = "00000000"));
    end loop;
    for i in 0 to 7 loop
        wait for 4 ns;
        gpr_pairaddr <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_pairaddr'length));
        wait for 4 ns;
        assert(gpr_pairout = x"0000");
    end loop;
    wait for 8 ns;
    
    -- check writing and reading different registers at the same time on different interfaces
    gpr_wdata1 <= x"1f";
    gpr_wdata2 <= x"20";
    for i in 0 to 7 loop
        gpr_write1 <= '1';
        gpr_write2 <= '1';
        gpr_addr1 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr1'length));
        gpr_addr2 <= STD_LOGIC_VECTOR(to_unsigned(i+8, gpr_addr2'length));
        wait for 8 ns;
    end loop;
    gpr_write1 <= '0';
    gpr_write2 <= '0';
    for i in 0 to 7 loop
        wait for 4 ns;
        gpr_addr1 <= STD_LOGIC_VECTOR(to_unsigned(i+8, gpr_addr1'length));
        gpr_addr2 <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_addr2'length));
        wait for 4 ns;
        assert((gpr_out1 = x"20") and (gpr_out2 = x"1f"));
    end loop;
    for i in 0 to 7 loop
        wait for 4 ns;
        gpr_pairaddr <= STD_LOGIC_VECTOR(to_unsigned(i, gpr_pairaddr'length));
        wait for 4 ns;
        assert(gpr_pairout = x"201f");
    end loop;
    wait for 8 ns;
    
    -- check writing with all interfaces at once
    gpr_wdata1 <= x"35";
    gpr_wdata2 <= x"36";
    
    gpr_addr1 <= "0000";
    gpr_addr2 <= "1000";
    gpr_pairaddr <= "010";
    
    gpr_write1 <= '1';
    gpr_write2 <= '1';
    wait for 8 ns;
    
    gpr_write1 <= '0';
    gpr_write2 <= '0';
    gpr_pairaddr <= "000";
    wait for 4 ns;
    assert(gpr_pairout = x"3635");
    
    wait;
end process;

end Behavioral;
