---------------------------------------------------------------------------------- 
-- Engineer: Tom Conroy

-- Module Name: Datapath - Structural
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Datapath is
    Generic ( G_DATA_BUS_WIDTH : integer := 8; -- Default d-bus width is 8 bits
              G_PMEM_SIZE      : integer := 8; -- Default program memory size is 2^8 bytes
              G_DMEM_SIZE      : integer := 8; -- Default data memory size is 2^8 bytes
              G_NUM_SHDW_REGS : integer := 2;  -- Default number of saved registers is 2
              G_NUM_IV_REGS : integer := 4     -- Default number of IV registers is 4
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
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
           
           extdout : out STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
           
           progword : out STD_LOGIC_VECTOR (7 downto 0);
           lastprogword : out STD_LOGIC_VECTOR (7 downto 0);
           
           sr_out : out STD_LOGIC_VECTOR (7 downto 0);
           
           PCsel : in PCselType;
           SPsel : in SPselType;
           SRsel : in SRselType;
           
           daddrsel : in daddrselType;
           dinsel : in dinselType;
           dwe : in STD_LOGIC;
           
           gpr_addr1 : in STD_LOGIC_VECTOR (3 downto 0);
           gpr_write1 : in STD_LOGIC;
           gpr_wdata1sel : in wdata1selType;
           
           gpr_addr2 : in STD_LOGIC_VECTOR (3 downto 0);
           gpr_write2 : in STD_LOGIC;
           gpr_wdata2sel : in wdata2selType;
           
           gpr_pairaddr : in STD_LOGIC_VECTOR (2 downto 0);
           
           alu_asel : in alu_aselType;
           
           aluc_start : in STD_LOGIC;
           wait_req : out STD_LOGIC;
           
           iesel : in ieselType;
           ie: out STD_LOGIC_VECTOR (15 downto 0);
           
           iv_addr : in STD_LOGIC_VECTOR (3 downto 0);
           iv_wdata : in STD_LOGIC_VECTOR (7 downto 0);
           iv_write : in STD_LOGIC;
           
           load_shadow : in STD_LOGIC;
           unload_shadow : in STD_LOGIC
    );
end Datapath;

architecture Structural of Datapath is

signal data_we : STD_LOGIC;
signal din : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
signal dout : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
signal daddr : STD_LOGIC_VECTOR (15 downto 0);
signal dbus : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);

signal prog_out, lastprog_out : STD_LOGIC_VECTOR(7 downto 0);
signal nextlastprog_out : STD_LOGIC_VECTOR (7 downto 0);

signal paddr : STD_LOGIC_VECTOR(11 downto 0);

signal gpr_wdata1 : STD_LOGIC_VECTOR (7 downto 0);
signal gpr_out1 : STD_LOGIC_VECTOR (7 downto 0);

signal gpr_wdata2 : STD_LOGIC_VECTOR (7 downto 0);
signal gpr_out2 : STD_LOGIC_VECTOR (7 downto 0);

signal gpr_wdatapair : STD_LOGIC_VECTOR (15 downto 0);
signal gpr_pairout : STD_LOGIC_VECTOR (15 downto 0);

signal PC, PCnext : STD_LOGIC_VECTOR (11 downto 0);
signal SP, SPnext : STD_LOGIC_VECTOR (15 downto 0);
signal SR, SRnext : STD_LOGIC_VECTOR (7 downto 0);

signal alu_a : UNSIGNED (7 downto 0);
signal alu_out : UNSIGNED (7 downto 0);
signal alu_sr : STD_LOGIC_VECTOR (7 downto 0);

signal PC_plus_1 : STD_LOGIC_VECTOR (11 downto 0);
signal PC_plus_2 : STD_LOGIC_VECTOR (11 downto 0);

signal aluc_sr : STD_LOGIC_VECTOR (7 downto 0);
signal aluc_out : STD_LOGIC_VECTOR (7 downto 0);

signal IEinternal, IEnext : STD_LOGIC_VECTOR (15 downto 0);

signal IV : STD_LOGIC_VECTOR (7 downto 0);

signal PCS, PCSnext : STD_LOGIC_VECTOR (11 downto 0);
signal SRS, SRSnext : STD_LOGIC_VECTOR (7 downto 0);
begin

-- DATA MEMORY

daddr <=    extdaddr when extdaddrsel = '1' else
            x"0000" when daddrsel = daddr_zero else
            gpr_pairout when daddrsel = daddr_reg else
            SP when daddrsel = daddr_sp else
            STD_LOGIC_VECTOR(UNSIGNED(SP) + 1);
            
din <=  extdin when extdaddrsel = '1' else
        gpr_out1 when dinsel = din_reg else
        PC_plus_1 (7 downto 0) when dinsel = din_pc_inc else
        "0000" & PC_plus_2 (11 downto 8)  when dinsel = din_pc_plus_2 else
        SR;
        
data_we <= extdataload when extdaddrsel = '1' else dwe;

data_memory: entity work.DRAM(behavioral)
	generic map( MEM_SIZE => G_DMEM_SIZE)
	port map(
			clk => clk,
			we => data_we,
	        di => din,
			do => dout,
			addr => daddr(G_DMEM_SIZE-1 downto 0));

auxdin <= din;
auxdaddr <= daddr;
extdout <= dout;

with auxdoutsel select
    dbus <= auxdout when '1',
            dout when others;
            
-- PROGRAM MEMORY

paddr <= PC when (extprogload = '0') else extpaddr;

prog_memory: entity work.DRAM(behavioral)
	generic map( MEM_SIZE => G_PMEM_SIZE)
	port map(
		clk => clk,
		we => extprogload, -- program memory cannot be written inside softcore
	    di => extprogin,
		do => prog_out,
		addr => paddr(G_PMEM_SIZE-1 downto 0));

