----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Module Name: SoftCore - Structural
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
use work.SoftCoreConstants.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SoftCore is
    Generic ( G_DATA_BUS_WIDTH : integer := 8; -- Default d-bus width is 8 bits
              G_PMEM_SIZE      : integer := 8; -- Default program memory size is 2^8 bytes
              G_DMEM_SIZE      : integer := 8; -- Default data memory size is 2^8 bytes
              G_NUM_SHDW_REGS : integer := 2;  -- Default number of pairs of saved registers is 2
              G_NUM_IV_REGS : integer := 4     -- Default number of IV registers is 4
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           start : in STD_LOGIC;
           extpaddr : in STD_LOGIC_VECTOR (11 downto 0);
           extprogin : in STD_LOGIC_VECTOR (7 downto 0);
           extprogload : in STD_LOGIC;
           
           extdaddr : in STD_LOGIC_VECTOR (15 downto 0);
           extdin : in STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
           extdataload : in STD_LOGIC;
           extdaddrsel : in STD_LOGIC;
           
           auxdout : in STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
           auxdoutsel : in STD_LOGIC;
           auxdin : out STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
           auxdaddr : out STD_LOGIC_VECTOR (15 downto 0);
           
           ibus : in STD_LOGIC_VECTOR (15 downto 0);
           
           sbus : out STD_LOGIC_VECTOR (7 downto 0);
           extdout : out STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0)
    );
end SoftCore;

architecture Structural of SoftCore is

signal progword : STD_LOGIC_VECTOR (7 downto 0);
signal lastprogword : STD_LOGIC_VECTOR (7 downto 0);

signal sr : STD_LOGIC_VECTOR (7 downto 0);

signal PCsel : PCselType;
signal SPsel : SPselType;
signal SRsel : SRselType;

signal daddrsel : daddrselType;
signal dinsel : dinselType;
signal dwe: STD_LOGIC;

signal gpr_addr1 : STD_LOGIC_VECTOR (3 downto 0);
signal gpr_write1 : STD_LOGIC;
signal gpr_wdata1sel : wdata1selType;

signal gpr_addr2 : STD_LOGIC_VECTOR (3 downto 0);
signal gpr_write2 : STD_LOGIC;
signal gpr_wdata2sel : wdata2selType;

signal gpr_pairaddr : STD_LOGIC_VECTOR (2 downto 0);

signal alu_asel : alu_aselType;

signal aluc_start : STD_LOGIC;
signal wait_req : STD_LOGIC;

signal iesel : ieselType;
signal ie : STD_LOGIC_VECTOR (15 downto 0);

signal iv_addr : STD_LOGIC_VECTOR (3 downto 0);
signal iv_wdata : STD_LOGIC_VECTOR (7 downto 0);
signal iv_write : STD_LOGIC;

signal load_shadow : STD_LOGIC;
signal unload_shadow : STD_LOGIC;
begin

soft_core_data_path: entity work.Datapath(Structural)
    generic map(
        G_DATA_BUS_WIDTH => G_DATA_BUS_WIDTH,
        G_PMEM_SIZE => G_PMEM_SIZE,
        G_DMEM_SIZE => G_DMEM_SIZE,
        G_NUM_SHDW_REGS => G_NUM_SHDW_REGS,
        G_NUM_IV_REGS => G_NUM_IV_REGS
    )
    
    port map(
        clk => clk,
        rst => rst,
        
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
        
        extdout => extdout,
        
        progword => progword,
        lastprogword => lastprogword,
        
        sr_out => sr,
        
        PCsel => PCsel,
        SPsel => SPsel,
        SRsel => SRsel,
        
        daddrsel => daddrsel,
        dinsel => dinsel,
        dwe => dwe,
        
        gpr_addr1 => gpr_addr1,
        gpr_write1 => gpr_write1,
        gpr_wdata1sel => gpr_wdata1sel,
        
        gpr_addr2 => gpr_addr2,
        gpr_write2 => gpr_write2,
        gpr_wdata2sel => gpr_wdata2sel,
        
        gpr_pairaddr => gpr_pairaddr,
        
        alu_asel => alu_asel,
        
        aluc_start => aluc_start,
        wait_req => wait_req,
        
        iesel => iesel,
        ie => ie,
        
        iv_addr => iv_addr,
        iv_wdata => iv_wdata,
        iv_write => iv_write,
        
        load_shadow => load_shadow,
        unload_shadow => unload_shadow
    );
    
soft_core_controller: entity work.Controller(Behavioral)
    port map(
        clk => clk,
        rst => rst,
       
        start => start,
        
        ibus => ibus,
        
        sbus => sbus,
        
        progword => progword,
        lastprogword => lastprogword,
        
        sr => sr,
        
        PCsel => PCsel,
        SPsel => SPsel,
        SRsel => SRsel,
        
        daddrsel => daddrsel,
        dinsel => dinsel,
        dwe => dwe,
        
        gpr_addr1 => gpr_addr1,
        gpr_write1 => gpr_write1,
        gpr_wdata1sel => gpr_wdata1sel,
        
        gpr_addr2 => gpr_addr2,
        gpr_write2 => gpr_write2,
        gpr_wdata2sel => gpr_wdata2sel,
        
        gpr_pairaddr => gpr_pairaddr,
        
        alu_asel => alu_asel,
        
        aluc_start => aluc_start,
        wait_req => wait_req,
        
        iesel => iesel,
        ie => ie,
        
        iv_addr => iv_addr,
        iv_wdata => iv_wdata,
        iv_write => iv_write,
        
        load_shadow => load_shadow,
        unload_shadow => unload_shadow
    );
    
end Structural;
