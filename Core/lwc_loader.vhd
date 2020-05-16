----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: lwc_loader - Structural
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: Lightweight Cryptography Loader
--  This module implements the control logic necessary to run testvectors of
--  GIFT, CHAM, and AES ciphers on the SoftCore. The cipher, key, and plaintext
--  are configured through the external interface of the module. The ciphertext
--  is returned on the dout signal when the encryption ends.
--
--  Asserting start signals the module that a transfer originating externally
--  is requested. The type of transfer is specified in the signal header.
--  Transfers are either 1 byte or 16 bytes, each byte requiring one clock
--  cycle. The data is transferred on the din bus. When the lwc_loader is ready
--  for a transfer, the ready signal will be asserted.
--
--  The types of transfers are:
--      cipher - choose between AES, CHAM, and GIFT (1 transfer cycle)
--      key - provide the 128-bit key (16 transfer cycles)
--      plaintext - provide the 128-bit plaintext (16 transfer cycles)
-- 
--  Upon assertion of start, both header and din must have valid data.
--
--  Immediately after receiving the plaintext, the encryption is started in the
--  core. Upon completion, the done signal is asserted. The 16 byte ciphertext
--  is returned on the 16 clock cycles starting on the same cycle done is
--  asserted.
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lwc_loader is
    Generic (
        -- Default d-bus width is 8 bits
        G_DATA_BUS_WIDTH    : integer := 8;
        
        -- Default program memory size is 2^8 bytes
        G_PMEM_SIZE         : integer := 9;
        
        -- Default data memory size is 2^8 bytes
        G_DMEM_SIZE         : integer := 8;

        -- Size of data buffer in loader 2^DATA_LOAD_SIZE
        DATA_LOAD_SIZE : integer := 8
       
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           header : in headerType;
           din : in STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
           ready : out STD_LOGIC;
           done : out STD_LOGIC;
           dout : out STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0)
    );
end lwc_loader;

architecture Structural of lwc_loader is

-- CONSTANTS
constant PZEROS : STD_LOGIC_VECTOR (11 - G_PMEM_SIZE downto 0) := (OTHERS => '0');
constant DZEROS : STD_LOGIC_VECTOR (15 - DATA_LOAD_SIZE downto 0) := (OTHERS => '0');
constant TEXT_LOC : UNSIGNED (15 downto 0) := x"0000";
constant KEY_LOC : UNSIGNED (15 downto 0) := x"0010";

-- SOFT CORE SIGNALS
signal core_start : STD_LOGIC;
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
signal extpaddrshort : STD_LOGIC_VECTOR (G_PMEM_SIZE-1 downto 0);
signal progloadend : STD_LOGIC;
signal progcounter_enable : STD_LOGIC;

signal giftextprogin, chamextprogin, aesextprogin : STD_LOGIC_VECTOR (7 downto 0);
signal giftprogloadend, champrogloadend, aesprogloadend : STD_LOGIC;

-- DATA LOAD
signal extdaddrloadshort : STD_LOGIC_VECTOR (DATA_LOAD_SIZE-1 downto 0);
signal dataload, dataloadend : STD_LOGIC;
signal datacounter_enable : STD_LOGIC;
signal cipher_din : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);

signal giftcipher_din, chamcipher_din, aescipher_din : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
signal giftdataloadend, chamdataloadend, aesdataloadend : STD_LOGIC;

-- KEY AND PLAINTEXT LOAD
signal plaintextload, keyload : STD_LOGIC;

-- RUN
signal runend : STD_LOGIC;

-- DATA READ
signal dataread : STD_LOGIC;

-- BUS COUNTER
signal clear_counter : STD_LOGIC;
signal counter_rst : STD_LOGIC;
signal buscount : STD_LOGIC_VECTOR (3 downto 0);
signal buscounter_enable : STD_LOGIC;

-- CIPHER REGISTER
signal nextcipher, cipher : STD_LOGIC_VECTOR (1 downto 0);
signal cipherload : STD_LOGIC;
begin

-- catch loading programs larger than memory supports during simulation
assert (G_DMEM_SIZE >= DATA_LOAD_SIZE);

-- SOFTCORE

extpaddr <= PZEROS & extpaddrshort;

extdaddr <= DZEROS & extdaddrloadshort when dataload = '1' else
            STD_LOGIC_VECTOR(KEY_LOC + UNSIGNED(x"000" & buscount)) when keyload = '1' else
            STD_LOGIC_VECTOR(TEXT_LOC + UNSIGNED(x"000" & buscount)) when
                plaintextload = '1' or dataread = '1' else
            x"0000";

extdin <= cipher_din when dataload = '1' else din;

extdataload <= dataload or keyload or plaintextload;

extdaddrsel <= extdataload or dataread;

ibus <= x"0000";

