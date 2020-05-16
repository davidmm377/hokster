---------------------------------------------------------------------------------- 
-- Engineer: Tom Conroy

-- Module Name: Controller - Behavioral
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: State and control logic for the SoftCore
--  The processor has 4 main states:
--      STOPPED - not running, waiting for input signal start to be asserted 
--      STARTING - one cycle of starting to reset PC
--      RUNNING - processor is running
--      HALTED - not running, but waiting for valid interrupt to resume
--
--  Due to the 2 cycle nature of most instructions, when running the
--  SoftCore is either in the FIRST or SECOND cycle of an instruction.
--  The only exception is an ALUC_WAIT cycle, which occurs when ALUC
--  instructions take more than 2 cycles.
-- 
-- Dependencies: 
-- 
-- Additional Comments:
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

entity Controller is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           start : in STD_LOGIC;
           
           ibus : in STD_LOGIC_VECTOR (15 downto 0);
           
           sbus : out STD_LOGIC_VECTOR (7 downto 0);
           
           progword : in STD_LOGIC_VECTOR (7 downto 0);
           lastprogword : in STD_LOGIC_VECTOR (7 downto 0);
           
           sr : in STD_LOGIC_VECTOR (7 downto 0);
           PCsel : out PCselType;
           SPsel : out SPselType;
           SRsel : out SRselType;
           
           daddrsel : out daddrselType;
           dinsel : out dinselType;
           dwe : out STD_LOGIC;
           
           gpr_addr1 : out STD_LOGIC_VECTOR (3 downto 0);
           gpr_write1 : out STD_LOGIC;
           gpr_wdata1sel : out wdata1selType;
           
           gpr_addr2 : out STD_LOGIC_VECTOR (3 downto 0);
           gpr_write2 : out STD_LOGIC;
           gpr_wdata2sel : out wdata2selType;
           
           gpr_pairaddr : out STD_LOGIC_VECTOR (2 downto 0);
           
           alu_asel : out alu_aselType;
           
           aluc_start : out STD_LOGIC;
           wait_req : in STD_LOGIC;
           
           iesel : out ieselType;
           ie : in STD_LOGIC_VECTOR (15 downto 0);
           
           iv_addr : out STD_LOGIC_VECTOR (3 downto 0);
           iv_wdata : out STD_LOGIC_VECTOR (7 downto 0);
           iv_write : out STD_LOGIC;
           
           load_shadow : out STD_LOGIC;
           unload_shadow : out STD_LOGIC
    );
end Controller;

architecture Behavioral of Controller is
type Processor_State_Type is (STOPPED, STARTING, RUNNING, HALTED);
signal processor_state : Processor_State_Type;

type Processor_Cycle_Type is (FIRST, SECOND, ALUC_WAIT);
signal processor_cycle, next_processor_cycle: Processor_Cycle_Type;

signal first_opc1, second_opc1 : opc1Type;
signal alu_opc2 : alu_opc2Type;
signal first_opc2, second_opc2 : gen1_opc2Type;

signal halt, prog_end : STD_LOGIC;

signal PC_running : PCselType;

signal enable_update : STD_LOGIC;
signal exit_interrupt : STD_LOGIC;
signal interrupt : STD_LOGIC;
signal interrupt_vector : STD_LOGIC_VECTOR (3 downto 0);

begin

-- opc1 and opc2 when the processor is in first cycle of an instruction
first_opc1 <= to_opc1(progword (7 downto 4));
first_opc2 <= to_gen1_opc2(progword (3 downto 0));

alu_opc2 <= to_alu_opc2(lastprogword (3 downto 0));

-- opc1 and opc2 when the processor is in second cycle of an instruction
second_opc1 <= to_opc1(lastprogword (7 downto 4));
second_opc2 <= to_gen1_opc2(lastprogword (3 downto 0));

