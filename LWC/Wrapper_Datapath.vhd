----------------------------------------------------------------------------------
-- Company: SAL-Virginia Tech
-- Engineer: Behnaz Rezvani
-- Project Name: HOKSTER Core
-- Module: Wrapper Datapath
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Design_pkg.all;
use work.SomeFunction.all;
use work.SoftCoreConstants.all;

-- Entity
----------------------------------------------------------------------------------
entity Wrapper_Datapath is
  Port (
    cipher          : in  integer;
    clk             : in  std_logic;
    -- API 
    bdi             : in  std_logic_vector(CCW-1 downto 0);
    bdi_size        : in  std_logic_vector(2 downto 0);
    bdi_eot         : in  std_logic;
    key             : in  std_logic_vector(CCSW-1 downto 0);
    bdo             : out std_logic_vector(CCW-1 downto 0);
    msg_auth        : out std_logic;
    -- Hard Loader
    HL_din          : in  std_logic_vector(7 downto 0);
    HL_header       : out headerType;
    HL_dout         : out std_logic_vector(7 downto 0);
    -- Cipher
    Ek_in_mux_sel   : in  std_logic;
    -- Control
    ctr_words       : in  std_logic_vector(1 downto 0);
    ctr_bytes       : in  std_logic_vector(4 downto 0);
    ctr_HL          : in  std_logic_vector(3 downto 0); 
    KeyReg128_rst   : in  std_logic;
    KeyReg128_en    : in  std_logic;
    HL_dinReg_rst   : in  std_logic;
    HL_dinReg_en    : in  std_logic;
    DstateReg_rst   : in  std_logic;
    DstateReg_en    : in  std_logic;
    Dstate_mux_sel  : in  std_logic_vector(1 downto 0);
    ZstateReg_rst   : in  std_logic; 
    ZstateReg_en    : in  std_logic;
    Zstate_mux_sel  : in  std_logic_vector(2 downto 0);
    Z_ctrl_mux_sel  : in  std_logic_vector(2 downto 0);
    YstateReg_rst   : in  std_logic; 
    YstateReg_en    : in  std_logic;
    Ystate_mux_sel  : in  std_logic_vector(1 downto 0);
    iDataReg_rst    : in  std_logic;
    iDataReg_en     : in  std_logic;
    iData_mux_sel   : in  std_logic_vector(1 downto 0);
    bdo_t_mux_sel   : in  std_logic;
    HL_mux_sel      : in std_logic_vector(1 downto 0) 
  );
end Wrapper_Datapath;

-- Architecture
----------------------------------------------------------------------------------
architecture Behavioral of Wrapper_Datapath is

    -- All zero constants --------------------------------------------------------
    constant zero127        : std_logic_vector(126 downto 0) := (others => '0');
    constant zero123        : std_logic_vector(122 downto 0) := (others => '0');
    constant zero120        : std_logic_vector(119 downto 0) := (others => '0');
    constant zero64         : std_logic_vector(63  downto 0) := (others => '0');

    -- Signals -------------------------------------------------------------------
    signal             cham_key,   aes_key          : std_logic_vector(127 downto 0); 
    signal gift_in,    cham_in,    aes_in           : std_logic_vector(127 downto 0); 
    signal gift_out,   cham_out,   aes_out, Ek_out  : std_logic_vector(127 downto 0); 
    signal gift_start, cham_start, aes_start        : std_logic;
    signal gift_done,  cham_done,  aes_done         : std_logic;
    
    signal KeyReg128_in, secret_key_reg             : std_logic_vector(127 downto 0);

    signal DstateReg_in, DstateReg_out              : std_logic_vector(63  downto 0); -- Delta state
    
    signal ZstateReg_in, ZstateReg_out              : std_logic_vector(127 downto 0);
    signal Zstate_ctrl                              : std_logic_vector(4   downto 0);
    
    signal YstateReg_in, YstateReg_out              : std_logic_vector(127 downto 0);

    signal iDataReg_in, iDataReg_out                : std_logic_vector(127 downto 0);
    signal gift_Data_in, comet_Data_in              : std_logic_vector(127 downto 0);
    
    signal CT, HL_dinReg_in, Ek_out_t               : std_logic_vector(127 downto 0);
    
    signal gift_Ek_out_32, comet_Ek_out_32, CT_32   : std_logic_vector(31  downto 0);
    signal gift_bdo_t, comet_bdo_t                  : std_logic_vector(31  downto 0);
    
    signal key_t, PT_t                              : std_logic_vector(7   downto 0);