softcore: entity work.SoftCore(Structural)
    generic map ( G_DATA_BUS_WIDTH => G_DATA_BUS_WIDTH,
              G_PMEM_SIZE => G_PMEM_SIZE,
              G_DMEM_SIZE => G_DMEM_SIZE
    )
    port map ( clk => clk,
           rst => rst,
           
           start => core_start,
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
           extdout => dout
    );

runend <= '1' when sbus = x"FF" else '0';

done <= dataread;

-- CIPHER REGISTER

nextcipher <= din (1 downto 0) when cipherload = '1' else cipher;

store_cipher: entity work.regn(behavioral)
    generic map(N => 2)
    port map(
        d => nextcipher,
        clk => clk,
        rst => rst,
        q => cipher
    );
    
-- COUNTERS

counter_rst <= rst or clear_counter;

buscounter: entity work.countern(Structural)
    generic map(N => 4)
    port map(
        clk => clk,
        rst => counter_rst,
        enable => buscounter_enable,
        count => buscount
    );
    
progcounter_enable <= '1' when (extprogload = '1' and progloadend = '0') else '0';

progloadcntr: entity work.countern(Structural)
    generic map(N => G_PMEM_SIZE)
    port map(
        clk => clk,
        rst => counter_rst,
        enable => progcounter_enable,
        count => extpaddrshort
    );


datacounter_enable <= '1' when (dataload = '1' and dataloadend = '0') else '0';

dataloadcntr: entity work.countern(Structural)
    generic map(N => DATA_LOAD_SIZE)
    port map(
        clk => clk,
        rst => counter_rst,
        enable => datacounter_enable,
        count => extdaddrloadshort
    );

-- PROG AND DATA LOADERS

gift_prog: entity work.fileloader(Dataflow)
    generic map (
        LOADER_SIZE => G_PMEM_SIZE,
        FILE_NAME => "gift128ise_prog.hex"
    )
    port map (
        addr => extpaddrshort,
        dout => giftextprogin,
        done => giftprogloadend
    );
    
gift_data: entity work.fileloader(Dataflow)
    generic map (
        LOADER_SIZE => DATA_LOAD_SIZE,
        FILE_NAME => "gift128ise_data.hex"
    )
    port map (
        addr => extdaddrloadshort,
        dout => giftcipher_din,
        done => giftdataloadend
    );
    
cham_prog: entity work.fileloader(Dataflow)
    generic map (
        LOADER_SIZE => G_PMEM_SIZE,
        FILE_NAME => "cham128ise_prog.hex"
    )
    port map (
        addr => extpaddrshort,
        dout => chamextprogin,
        done => champrogloadend
    );
    
cham_data: entity work.fileloader(Dataflow)
    generic map (
        LOADER_SIZE => DATA_LOAD_SIZE,
        FILE_NAME => "cham128ise_data.hex"
    )
    port map (
        addr => extdaddrloadshort,
        dout => chamcipher_din,
        done => chamdataloadend
    );
    
aes_prog: entity work.fileloader(Dataflow)
    generic map (
        LOADER_SIZE => G_PMEM_SIZE,
        FILE_NAME => "aesenc_prog.hex"
    )
    port map (
        addr => extpaddrshort,
        dout => aesextprogin,
        done => aesprogloadend
    );
    
aes_data: entity work.fileloader(Dataflow)
    generic map (
        LOADER_SIZE => DATA_LOAD_SIZE,
        FILE_NAME => "aesenc_data.hex"
    )
    port map (
        addr => extdaddrloadshort,
        dout => aescipher_din,
        done => aesdataloadend
    );

                    
with cipher select
    extprogin  <=   giftextprogin when cipher_gift,
                    chamextprogin when cipher_cham,
                    aesextprogin when others;
       
with cipher select
    progloadend <=  giftprogloadend when cipher_gift,
                    champrogloadend when cipher_cham,
                    aesprogloadend when others;
                  
with cipher select
    cipher_din <=   giftcipher_din when cipher_gift,
                    chamcipher_din when cipher_cham,
                    aescipher_din when others;
                    
with cipher select
    dataloadend <=  giftdataloadend when cipher_gift,
                    chamdataloadend when cipher_cham,
                    aesdataloadend when others;
                                        
-- CONTROLLER

controller: entity work.lwc_loader_controller(Behavioral)
    port map ( clk => clk,
           rst => rst,
           
           count => buscount,
           start => start,
           header => header,
           
           ready => ready,
           clear_counter => clear_counter,
           enable_counter => buscounter_enable,
           
           progloadend => progloadend,
           progload => extprogload,
           
           dataloadend => dataloadend,
           dataload => dataload,
           
           plaintextload => plaintextload,
           keyload => keyload,
           cipherload => cipherload,
           
           runend => runend,
           runstart => core_start,
           
           dataread => dataread
    );
    
end Structural;
