----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: lwc_loader_tb - Behavioral
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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

entity lwc_loader_tb is
--  Port ( );
end lwc_loader_tb;

architecture Behavioral of lwc_loader_tb is

constant G_DATA_BUS_WIDTH : integer := 8;

signal clk : STD_LOGIC := '0';
signal rst : STD_LOGIC;
signal start : STD_LOGIC;
signal header : headerType;
signal din : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);
signal ready : STD_LOGIC;
signal done : STD_LOGIC;
signal dout : STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0);

type data16bytes is array (0 to 15) of STD_LOGIC_VECTOR (7 downto 0);

signal key : data16bytes;
signal plaintext : data16bytes;
signal ciphertext : data16bytes;

procedure transfer_cipher
    (cipher : in STD_LOGIC_VECTOR (1 downto 0);
    signal ready : in STD_LOGIC;
    signal start : out STD_LOGIC;
    signal header : out headerType;
    signal din : out STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0)) is
begin
    if ready = '1' then
        wait until ready = '0';
    end if;
    header <= header_cipher;
    start <= '1';
    din <= "000000" & cipher;
    wait until ready = '1';
    wait for 8 ns;
    
    start <= '0';
    wait for 8 ns;
end transfer_cipher;

procedure transfer_16_bytes
    (data_type : in headerType;
    data : in data16bytes;
    signal ready : in STD_LOGIC;
    signal start : out STD_LOGIC;
    signal header : out headerType;
    signal din : out STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0)) is
begin
    if ready = '1' then
        wait until ready = '0';
    end if;
    header <= data_type;
    start <= '1';
    din <= data(0);
    wait until ready = '1';
    wait for 8 ns;
    
    for i in 1 to 15 loop
        din <= data(i);
        wait for 8 ns;
    end loop;
    start <= '0';
    wait for 8 ns;
end transfer_16_bytes;

procedure confirm_result
    (correct_result : in data16bytes;
    signal done : in STD_LOGIC;
    signal dout : in STD_LOGIC_VECTOR (G_DATA_BUS_WIDTH-1 downto 0)) is
begin
    wait until done = '1';
    wait for 4 ns;
    for i in 0 to 15 loop
        assert(correct_result(i) = dout);
        wait for 8 ns;
    end loop;
end confirm_result;

begin

uut: entity work.lwc_loader(Structural)
    generic map (
        G_DATA_BUS_WIDTH => G_DATA_BUS_WIDTH,
        G_PMEM_SIZE => 9,
        G_DMEM_SIZE => 8,
        DATA_LOAD_SIZE => 8
    )
    port map (
        clk => clk,
        rst => rst,
        start => start,
        header => header,
        din => din,
        ready => ready,
        done => done,
        dout => dout
    );
    
clk <= not clk after 4 ns;

init_process: process
begin
    -- initial values
    rst <= '0';
    start <= '0';
    header <= header_cipher;
    din <= x"00";
    wait for 8 ns;
    
    -- GIFT test vector
    key <= (x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08",
        x"09", x"0a", x"0b", x"0c", x"0d", x"0e", x"0f");
    plaintext <= (x"10", x"11", x"12", x"13", x"14", x"15", x"16", x"17",
        x"18", x"19", x"1a", x"1b", x"1c", x"1d", x"1e", x"1f");
    ciphertext <= (x"84", x"c7", x"90", x"05", x"15", x"b1", x"16", x"f4",
        x"80", x"51", x"fe", x"86", x"b9", x"44", x"fe", x"d6");
    
    -- reset hardloader & core
    rst <= '1';
    wait for 8 ns;
    rst <= '0';
    wait for 8 ns;
    
    -- load cipher
    transfer_cipher(cipher_gift, ready, start, header, din);
    
    -- load key
    transfer_16_bytes(header_key, key, ready, start, header, din);
    
    -- load plaintext
    transfer_16_bytes(header_plaintext, plaintext, ready, start, header, din);
    
    -- confirm GIFT ciphertext correct
    confirm_result(ciphertext, done, dout);
    
    -- DO IT AGAIN
    -- load key
    transfer_16_bytes(header_key, key, ready, start, header, din);
    
    -- load plaintext
    transfer_16_bytes(header_plaintext, plaintext, ready, start, header, din);
    
    -- confirm GIFT ciphertext correct
    confirm_result(ciphertext, done, dout);
    
    -- Try AES encryption -----------------------------------------------------
    key <= (x"10", x"11", x"12", x"13", x"14", x"15", x"16", x"17", x"18",
        x"19", x"1a", x"1b", x"1c", x"1d", x"1e", x"1f");
    plaintext <= (x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07",
        x"08", x"09", x"0a", x"0b", x"0c", x"0d", x"0e", x"0f");
    ciphertext <= (x"9c", x"54", x"d5", x"71", x"70", x"2c", x"fa", x"0f",
        x"03", x"f3", x"62", x"15", x"67", x"6b", x"ab", x"78");
    wait for 8 ns;
    -- load cipher
    transfer_cipher(cipher_aes, ready, start, header, din);
    
    -- load key
    transfer_16_bytes(header_key, key, ready, start, header, din);
    
    -- load plaintext
    transfer_16_bytes(header_plaintext, plaintext, ready, start, header, din);
    
    -- confirm AES ciphertext correct
    confirm_result(ciphertext, done, dout);
    
    -- DO IT AGAIN
    -- load key
    transfer_16_bytes(header_key, key, ready, start, header, din);
    
    -- load plaintext
    transfer_16_bytes(header_plaintext, plaintext, ready, start, header, din);
    
    -- confirm AES ciphertext correct
    confirm_result(ciphertext, done, dout);
    
    -- Try CHAM encryption ----------------------------------------------------
    key <= (x"10", x"11", x"12", x"13", x"14", x"15", x"16", x"17", x"18",
        x"19", x"1a", x"1b", x"1c", x"1d", x"1e", x"1f");
    plaintext <= (x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07",
        x"08", x"09", x"0a", x"0b", x"0c", x"0d", x"0e", x"0f");
    ciphertext <= (x"09", x"89", x"91", x"3c", x"a8", x"a5", x"7a", x"34",
        x"97", x"1d", x"aa", x"1e", x"11", x"f0", x"4d", x"a6");
    wait for 8 ns;
    -- load cipher
    transfer_cipher(cipher_cham, ready, start, header, din);
    
    -- load key
    transfer_16_bytes(header_key, key, ready, start, header, din);
    
    -- load plaintext
    transfer_16_bytes(header_plaintext, plaintext, ready, start, header, din);
    
    -- confirm CHAM ciphertext correct
    confirm_result(ciphertext, done, dout);
    
    -- DO IT AGAIN
    -- no key load necessary for the CHAM program
    
    -- load plaintext
    transfer_16_bytes(header_plaintext, plaintext, ready, start, header, din);
    
    -- confirm CHAM ciphertext correct
    confirm_result(ciphertext, done, dout);
    
    wait;
end process;

end Behavioral;