-- processor state control logic
process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            processor_state <= STOPPED;
        else
            case processor_state is
                when STOPPED =>
                    if start = '1' then
                        processor_state <= STARTING;
                    end if;
                when STARTING =>
                    -- only one clock cycle
                    processor_state <= RUNNING;
                when RUNNING =>
                    if halt = '1' then
                        processor_state <= HALTED;
                    elsif prog_end = '1' then
                        processor_state <= STOPPED;
                    end if;
                when HALTED =>
                    if (ibus and ie) /= x"0000" then
                        processor_state <= RUNNING;
                    end if;
                when others =>
                    processor_state <= STOPPED;
            end case;
        end if;
    end if;
end process;

-- processor cycle update logic
process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            processor_cycle <= FIRST;
        else
            processor_cycle <= next_processor_cycle;
        end if;
    end if;
end process;

-- Interrupt Controller
interrupt_controller: entity work.InterruptController(Behavioral)
    port map(
        clk => clk,
        rst => rst,
        enable_update => enable_update,
        exit_interrupt => exit_interrupt,
        
        ibus => ibus,
        ie => ie,
        
        interrupt => interrupt,
        vector => interrupt_vector
    );
    
-- Instruction decoding and control signal generation
process (processor_state, processor_cycle, first_opc1, first_opc2, alu_opc2,
    second_opc1, second_opc2, progword, lastprogword, sr, wait_req, interrupt,
    interrupt_vector)
