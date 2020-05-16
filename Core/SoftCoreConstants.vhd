----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Package Name: SoftCoreConstants
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: File containg global constants
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
use IEEE.NUMERIC_STD.ALL;

package SoftCoreConstants is
    -- PCsel values
    type PCselType is (PC_hold, PC_inc, PC_reset, PC_imm, PC_mem_high, PC_mem_low, PC_iv, PC_pcs);
    
    -- SPsel values
    type SPselType is (SP_hold, SP_inc, SP_dec, SP_load);
    
    -- SRsel values
    type SRselType is (SR_hold, SR_mem, SR_alu, SR_aluc, SR_srs);
    
    -- daddrsel values
    type daddrselType is (daddr_zero, daddr_reg, daddr_sp, daddr_sp_inc);
    
    -- dinsel values
    type dinselType is (din_reg, din_sr, din_pc_inc, din_pc_plus_2);
    
    -- General purpose register decoding
    constant r0addr : STD_LOGIC_VECTOR (3 downto 0) := x"0";
    constant r1addr : STD_LOGIC_VECTOR (3 downto 0) := x"1";
    constant r2addr : STD_LOGIC_VECTOR (3 downto 0) := x"2";
    constant r3addr : STD_LOGIC_VECTOR (3 downto 0) := x"3";
    constant r4addr : STD_LOGIC_VECTOR (3 downto 0) := x"4";
    constant r5addr : STD_LOGIC_VECTOR (3 downto 0) := x"5";
    constant r6addr : STD_LOGIC_VECTOR (3 downto 0) := x"6";
    constant r7addr : STD_LOGIC_VECTOR (3 downto 0) := x"7";
    constant a0addr : STD_LOGIC_VECTOR (3 downto 0) := x"8";
    constant a1addr : STD_LOGIC_VECTOR (3 downto 0) := x"9";
    constant a2addr : STD_LOGIC_VECTOR (3 downto 0) := x"A";
    constant a3addr : STD_LOGIC_VECTOR (3 downto 0) := x"B";
    constant a4addr : STD_LOGIC_VECTOR (3 downto 0) := x"C";
    constant a5addr : STD_LOGIC_VECTOR (3 downto 0) := x"D";
    constant a6addr : STD_LOGIC_VECTOR (3 downto 0) := x"E";
    constant a7addr : STD_LOGIC_VECTOR (3 downto 0) := x"F";
    
    -- Decoding opc1
    type opc1Type is (
        opc1_mvs,       -- 0000
        opc1_mvv,       -- 0001
        opc1_jmp,       -- 0010
        opc1_jsr,       -- 0011
        opc1_bzi,       -- 0100
        opc1_bni,       -- 0101
        opc1_bci,       -- 0110
        opc1_bxi,       -- 0111
        opc1_mvi,       -- 1000
        opc1_alu,       -- 1001
        opc1_aluc,      -- 1010
        opc1_RESERVED1, -- 1011
        opc1_gen1,      -- 1100
        opc1_psh,       -- 1101
        opc1_pop,       -- 1110
        opc1_RESERVED2  -- 1111
    );        
        
    function to_opc1 (s : STD_LOGIC_VECTOR(3 downto 0))
        return opc1Type;
    
    -- Decoding opc2
    type alu_opc2Type is (
        opc2_add,           -- 0000
        opc2_sub,           -- 0001
        opc2_and,           -- 0010
        opc2_lor,           -- 0011
        opc2_sll,           -- 0100
        opc2_rol,           -- 0101
        opc2_srl,           -- 0110
        opc2_ror,           -- 0111
        opc2_alu_RESERVED1, -- 1000
        opc2_alu_RSERVED2,  -- 1001
        opc2_not,           -- 1010
        opc2_xor,           -- 1011
        opc2_adc,           -- 1100
        opc2_sbc,           -- 1101
        opc2_adi,           -- 1110
        opc2_sbi            -- 1111
    );
    function to_alu_opc2 (s : STD_LOGIC_VECTOR(3 downto 0))
        return alu_opc2Type;
        
    --gen1 opc2
    type gen1_opc2Type is (
        opc2_mov,               -- 0000
        opc2_lxb,               -- 0001
        opc2_sxb,               -- 0010
        opc2_ret,               -- 0011
        opc2_str,               -- 0100
        opc2_lsr,               -- 0101
        opc2_rie,               -- 0110
        opc2_sie,               -- 0111
        opc2_hlt,               -- 1000
        opc2_rti,               -- 1001
        opc2_gen1_RESERVED1,    -- 1010
        opc2_gen1_RESERVED2,    -- 1011
        opc2_gen1_RESERVED3,    -- 1100
        opc2_gen1_RESERVED4,    -- 1101
        opc2_gen1_RESERVED5,    -- 1110
        opc2_sys                -- 1111
    );
    function to_gen1_opc2 (s : STD_LOGIC_VECTOR(3 downto 0))
        return gen1_opc2Type;
        
    -- SR bits
    constant srZ : integer := 0;
    constant srN : integer := 1;
    constant srC : integer := 2;
    constant srX : integer := 3;
    
    -- wdata1sel values
    type wdata1selType is (wdata1_imm, wdata1_inc, wdata1_ie);
    
    -- wdata2sel values
    type wdata2selType is (wdata2_alu, wdata2_aluc, wdata2_reg,
        wdata2_inc, wdata2_mem, wdata2_ie);
    
    -- alu_asel values
    type alu_aselType is (alu_areg, alu_aimm);
    
    -- iesel values
    type ieselType is (ie_hold, ie_load);
    
    -- lwc_loader header values
    type headerType is (header_cipher, header_key, header_plaintext);
    
    -- lwc_loader cipher constants
    constant cipher_gift : STD_LOGIC_VECTOR (1 downto 0) := "00";
    constant cipher_cham : STD_LOGIC_VECTOR (1 downto 0) := "01";
    constant cipher_aes : STD_LOGIC_VECTOR (1 downto 0) := "10";
    
end SoftCoreConstants;

package body SoftCoreConstants is
    function to_opc1 (s : STD_LOGIC_VECTOR(3 downto 0))
        return opc1Type is
    begin
        return opc1Type'VAL(to_integer(UNSIGNED(s)));
    end to_opc1;
    
    function to_alu_opc2 (s : STD_LOGIC_VECTOR(3 downto 0))
        return alu_opc2Type is
    begin
        return alu_opc2Type'VAL(to_integer(UNSIGNED(s)));
    end to_alu_opc2;
    
    function to_gen1_opc2 (s : STD_LOGIC_VECTOR(3 downto 0))
        return gen1_opc2Type is
    begin
        return gen1_opc2Type'VAL(to_integer(UNSIGNED(s)));
    end to_gen1_opc2;
end SoftCoreConstants;