--------------------------------------------------------------------------------------   
begin

--====================================================================================
---------------------------- Shared Datapath Multiplexers ----------------------------
--====================================================================================
    msg_auth <=  '1' when (iDataReg_out = Ek_out) else '0';
    
    bdo <= gift_bdo_t when (cipher = 0) else comet_bdo_t; 
    
    KeyReg128_in <= secret_key_reg(95 downto 0) & key;
                                                  
    iDataReg_in <= gift_Data_in when (cipher = 0) else comet_Data_in; 
                                                  
--====================================================================================
-------------------------------- GIFT-COFB Datapath ----------------------------------
--==================================================================================== 
    with Ek_in_mux_sel select
        gift_in <= BS2C(iDataReg_out)                                                                               when '0',    -- Nonce
                   BS2C(rho1(Ek_out, cofb_pad(iDataReg_out, conv_integer(ctr_bytes))) xor (DstateReg_out & zero64)) when others; -- AD, PT  
                         
    with iData_mux_sel select
        gift_Data_in <= iDataReg_out(95 downto 0) & bdi                                      when "00",   -- Nonce or expected tag
                        cofb_mux(iDataReg_out(95 downto 0) & gift_bdo_t, ctr_words, bdi_eot) when "10",   -- PT during the decryption                 
                        cofb_mux(iDataReg_out(95 downto 0) & bdi,   ctr_words, bdi_eot)      when others; -- AD or PT
                             
    with Dstate_mux_sel select
        DstateReg_in <= Ek_out(127 downto 64)   when "00",   -- Tranc(Ek(N))
                        Tripling(DstateReg_out) when "01",   -- 3*L
                        Doubling(DstateReg_out) when others; -- 2*L
                        
    gift_Ek_out_32 <=  Ek_out((127 - conv_integer(ctr_words)*32) downto (96 - conv_integer(ctr_words)*32));
         
    with bdo_t_mux_sel select                      
        gift_bdo_t <=  gift_Ek_out_32 xor bdi when '0',    -- CT(PT) =  Y xor PT(CT) 
                       gift_Ek_out_32         when others; -- Computed tag
                                 