begin
    -- default values
    next_processor_cycle <= FIRST;
    
    SPsel <= sp_hold;
    SRsel <= sr_hold;
    
    daddrsel <= daddr_zero;
    dinsel <= din_reg;
    dwe <= '0';
    
    gpr_addr1 <= "0000";
    gpr_write1 <= '0';
    gpr_wdata1sel <= wdata1_imm;
    
    gpr_addr2 <= "0000";
    gpr_write2 <= '0';
    gpr_wdata2sel <= wdata2_alu;
    
    gpr_pairaddr <= "000";
    
    alu_asel <= alu_areg;
    
    halt <= '0';
    prog_end <= '0';
    
    PC_running <= PC_inc;
    
    sbus <= x"00";
    
    aluc_start <= '0';
    
    iesel <= ie_hold;
    
    iv_addr <= "0000";
    iv_wdata <= progword;
    iv_write <= '0';
    
    enable_update <= '0';
    exit_interrupt <= '0';
    
    load_shadow <= '0';
    unload_shadow <= '0';
    
    if processor_state = RUNNING then
        case processor_cycle is
            when FIRST =>
                enable_update <= '1'; -- enable interrupt controller update
                if interrupt = '1' then
                    next_processor_cycle <= FIRST;
                    PC_running <= PC_iv;
                    iv_addr <= interrupt_vector;
                    load_shadow <= '1';
                else
                    case first_opc1 is
                        when opc1_jsr => -- FIRST CYCLE OF jsr
                            next_processor_cycle <= SECOND;
                            daddrsel <= daddr_sp;
                            dinsel <= din_pc_plus_2;
                            dwe <= '1';
                            SPsel <= sp_dec;
                            
                        when opc1_gen1 =>
                            case first_opc2 is
                                when opc2_ret => -- FIRST CYCLE OF ret
                                    next_processor_cycle <= SECOND;
                                    PC_running <= PC_mem_low;
                                    daddrsel <= daddr_sp_inc;
                                    SPsel <= SP_inc;
                                    
                                when opc2_str =>
                                    next_processor_cycle <= FIRST;
                                    daddrsel <= daddr_sp;
                                    dinsel <= din_sr;
                                    dwe <= '1';
                                    SPsel <= sp_dec;
                                    
                                when opc2_lsr =>
                                    next_processor_cycle <= FIRST;
                                    daddrsel <= daddr_sp_inc;
                                    SPsel <= sp_inc;
                                    SRsel <= sr_mem;
                                    
                                when opc2_hlt =>
                                    next_processor_cycle <= FIRST;
                                    halt <= '1';
                                    
                                when opc2_rti =>
                                    next_processor_cycle <= FIRST;
                                    PC_running <= PC_pcs;
                                    SRsel <= SR_srs;
                                    unload_shadow <= '1';
                                    exit_interrupt <= '1';
                                    
                                when others => next_processor_cycle <= SECOND;
                            end case;
                        when opc1_psh =>
                            next_processor_cycle <= FIRST;
                            gpr_addr1 <= progword (3 downto 0);
                            daddrsel <= daddr_sp;
                            dinsel <= din_reg;
                            dwe <= '1';
                            SPsel <= sp_dec;
                            
                        when opc1_pop =>
                            next_processor_cycle <= FIRST;
                            daddrsel <= daddr_sp_inc;
                            SPsel <= sp_inc;
                            gpr_addr2 <= progword (3 downto 0);
                            gpr_wdata2sel <= wdata2_mem;
                            gpr_write2 <= '1';
                            
                        when others => next_processor_cycle <= SECOND;
                    end case;
                end if;
            when SECOND =>
                case second_opc1 is
                    when opc1_mvs =>
                        next_processor_cycle <= FIRST;
                        SPsel <= sp_load;
                    
                    when opc1_mvv =>
                        next_processor_cycle <= FIRST;
                        iv_addr <= lastprogword (3 downto 0);
                        iv_wdata <= progword;
                        iv_write <= '1';
                        
                    when opc1_jmp =>
                        next_processor_cycle <= FIRST;
                        PC_running <= PC_imm;
                        
                    when opc1_jsr => -- SECOND CYCLE OF jsr
                        next_processor_cycle <= FIRST;
                        PC_running <= PC_imm;
                        daddrsel <= daddr_sp;
                        dinsel <= din_pc_inc;
                        dwe <= '1';
                        SPsel <= SP_dec;
                        
                    when opc1_bzi =>
                        next_processor_cycle <= FIRST;
                        if sr(srZ) = '1' then
                            PC_running <= PC_imm;
                        end if;
                        
                    when opc1_bni =>
                        next_processor_cycle <= FIRST;
                        if sr(srN) = '1' then
                            PC_running <= PC_imm;
                        end if;
                    
                    when opc1_bci =>
                        next_processor_cycle <= FIRST;
                        if sr(srC) = '1' then
                            PC_running <= PC_imm;
                        end if;
                    
                    when opc1_bxi =>
                        next_processor_cycle <= FIRST;
                        if sr(srX) = '1' then
                            PC_running <= PC_imm;
                        end if;
                        
                    when opc1_mvi =>
                        next_processor_cycle <= FIRST;
                        gpr_addr1 <= lastprogword (3 downto 0); -- <dst>
                        gpr_write1 <= '1';
                        gpr_wdata1sel <= wdata1_imm;
                        
                    when opc1_alu =>
                        next_processor_cycle <= FIRST;
                        gpr_addr1 <= progword (7 downto 4); -- <src1>
                        gpr_addr2 <= progword (3 downto 0); -- <src2>
                        gpr_write2 <= '1'; -- write to <src2=dst>
                        gpr_wdata2sel <= wdata2_alu; -- write alu_out
                        SRsel <= sr_alu; -- update SR from ALU
                        -- check for use of immediates instead of register
                        if alu_opc2 = opc2_adi or alu_opc2 = opc2_sbi then
                            alu_asel <= alu_aimm;
                        else
                            alu_asel <= alu_areg;
                        end if;
                        
                    when opc1_aluc =>
                        gpr_addr1 <= progword (7 downto 4); -- <src1>
                        gpr_addr2 <= progword (3 downto 0); -- <src2>
                        aluc_start <= '1';
                        if wait_req = '1' then
                            next_processor_cycle <= ALUC_WAIT;
                            PC_running <= PC_hold; -- hold PC
                        else
                            next_processor_cycle <= FIRST;
                            SRsel <= SR_aluc;
                            gpr_write2 <= '1'; -- write to <src2=dst>
                            gpr_wdata2sel <= wdata2_aluc; -- write aluc_out
                        end if;
                        
                    when opc1_gen1 =>
                        case second_opc2 is
                            when opc2_mov =>
                                next_processor_cycle <= FIRST;
                                gpr_addr1 <= progword (7 downto 4); -- <src>
                                gpr_addr2 <= progword (3 downto 0); -- <dst>
                                gpr_write2 <= '1';
                                gpr_wdata2sel <= wdata2_reg; -- write <src>
                                
                            when opc2_lxb =>
                                next_processor_cycle <= FIRST;
                                gpr_pairaddr <= progword (6 downto 4); -- <src>
                                daddrsel <= daddr_reg; -- dmem use register address
                                gpr_addr2 <= progword (3 downto 0); -- <dst>
                                gpr_write2 <= '1';
                                gpr_wdata2sel <= wdata2_mem;
                                -- check for increment needed
                                if progword(7) = '1' then
                                    gpr_addr1 <= '0' & progword (6 downto 4); -- r_i
                                    gpr_write1 <= '1';
                                    gpr_wdata1sel <= wdata1_inc;
                                end if;
                                
                            when opc2_sxb =>
                                next_processor_cycle <= FIRST;
                                gpr_pairaddr <= progword (2 downto 0); -- <dst>
                                daddrsel <= daddr_reg; -- dmem use register address
                                dinsel <= din_reg;
                                dwe <= '1';
                                gpr_addr1 <= progword (7 downto 4); -- <src>
                                -- check for increment needed
                                if progword(3) = '1' then
                                    gpr_addr2 <= '0' & progword (2 downto 0); -- r_i
                                    gpr_write2 <= '1';
                                    gpr_wdata2sel <= wdata2_inc;
                                end if;
                                
                            when opc2_ret => -- SECOND CYCLE OF ret
                                next_processor_cycle <= FIRST;
                                PC_running <= PC_mem_high;
                                daddrsel <= daddr_sp_inc;
                                SPsel <= SP_inc;
                                
                            when opc2_rie =>
                                next_processor_cycle <= FIRST;
                                gpr_addr1 <= '0' & progword (6 downto 4);
                                gpr_write1 <= '1';
                                gpr_wdata1sel <= wdata1_ie;
                                
                                gpr_addr2 <= '1' & progword (6 downto 4);
                                gpr_write2 <= '1';
                                gpr_wdata2sel <= wdata2_ie;
                                
                            when opc2_sie =>
                                next_processor_cycle <= FIRST;
                                gpr_pairaddr <= progword (6 downto 4);
                                iesel <= ie_load;
                                
                            when opc2_sys =>
                                next_processor_cycle <= FIRST;
                                sbus <= progword;
                                if progword = x"FF" then
                                    prog_end <= '1';
                                end if;
                            when others =>
                                next_processor_cycle <= FIRST;
                        end case;
                    when others =>
                        next_processor_cycle <= FIRST;
                end case;
                
            when ALUC_WAIT =>
                gpr_addr1 <= progword (7 downto 4); -- <src1>
                gpr_addr2 <= progword (3 downto 0); -- <src2>
                if wait_req = '1' then
                    next_processor_cycle <= ALUC_WAIT;
                    PC_running <= PC_hold;
                else
                    next_processor_cycle <= FIRST;
                    SRsel <= SR_aluc;
                    gpr_write2 <= '1'; -- write to <src2=dst>
                    gpr_wdata2sel <= wdata2_aluc; -- write aluc_out
                end if;
        end case;
    end if;
end process;

PCsel <=    PC_running when (processor_state = RUNNING) else
            PC_reset when (processor_state = STARTING) else
            PC_hold;
        
end Behavioral;
