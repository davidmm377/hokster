----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: loader - Structural
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: based on loader from SoftCore by William Diehl
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

entity loader_isr is
    Generic (
        -- Default d-bus width is 8 bits
        G_DATA_BUS_WIDTH    : integer := 8;
        
        -- Default program memory size is 2^8 bytes
        G_PMEM_SIZE         : integer := 8;
        
        -- Default data memory size is 2^8 bytes
        G_DMEM_SIZE         : integer := 8;
        
        -- Size of program buffer in loader 2^PROG_LOAD_SIZE
        PROG_LOAD_SIZE      : integer := 8;
        
        -- Name of file containing program
        PROG_FILE : string := "GCD_prog.hex";
        
        -- Size of data buffer in loader 2^DATA_LOAD_SIZE
        DATA_LOAD_SIZE : integer := 8;
        
        -- Name of file containing data
        DATA_FILE : string := "GCD_data.hex";
        
         -- Last data address to read out
        END_READ_LOC : STD_LOGIC_VECTOR(15 downto 0) := x"0010"
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           done : out STD_LOGIC;
           extdout : out STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0)
    );
end loader_isr;

architecture Structural of loader_isr is

-- CONSTANTS
constant PZEROS : STD_LOGIC_VECTOR(11 - PROG_LOAD_SIZE downto 0) := (OTHERS => '0');
constant DZEROS : STD_LOGIC_VECTOR(15 - DATA_LOAD_SIZE downto 0) := (OTHERS => '0');

-- SOFT CORE SIGNALS
signal start : STD_LOGIC;
signal extpaddr : STD_LOGIC_VECTOR (11 downto 0);
signal extprogin : STD_LOGIC_VECTOR (7 downto 0);
signal extprogload : STD_LOGIC;

signal extdaddr : STD_LOGIC_VECTOR (15 downto 0);
signal extdin : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
signal extdataload : STD_LOGIC;
signal extdaddrsel : STD_LOGIC;

signal auxdout : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
signal auxdoutsel : STD_LOGIC;
signal auxdin : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
signal auxdaddr : STD_LOGIC_VECTOR (15 downto 0);

signal ibus : STD_LOGIC_VECTOR (15 downto 0);

signal sbus : STD_LOGIC_VECTOR (7 downto 0);

-- PROGRAM LOAD
signal extpaddrshort, extpaddrshortnext : STD_LOGIC_VECTOR (PROG_LOAD_SIZE-1 downto 0);
signal progloadend : STD_LOGIC;
 
-- DATA LOAD
signal extdaddrloadshort, extdaddrloadshortnext : STD_LOGIC_VECTOR (DATA_LOAD_SIZE-1 downto 0);
signal dataloadend : STD_LOGIC;

-- RUN
signal runend : STD_LOGIC;

-- DATA READ
signal extdaddrreadshort, extdaddrreadshortnext : STD_LOGIC_VECTOR (DATA_LOAD_SIZE-1 downto 0);
signal datareadend : STD_LOGIC;
signal dataread : STD_LOGIC;

begin 

-- catch loading programs larger than memory supports during simulation
assert (G_PMEM_SIZE >= PROG_LOAD_SIZE);
assert (G_DMEM_SIZE >= DATA_LOAD_SIZE);

-- SOFTCORE

extpaddr <= PZEROS & extpaddrshort;
extdaddr <= (DZEROS & extdaddrloadshort) when extdataload = '1' else
            (DZEROS & extdaddrreadshort);
            
extdaddrsel <= extdataload or dataread;

softcore: entity work.SoftCore(Structural)
    generic map ( G_DATA_BUS_WIDTH => G_DATA_BUS_WIDTH,
              G_PMEM_SIZE => G_PMEM_SIZE,
              G_DMEM_SIZE => G_DMEM_SIZE
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

runend <= '1' when sbus = x"FF" else '0';
done <= runend;

-- LOAD AND READ COUNTERS

extpaddrshortnext <= STD_LOGIC_VECTOR(UNSIGNED(extpaddrshort) + 1)
    when (extprogload = '1' and progloadend = '0') else extpaddrshort;

progloadcntr: entity work.regn(behavioral)
    generic map(N => PROG_LOAD_SIZE)
    port map(
        d => extpaddrshortnext,
        clk => clk,
        rst => rst,
        q => extpaddrshort
    );

extdaddrloadshortnext <= STD_LOGIC_VECTOR(UNSIGNED(extdaddrloadshort) + 1)
    when (extdataload = '1' and dataloadend = '0') else extdaddrloadshort;

dataloadcntr: entity work.regn(behavioral)
    generic map(N => DATA_LOAD_SIZE)
    port map(
        d => extdaddrloadshortnext,
        clk => clk,
        rst => rst,
        q => extdaddrloadshort
    );

extdaddrreadshortnext <= STD_LOGIC_VECTOR(UNSIGNED(extdaddrreadshort) + 1)
    when (dataread = '1' and datareadend = '0') else extdaddrreadshort;
 
datareadcntr: entity work.regn(behavioral)
    generic map(N => DATA_LOAD_SIZE)
    port map(
        d => extdaddrreadshortnext,
        clk => clk,
        rst => rst,
        q => extdaddrreadshort
	);

-- PROG AND DATA LOADERS

prog: entity work.fileloader(Dataflow)
    generic map ( 
        LOADER_SIZE => PROG_LOAD_SIZE,
        FILE_NAME => PROG_FILE
    )
    port map (
        addr => extpaddrshort,
        dout => extprogin,
        done => progloadend
    );
    
data: entity work.fileloader(Dataflow)
    generic map (
        LOADER_SIZE => DATA_LOAD_SIZE,
        FILE_NAME => DATA_FILE
    )
    port map ( addr => extdaddrloadshort,
        dout => extdin,
        done => dataloadend
    );
    
-- CONTROLLER

datareadend <= '1' when extdaddr = END_READ_LOC else '0';

controller: entity work.loader_controller(Behavioral)
    port map ( clk => clk,
        rst => rst,
        progloadend => progloadend,
        progload => extprogload,
       
        dataloadend => dataloadend,
        dataload => extdataload,
       
        datareadend => datareadend,
        dataread => dataread,
       
        runend	=> runend,
        runstart => start
    );
    
-- Cause interrupt after a short time
isr_process: process
begin
    ibus <= x"0000";
    wait for 1000 ns;
    ibus <= x"0002";
    wait until sbus = x"01";
    ibus <= x"0000";
    
    wait;
end process;

end Structural;