--====================================================================================
------------------------------------ COMET Datapath ----------------------------------
--==================================================================================== 
    -- AES Cipher -----------------------------------
    aes_key <= ZstateReg_out(7   downto 0)  & ZstateReg_out(15  downto 8)   & ZstateReg_out(23  downto 16)  & ZstateReg_out(31  downto 24) &
               ZstateReg_out(39  downto 32) & ZstateReg_out(47  downto 40)  & ZstateReg_out(55  downto 48)  & ZstateReg_out(63  downto 56) &
               ZstateReg_out(71  downto 64) & ZstateReg_out(79  downto 72)  & ZstateReg_out(87  downto 80)  & ZstateReg_out(95  downto 88) &
               ZstateReg_out(103 downto 96) & ZstateReg_out(111 downto 104) & ZstateReg_out(119 downto 112) & ZstateReg_out(127 downto 120);
                 
    aes_in  <= YstateReg_out(7   downto 0)  & YstateReg_out(15  downto 8)   & YstateReg_out(23  downto 16)  & YstateReg_out(31  downto 24) &
               YstateReg_out(39  downto 32) & YstateReg_out(47  downto 40)  & YstateReg_out(55  downto 48)  & YstateReg_out(63  downto 56) &
               YstateReg_out(71  downto 64) & YstateReg_out(79  downto 72)  & YstateReg_out(87  downto 80)  & YstateReg_out(95  downto 88) &
               YstateReg_out(103 downto 96) & YstateReg_out(111 downto 104) & YstateReg_out(119 downto 112) & YstateReg_out(127 downto 120);   
                  
    -------------------------------------------------
    -- CHAM Cipher ----------------------------------
    cham_key <= ZstateReg_out(31 downto 0)  & ZstateReg_out(63  downto 32) &
                ZstateReg_out(95 downto 64) & ZstateReg_out(127 downto 96);
              
    cham_in  <= YstateReg_out(31 downto 0)  & YstateReg_out(63  downto 32) &
                YstateReg_out(95 downto 64) & YstateReg_out(127 downto 96);
                     
    -------------------------------------------------
    -- COMET ----------------------------------------
        with Z_ctrl_mux_sel select
            Zstate_ctrl <= "00001" when "001", -- First AD
                           "00010" when "010", -- Partial AD
                           "00011" when "011", -- Partial first AD
                           "01000" when "101", -- Partial M
                           "10000" when "111", -- Tag
                           "00000" when others; -- Nothing
        
        with Zstate_mux_sel select
            ZstateReg_in    <= secret_key_reg(7   downto 0)   & secret_key_reg(15  downto 8)  &
                               secret_key_reg(23  downto 16)  & secret_key_reg(31  downto 24) &
                               secret_key_reg(39  downto 32)  & secret_key_reg(47  downto 40) &
                               secret_key_reg(55  downto 48)  & secret_key_reg(63  downto 56) &
                               secret_key_reg(71  downto 64)  & secret_key_reg(79  downto 72) &
                               secret_key_reg(87  downto 80)  & secret_key_reg(95  downto 88) &
                               secret_key_reg(103 downto 96)  & secret_key_reg(111 downto 104)&
                               secret_key_reg(119 downto 112) & secret_key_reg(127 downto 120)           when "000", -- Z = Key
                               Ek_out xor (Zstate_ctrl & zero123)                                        when "001", -- Z = Ek(K, N)
                               phi(Ek_out xor (Zstate_ctrl & zero123))                                   when "010", -- Z = phi(Ek(K, N))
                               phi(ZstateReg_out xor (zero120 & "00100000") xor (Zstate_ctrl & zero123)) when "011", -- Because of the bug in the SW code
                               phi(ZstateReg_out xor (Zstate_ctrl & zero123))                            when others;
                               
        with Ystate_mux_sel select
            YstateReg_in    <= comet_Data_in(31   downto 0)   & comet_Data_in(63   downto 32) & 
                               comet_Data_in(95   downto 64)  & comet_Data_in(127  downto 96)                    when "00",   -- Y = Nonce
                               secret_key_reg(7   downto 0)   & secret_key_reg(15  downto 8)  &
                               secret_key_reg(23  downto 16)  & secret_key_reg(31  downto 24) &
                               secret_key_reg(39  downto 32)  & secret_key_reg(47  downto 40) &
                               secret_key_reg(55  downto 48)  & secret_key_reg(63  downto 56) &
                               secret_key_reg(71  downto 64)  & secret_key_reg(79  downto 72) &
                               secret_key_reg(87  downto 80)  & secret_key_reg(95  downto 88) &
                               secret_key_reg(103 downto 96)  & secret_key_reg(111 downto 104)&
                               secret_key_reg(119 downto 112) & secret_key_reg(127 downto 120)                   when "01",   -- Y = key
                               Ek_out xor comet_pad((shuffle(Ek_out) xor iDataReg_out), conv_integer(ctr_bytes)) when "10",   -- Y = CT 
                               Ek_out xor comet_pad(iDataReg_out, conv_integer(ctr_bytes))                       when others; -- Y = Ek_out xor AD/PT 
                            
        with iData_mux_sel select
            comet_Data_in <= iDataReg_out(95 downto 0) & bdi(7  downto 0)  & bdi(15 downto 8) &
                                                         bdi(23 downto 16) & bdi(31 downto 24)              when "00",    -- Nonce/Expected tag
                             comet_mux(iDataReg_out,    (bdi(7  downto 0)  & bdi(15 downto 8)
                                                       & bdi(23 downto 16) & bdi(31 downto 24)), ctr_words) when others; -- AD/PT/CT                                                      
                           
        comet_Ek_out_32 <=  Ek_out(((conv_integer(ctr_words)+1)*32 - 1) downto (conv_integer(ctr_words)*32)); 
        
        CT <= shuffle(Ek_out) xor iDataReg_out; -- Enc: CT = shuffle(Ek_out) xor M
        CT_32 <= CT(((conv_integer(ctr_words)+1)*32 - 1) downto (conv_integer(ctr_words)*32));                  
    
        with bdo_t_mux_sel select 
            comet_bdo_t <=  trunc(BE2LE(CT_32), ctr_bytes) when '0', -- CT(PT) =  Y xor PT(CT)
                            comet_Ek_out_32(7  downto 0)  & comet_Ek_out_32(15 downto 8) &
                            comet_Ek_out_32(23 downto 16) & comet_Ek_out_32(31 downto 24) when others; -- Computed tag              