progword <= prog_out;

-- GENERAL PURPOSE REGISTERS

with gpr_wdata1sel select
    gpr_wdata1 <=   prog_out when wdata1_imm,
                    STD_LOGIC_VECTOR(UNSIGNED(gpr_out1) + 1) when wdata1_inc,
                    IEinternal (7 downto 0) when others;
                    
with gpr_wdata2sel select
    gpr_wdata2 <=   STD_LOGIC_VECTOR(alu_out) when wdata2_alu,
                    aluc_out when wdata2_aluc,
                    gpr_out1 when wdata2_reg,
                    STD_LOGIC_VECTOR(UNSIGNED(gpr_out2) + 1) when wdata2_inc,
                    dbus when wdata2_mem,
                    IEinternal (15 downto 8) when others;
                
gp_registers: entity work.GPRegisters(Structural)
    generic map(
        G_NUM_SHDW_REGS => G_NUM_SHDW_REGS
    )
    port map(
        clk => clk,
        rst => rst,
        
        load_shadow => load_shadow,
        unload_shadow => unload_shadow,
        
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

-- PROGRAM COUNTER

with PCsel select
    PCnext <=   PC when PC_hold,
                STD_LOGIC_VECTOR(UNSIGNED(PC) + 1) when PC_inc,
                x"000" when PC_reset,
                lastprog_out (3 downto 0) & prog_out (7 downto 0) when PC_imm,
                PC (11 downto 8) & dbus when PC_mem_low,
                dbus (3 downto 0) & PC (7 downto 0) when PC_mem_high,
                IV & "0000" when PC_iv,
                PCS when others;

store_PC: entity work.regn(Behavioral)
    generic map(n => 12)
    port map(
        d => PCnext,
        clk => clk,
        rst => rst,
        q => PC
    );
    
with load_shadow select
    PCSnext <=  PC when '1',
                PCS when others;
                
store_PCS: entity work.regn(Behavioral)
    generic map(n => 12)
    port map(
        d => PCSnext,
        clk => clk,
        rst => rst,
        q => PCS
    );
    
PC_plus_1 <= STD_LOGIC_VECTOR(UNSIGNED(PC) + 1);
PC_plus_2 <= STD_LOGIC_VECTOR(UNSIGNED(PC) + 2);

-- LAST PROGWORD

with PCsel select
    nextlastprog_out <= lastprog_out when PC_hold,
                        prog_out when others;
                        
store_lastprog_out: entity work.regn(Behavioral)
    generic map(n => 8)
    port map(
        d => nextlastprog_out,
        clk => clk,
        rst => rst,
        q => lastprog_out
    );
    
lastprogword <= lastprog_out;

-- STACK POINTER

with SPsel select
    SPnext <=   SP when SP_hold,
                STD_LOGIC_VECTOR(UNSIGNED(SP) + 1) when SP_inc,
                STD_LOGIC_VECTOR(UNSIGNED(SP) - 1) when SP_dec,
                STD_LOGIC_VECTOR(UNSIGNED(lastprog_out(3 downto 0)
                    & prog_out & "0000") - 1) when SP_load,
                SP when others;
            
store_SP: entity work.regn(Behavioral)
    generic map(n => 16)
    port map(
        d => SPnext,
        clk => clk,
        rst => rst,
        q => SP
    );
    
-- STATUS REGISTER

with SRsel select
    SRnext <=   SR when SR_hold,
                dbus when SR_mem,
                alu_sr when SR_alu,
                aluc_sr when SR_aluc,
                SRS when others;

store_SR: entity work.regn(Behavioral)
    generic map(n => 8)
    port map(
        d => SRnext,
        clk => clk,
        rst => rst,
        q => SR
    );
    
with load_shadow select
    SRSnext <=  SR when '1',
                SRS when others;
                
store_SRS: entity work.regn(Behavioral)
    generic map(n => 8)
    port map(
        d => SRSnext,
        clk => clk,
        rst => rst,
        q => SRS
    );
    
sr_out <= SR;

-- ALU

with alu_asel select
    alu_a <=    UNSIGNED(gpr_out1) when alu_areg,
                UNSIGNED("0000" & prog_out (7 downto 4)) when others;
                
alu: entity work.ALU(Behavioral)
    port map(
        a => alu_a,
        b => UNSIGNED(gpr_out2),
        sr => SR,
        opc2 => to_alu_opc2(lastprog_out (3 downto 0)),
        result_out => alu_out,
        sr_out => alu_sr
    );
    
-- ALUC

aluc: entity work.ALUC(Structural)
    port map(
        clk => clk,
        rst => rst,
        start => aluc_start,
        a => gpr_out1,
        b => gpr_out2,
        Im => prog_out (7 downto 4),
        opc2 => lastprog_out (3 downto 0),
        sr => SR,
        sr_out => aluc_sr,
        result => aluc_out,
        wait_req => wait_req
    );
    
-- INTERRUPT ENABLE (IE) REGISTER

with iesel select
    IEnext <=   IEinternal when ie_hold,
                gpr_pairout when others;
                
store_IE: entity work.regn(Behavioral)
    generic map(n => 16)
    port map(
        d => IEnext,
        clk => clk,
        rst => rst,
        q => IEinternal
    );
    
IE <= IEinternal;

-- INTERRUPT VECTOR (IV) REGISTERS

iv_registers: entity work.IVRegisters(Structural)
    generic map(G_NUM_IV_REGS => G_NUM_IV_REGS)
    port map(
        clk => clk,
        rst => rst,
        addr => iv_addr,
        wdata => iv_wdata,
        write => iv_write,
        iv => IV
    );
    
end Structural;