--====================================================================================
-------------------------------- Ciphers Inputs/Output -------------------------------
--====================================================================================
    key_t <= secret_key_reg((127 - conv_integer(ctr_HL)*8) downto (120 - conv_integer(ctr_HL)*8)) when (cipher = 0) else
             cham_key((127 -       conv_integer(ctr_HL)*8) downto (120 - conv_integer(ctr_HL)*8)) when (cipher = 1) else
             aes_key((127 -        conv_integer(ctr_HL)*8) downto (120 - conv_integer(ctr_HL)*8));
             
    PT_t <= gift_in((127 - conv_integer(ctr_HL)*8) downto (120 - conv_integer(ctr_HL)*8)) when (cipher = 0) else
            cham_in((127 - conv_integer(ctr_HL)*8) downto (120 - conv_integer(ctr_HL)*8)) when (cipher = 1) else
            aes_in((127 -  conv_integer(ctr_HL)*8) downto (120 - conv_integer(ctr_HL)*8));
             
    with HL_mux_sel select
        HL_dout <= std_logic_vector(to_unsigned(cipher, 8)) when "00",
                   key_t                                    when "01",
                   PT_t                                     when others; 
                   
    with HL_mux_sel select
        HL_header <= header_cipher      when "00",
                     header_key         when "01",
                     header_plaintext   when others;

    HL_dinReg_in <= Ek_out_t(119 downto 0) & HL_din; 
    Ek_out <= C2BS(Ek_out_t)                                                                                          when (cipher = 0) else
              Ek_out_t(31  downto 0)  & Ek_out_t(63  downto 32)  & Ek_out_t(95 downto 64)   & Ek_out_t(127 downto 96) when (cipher = 1) else
              Ek_out_t(7   downto 0)  & Ek_out_t(15  downto 8)   & Ek_out_t(23  downto 16)  & Ek_out_t(31 downto 24) &
              Ek_out_t(39  downto 32) & Ek_out_t(47  downto 40)  & Ek_out_t(55  downto 48)  & Ek_out_t(63 downto 56) &
              Ek_out_t(71  downto 64) & Ek_out_t(79  downto 72)  & Ek_out_t(87  downto 80)  & Ek_out_t(95 downto 88) &
              Ek_out_t(103 downto 96) & Ek_out_t(111 downto 104) & Ek_out_t(119 downto 112) & Ek_out_t(127 downto 120);         

--====================================================================================
----------------------------------- Shared registers ---------------------------------
--==================================================================================== 
    KeyReg128: entity work.myReg -- Register for 128-bit secret key
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => KeyReg128_rst,
        en      => KeyReg128_en,
        D_in    => KeyReg128_in,
        D_out   => secret_key_reg
    );
    
    HL_dinReg: entity work.myReg -- Register for 128-bit HL_din
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => HL_dinReg_rst,
        en      => HL_dinReg_en,
        D_in    => HL_dinReg_in,
        D_out   => Ek_out_t
    );
    
    DeltaReg: entity work.myReg -- Register for 64-bit delta state (gift-cofb only)
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => DstateReg_rst,
        en      => DstateReg_en,
        D_in    => DstateReg_in,
        D_out   => DstateReg_out
    );
    
    ZstateReg: entity work.myReg -- Register for 128-bit key state (comet only)
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => ZstateReg_rst,
        en      => ZstateReg_en,
        D_in    => ZstateReg_in,
        D_out   => ZstateReg_out
    );
    
    YstateReg: entity work.myReg -- Register for 128-bit state (comet only)
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => YstateReg_rst,
        en      => YstateReg_en,
        D_in    => YstateReg_in,
        D_out   => YstateReg_out
    );

    iDataReg: entity work.myReg -- Register for nonce, AD, PT/CT, expected tag
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => iDataReg_rst,
        en      => iDataReg_en,
        D_in    => iDataReg_in,
        D_out   => iDataReg_out
    );

end Behavioral;
