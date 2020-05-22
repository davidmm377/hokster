----------------------------------------------------------------------------------
-- Company: SAL- Virginia Tech
-- Engineer: Behnaz Rezvani
-- Project Name: HOKSTER Core
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use work.SoftCoreConstants.all;

-- Entity
----------------------------------------------------------------------------------
entity Wrapper_Controller is
    Port(
        cipher          : in    integer;
        clk             : in    std_logic;
        rst             : in    std_logic;
        -- Data Input
        key             : in    std_logic_vector(31 downto 0); -- SW = 32
        bdi             : in    std_logic_vector(31 downto 0); -- W = 32
        -- Key Control
        key_valid       : in    std_logic;
        key_ready       : out   std_logic;
        key_update      : in    std_logic;
        -- BDI Control
        bdi_valid       : in    std_logic;
        bdi_ready       : out   std_logic;
        bdi_valid_bytes : in    std_logic_vector(3 downto 0); -- W/8 = 4
        bdi_size        : in    std_logic_vector(2 downto 0); -- W/(8+1) = 3
        bdi_eot         : in    std_logic;
        bdi_eoi         : in    std_logic;
        bdi_type        : in    std_logic_vector(3 downto 0);
        decrypt_in      : in    std_logic;
        -- BDO Control
        bdo_valid       : out   std_logic;
        bdo_ready       : in    std_logic;
        bdo_valid_bytes : out   std_logic_vector(3 downto 0); -- W/8 = 4
        end_of_block    : out   std_logic;
        -- Tag Verification
        msg_auth_valid  : out   std_logic;
        msg_auth_ready  : in    std_logic;
        -- Hard Loader Control
        HL_ready        : in    std_logic;
        HL_start        : out   std_logic;
        HL_done         : in    std_logic;      
        -- Datapath Control
        ctr_words       : inout std_logic_vector(1 downto 0);
        ctr_bytes       : inout std_logic_vector(4 downto 0);
        ctr_HL          : inout std_logic_vector(3 downto 0);
        KeyReg128_rst   : out   std_logic;
        KeyReg128_en    : out   std_logic;
        HL_dinReg_rst   : out   std_logic;
        HL_dinReg_en    : out   std_logic;
        DstateReg_rst   : out   std_logic;
        DstateReg_en    : out   std_logic;
        Dstate_mux_sel  : out   std_logic_vector(1 downto 0);
        ZstateReg_rst   : out   std_logic;
        ZstateReg_en    : out   std_logic;
        Zstate_mux_sel  : out   std_logic_vector(2 downto 0);
        Z_ctrl_mux_sel  : out   std_logic_vector(2 downto 0);
        YstateReg_rst   : out   std_logic;
        YstateReg_en    : out   std_logic;
        Ystate_mux_sel  : out   std_logic_vector(1 downto 0);
        iDataReg_rst    : out   std_logic;
        iDataReg_en     : out   std_logic;
        iData_mux_sel   : out   std_logic_vector(1 downto 0);
        bdo_t_mux_sel   : out   std_logic;
        Ek_in_mux_sel   : out   std_logic; 
        HL_mux_sel      : out   std_logic_vector(1 downto 0)      
    );
end Wrapper_Controller;

-- Architecture
----------------------------------------------------------------------------------
architecture Behavioral of Wrapper_Controller is

    -- Constants -----------------------------------------------------------------
    --bdi_type and bdo_type encoding
    constant HDR_AD         : std_logic_vector(3 downto 0)  := "0001";
    constant HDR_MSG        : std_logic_vector(3 downto 0)  := "0100";
    constant HDR_CT         : std_logic_vector(3 downto 0)  := "0101";
    constant HDR_TAG        : std_logic_vector(3 downto 0)  := "1000";
    constant HDR_KEY        : std_logic_vector(3 downto 0)  := "1100";
    constant HDR_NPUB       : std_logic_vector(3 downto 0)  := "1101";
    
    -- Types ---------------------------------------------------------------------
    type fsm is (idle, load_key, wait_Npub, load_Npub, process_Npub, load_AD, process_AD, -- Common states
                 after_AD, load_data, process_data, after_data, output_tag, load_tag,
                 verify_tag, send_cipher, send_key, send_data, load_din,
                 after_Npub_g, AD_delta1, AD_delta2, AD_delta3, AD_delta4, M_delta1, M_delta2, -- Only for gift-cofb
                 after_Npub_c, output_data,  process_tag); -- Only for comet

    -- Signals ------------------------------------------------------------------- 
    signal state, n_state : fsm;    
    
    signal decrypt_reg,   decrypt_rst,     decrypt_set      : std_logic;
        
    signal last_AD_reg,   last_AD_rst,     last_AD_set      : std_logic;               
    signal no_AD_reg,     no_AD_rst,       no_AD_set        : std_logic;
    signal last_M_reg,    last_M_rst,      last_M_set       : std_logic;    
    signal no_M_reg,      no_M_rst,        no_M_set         : std_logic;
    signal half_AD_reg,   half_AD_set_0,   half_AD_rst_0    : std_logic; -- only for gift-cofb  
    signal half_M_reg,    half_M_set_0,    half_M_rst_0     : std_logic; -- only for gift-cofb    
    signal first_AD_reg,  first_AD_set_12, first_AD_rst_12  : std_logic; -- only for comet 
    signal first_M_reg,   first_M_set_12,  first_M_rst_12   : std_logic; -- only for comet     
    
    signal ValidBytesReg_rst, ValidBytesReg_en              : std_logic;
    signal ValidBytesReg_out                                : std_logic_vector(3 downto 0);

    signal ctr_words_rst,  ctr_words_inc                    : std_logic;    
    signal ctr_bytes_rst,  ctr_bytes_inc,   ctr_bytes_dec   : std_logic;    
    signal ctr_HL_rst,     ctr_HL_inc                       : std_logic; -- For hard loader 
  
    signal iHeaderReg_in,  iHeaderReg_out                   : std_logic_vector(3 downto 0);
    signal iHeaderReg_en,  iHeaderReg_rst                   : std_logic;
    signal iHeader_mux_sel                                  : std_logic_vector(1 downto 0);
    
----------------------------------------------------------------------------------
begin
   
    with iHeader_mux_sel select
        iHeaderReg_in <= HDR_NPUB when "00",
                         HDR_AD   when "01",
                         HDR_MSG  when "10",
                         HDR_TAG  when others;
   
    Header_Reg: entity work.myReg
    generic map( b => 4)
    Port map(
        clk     => clk,
        rst     => iHeaderReg_rst,
        en      => iHeaderReg_en,
        D_in    => iHeaderReg_in,
        D_out   => iHeaderReg_out
    );
    
    ValidBytesReg: entity work.myReg -- Only for comet
    generic map( b => 4)
    Port map(
        clk     => clk,
        rst     => ValidBytesReg_rst,
        en      => ValidBytesReg_en,
        D_in    => bdi_valid_bytes,
        D_out   => ValidBytesReg_out
    );

--================================================================================
--------------------------------- Clock Process ----------------------------------
--================================================================================  
    state_process: process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                state  <= idle;               
            else
                state  <= n_state;
            end if;
        end if;
    end process state_process;

    registers_process: process(clk)
    begin
        if rising_edge(clk) then          
            if (ctr_words_rst = '1') then
                ctr_words   <= "00";
            elsif (ctr_words_inc = '1') then
                ctr_words   <= ctr_words + 1;
            end if;
            
            if (ctr_bytes_rst = '1') then
                ctr_bytes   <= "00000";
            elsif (ctr_bytes_inc = '1') then
                ctr_bytes   <= ctr_bytes + bdi_size;
            elsif (ctr_bytes_dec = '1') then
                ctr_bytes   <= ctr_bytes - 4;
            end if;
            
            if (ctr_HL_rst = '1') then
                ctr_HL   <= "0000";
            elsif (ctr_HL_inc = '1') then
                ctr_HL   <= ctr_HL + 1;
            end if;

            if (decrypt_rst = '1') then
                decrypt_reg <= '0';
            elsif (decrypt_set = '1') then
                decrypt_reg <= '1';
            end if;
            
            if (first_AD_rst_12 = '1') then -- Only for comet
                first_AD_reg <= '0';
            elsif (first_AD_set_12 = '1') then
                first_AD_reg <= '1';
            end if;
            
            if (last_AD_rst = '1') then
                last_AD_reg <= '0';
            elsif (last_AD_set = '1') then
                last_AD_reg <= '1';
            end if;
            
            if (half_AD_rst_0 = '1') then -- Only for gift-cofb
                half_AD_reg <= '0';
            elsif (half_AD_set_0 = '1') then
                half_AD_reg <= '1';
            end if;

            if (no_AD_rst = '1') then
                no_AD_reg   <= '0';
            elsif (no_AD_set = '1') then
                no_AD_reg   <= '1';
            end if;
            
            if (first_M_rst_12 = '1') then -- Only for comet
                first_M_reg <= '0';
            elsif (first_M_set_12 = '1') then
                first_M_reg <= '1';
            end if;
            
            if (last_M_rst = '1') then
                last_M_reg  <= '0';
            elsif (last_M_set = '1') then
                last_M_reg  <= '1';
            end if;
            
            if (half_M_rst_0 = '1') then -- Only for gift-cofb
                half_M_reg  <= '0';
            elsif (half_M_set_0 = '1') then
                half_M_reg  <= '1';
            end if;

            if (no_M_rst = '1') then
                no_M_reg   <= '0';
            elsif (no_M_set = '1') then
                no_M_reg   <= '1';
            end if;

        end if;
    end process registers_process;

--================================================================================
------------------------------- Controller FSM -----------------------------------
--================================================================================  
    Controller: process(state, key, bdi, key_valid, key_update, bdi_valid, bdi_eot, bdi_eoi,
                        bdi_type, ctr_words, HL_done, bdo_ready, msg_auth_ready, HL_ready, ctr_HL)
    begin
        n_state             <= idle;
        key_ready           <= '0';
        bdi_ready           <= '0';
        bdo_valid           <= '0';
        msg_auth_valid      <= '0';  
        ctr_words_rst       <= '0';
        ctr_words_inc       <= '0';
        ctr_bytes_rst       <= '0';
        ctr_bytes_inc       <= '0';
        ctr_bytes_dec       <= '0';
        ctr_HL_rst          <= '0';
        ctr_HL_inc          <= '0';
        KeyReg128_rst       <= '0';
        KeyReg128_en        <= '0';
        HL_dinReg_rst       <= '0';
        HL_dinReg_en        <= '0';
        iHeaderReg_rst      <= '0';
        iHeaderReg_en       <= '0';
        iDataReg_rst        <= '0';
        iDataReg_en         <= '0';
        DstateReg_rst       <= '0';
        DstateReg_en        <= '0';
        ZstateReg_rst       <= '0';
        ZstateReg_en        <= '0';
        YstateReg_rst       <= '0';
        YstateReg_en        <= '0'; 
        decrypt_rst         <= '0';
        decrypt_set         <= '0';
        first_AD_rst_12     <= '0';
        first_AD_set_12     <= '0';
        last_AD_rst         <= '0';
        last_AD_set         <= '0'; 
        half_AD_rst_0       <= '0';
        half_AD_set_0       <= '0';
        no_AD_rst           <= '0';
        no_AD_set           <= '0';
        first_M_rst_12      <= '0';
        first_M_set_12      <= '0';
        last_M_rst          <= '0';
        last_M_set          <= '0';
        half_M_rst_0        <= '0';
        half_M_set_0        <= '0';
        no_M_rst            <= '0';
        no_M_set            <= '0';    
        HL_start            <= '0';
        Ek_in_mux_sel       <= '1';
        bdo_t_mux_sel       <= '0'; -- CT      
        ValidBytesReg_rst   <= '0';
        ValidBytesReg_en    <= '0'; 

        case state is
            when idle =>
                ctr_words_rst       <= '1';
                ctr_bytes_rst       <= '1';
                ctr_HL_rst          <= '1';
                HL_dinReg_rst       <= '1';
                iDataReg_rst        <= '1';
                DstateReg_rst       <= '1'; 
                ZstateReg_rst       <= '1';
                YstateReg_rst       <= '1';                
                decrypt_rst         <= '1';
                first_AD_rst_12     <= '1';
                last_AD_rst         <= '1';
                half_AD_rst_0       <= '1';
                no_AD_rst           <= '1';
                first_M_rst_12      <= '1';
                last_M_rst          <= '1';
                half_M_rst_0        <= '1';
                no_M_rst            <= '1';
                iHeaderReg_rst      <= '1';
                if (key_valid = '1' and key_update = '1') then -- Get a new key
                    KeyReg128_rst   <= '1';  -- No need to keep the previous key
                    n_state         <= load_key;
                elsif (bdi_valid = '1') then -- In decryption, skip getting the key and get the nonce
                    n_state         <= load_Npub;
                else
                    n_state         <= idle;
                end if;
              
            when load_key =>
                key_ready           <= '1';
                KeyReg128_en        <= '1';
                ctr_words_inc       <= '1';
                if (ctr_words = 3) then
                    ctr_words_rst   <= '1';
                    n_state         <= send_cipher;
                else
                    n_state         <= load_key;
                end if;
                
            when send_cipher =>
                HL_start    <= '1';
                if (HL_ready = '1') then                                       
                    n_state <= wait_Npub;
                else
                    n_state <= send_cipher;
                end if;
                
            when wait_Npub =>           
                if (bdi_valid = '1') then
                    n_state <= load_Npub;
                else
                    n_state <= wait_Npub;
                end if;
                
            when load_Npub =>              
                bdi_ready           <= '1';   
                ctr_words_inc       <= '1';
                iDataReg_en         <= '1';
                if (decrypt_in = '1') then -- Decryption
                    decrypt_set     <= '1';
                end if;
                if (bdi_eoi = '1') then -- No AD and no data
                    no_AD_set       <= '1';
                    no_M_set        <= '1';
                end if;
                if (ctr_words = 3) then 
                    ctr_words_rst   <= '1';
                    iHeaderReg_en   <= '1';
                    ZstateReg_en    <= '1'; 
                    YstateReg_en    <= '1';
                    n_state         <= send_key;
                else
                    n_state         <= load_Npub;
                end if;  
                
            when send_key   =>
                HL_start        <= '1';
                if (HL_ready = '1') then
                    ctr_HL_inc  <= '1';     
                end if;
                if (ctr_HL = 15) then
                    ctr_HL_rst  <= '1';
                    n_state     <= send_data;
                else
                    n_state     <= send_key; 
                end if;      
            
            when send_data   =>
                HL_start            <= '1';
                if (iHeaderReg_out = HDR_NPUB) then -- Only for gift-cofb
                    Ek_in_mux_sel   <= '0';
                end if;
                if (HL_ready = '1') then
                    ctr_HL_inc      <= '1';                   
                end if;
                if (ctr_HL = 15) then
                    ctr_HL_rst      <= '1';
                    if (iHeaderReg_out = HDR_NPUB) then
                        n_state     <= process_Npub;
                    elsif (iHeaderReg_out = HDR_AD) then
                        n_state     <= process_AD;
                    elsif (iHeaderReg_out = HDR_MSG) then
                        n_state     <= process_data;
                    else
                        n_state     <= process_tag;
                    end if;
                else
                    n_state         <= send_data; 
                end if; 
                
            when process_Npub =>
                if (HL_done = '1') then 
                    ctr_HL_inc      <= '1'; 
                    HL_dinReg_en    <= '1';                                     
                end if;
                if (ctr_HL = 15) then
                    ctr_HL_rst      <= '1';
                    if (cipher = 0) then -- gift-cofb                    
                        n_state     <= after_Npub_g;
                    else                 -- comet
                        n_state     <= after_Npub_c; 
                    end if;
                else
                    n_state         <= process_Npub;
                end if; 
                
            when after_Npub_g => -- Only for gift-cofb
                iDataReg_rst    <= '1';
                DstateReg_en    <= '1';               
                iHeaderReg_en   <= '1';
                if (bdi_type /= HDR_AD) then -- No AD
                    no_AD_set   <= '1';
                    n_state     <= AD_delta1; 
                else                          
                    n_state     <= load_AD;
                end if;   
                
            when after_Npub_c => -- Only for comet
                iDataReg_rst        <= '1';
                ZstateReg_en        <= '1';               
                YstateReg_en        <= '1';
                if (no_AD_reg = '1') then      -- No AD and no data
                    iHeaderReg_en   <= '1'; 
                    n_state         <= send_key;
                elsif (bdi_type = HDR_AD) then -- Load AD
                    first_AD_set_12 <= '1';
                    n_state         <= load_AD;
                else                           -- No AD, goto load M
                    first_M_set_12  <= '1';
                    n_state         <= load_data; 
                end if;
            
            when load_AD => 
                bdi_ready               <= '1';
                ctr_words_inc           <= '1';
                ctr_bytes_inc           <= '1';
                iHeaderReg_en           <= '1';
                iDataReg_en             <= '1';                
                if (bdi_eoi = '1') then -- No data
                    no_M_set            <= '1';
                end if;
                if (bdi_eot = '1') then -- Last block of AD
                    last_AD_set         <= '1';
                    if (bdi_size /= 4 or ctr_words /= 3) then -- Partial block of AD
                        half_AD_set_0   <= '1';
                    end if;                  
                end if; 
                if (first_AD_reg = '1' and (bdi_eot = '1' or ctr_words = 3)) then -- First block of AD
                    first_AD_rst_12     <= '1';                 
                end if;
                if (bdi_eot = '1' or ctr_words = 3) then -- Have gotten a full block of AD
                    ctr_words_rst       <= '1';
                    ZstateReg_en        <= '1';                    
                    if (cipher = 0) then -- gift-cofb
                        n_state         <= AD_delta1;
                    else                 -- comet
                        n_state         <= send_key;
                    end if;
                else
                    n_state             <= load_AD;
                end if;                   
                
            when AD_delta1 => -- Only for gift-cofb
                DstateReg_en        <= '1';
                n_state             <= AD_delta2;
                
            when AD_delta2 => -- Only for gift-cofb
                if (half_AD_reg = '1' or no_AD_reg = '1') then -- Partial or empty block of AD
                    DstateReg_en    <= '1';
                end if;
                n_state             <= AD_delta3;
            
            when AD_delta3 => -- Only for gift-cofb
                if (no_M_reg = '1') then -- No data, so delta state needs two triples. This is the first one
                    DstateReg_en    <= '1';
                end if;
                n_state             <= AD_delta4;
                
            when AD_delta4 => -- Only for gift-cofb
                if (no_M_reg = '1') then -- No data, so delta state needs two triples. This is the second one
                    DstateReg_en    <= '1';
                end if; 
                n_state             <= send_key;
            
            when process_AD =>
                if (HL_done = '1') then
                    ctr_HL_inc      <= '1'; 
                    HL_dinReg_en    <= '1'; 
                end if;
                if (ctr_HL = 15) then
                    ctr_HL_rst      <= '1';                    
                    n_state         <= after_AD; 
                else
                    n_state         <= process_AD;
                end if;
                
            when after_AD =>
                YstateReg_en            <= '1';
                iDataReg_rst            <= '1';
                ctr_bytes_rst           <= '1';  
                if (last_AD_reg = '0' and no_AD_reg = '0') then -- Still loading AD, if we have any
                    n_state             <= load_AD;
                elsif (no_M_reg = '0') then -- No more AD, start loading M 
                    first_M_set_12      <= '1';
                    n_state             <= load_data;
                else                      -- No block of M
                    if (cipher /= 0) then -- comet: goto process tag
                        ZstateReg_en    <= '1';
                        iHeaderReg_en   <= '1'; 
                        n_state         <= send_key;
                    elsif (decrypt_reg = '0') then  -- gift: (Enc) goto tag extraction
                        n_state         <= output_tag;  
                    else                            -- gift: (Dec) goto verify tag
                        n_state         <= load_tag; 
                    end if;
                end if;
                
            when load_data =>
                bdi_ready               <= '1';            
                ctr_words_inc           <= '1';
                ctr_bytes_inc           <= '1';
                iDataReg_en             <= '1'; 
                ValidBytesReg_en        <= '1'; -- Only for comet: register bdi_valid_bytes for CT        
                if (bdi_eot = '1') then -- Last block of data
                    last_M_set          <= '1';
                    if (bdi_size /= 4 or ctr_words /= 3) then -- Partial block of data
                        half_M_set_0    <= '1';
                    end if;
                end if; 
                if (first_M_reg = '1' and (bdi_eot = '1' or ctr_words = 3)) then -- First block of M
                    first_M_rst_12      <= '1';              
                end if;
                if (cipher = 0 and bdo_ready = '1') then -- gift-cofb
                    bdo_valid           <= '1';              
                end if;   
                if (bdi_eot = '1' or ctr_words = 3) then
                    ctr_words_rst       <= '1';
                    ZstateReg_en        <= '1';
                    iHeaderReg_en       <= '1';
                    if (cipher = 0) then -- gift-cofb
                        n_state         <= M_delta1;
                    else                 -- comet
                        n_state         <= send_key;
                    end if;
                else
                    n_state             <= load_data;
                end if;    
                    
            when M_delta1 => -- Only for gift-cofb
                DstateReg_en        <= '1';
                n_state             <= M_delta2;
                
            when M_delta2 => -- Only for gift-cofb
                if (half_M_reg = '1') then -- Partial block of data
                    DstateReg_en    <= '1';
                end if;
                n_state             <= send_key;
            
            when process_data => 
                if (HL_done = '1') then
                    ctr_HL_inc      <= '1'; 
                    HL_dinReg_en    <= '1';
                end if;
                if (ctr_HL = 15) then
                    ctr_HL_rst      <= '1';
                    n_state         <= after_data;
                else
                    n_state         <= process_data;
                end if;
                
            when after_data => 
                YstateReg_en        <= '1';
                if (cipher /= 0) then -- comet
                    n_state         <= output_data;
                else                  -- gift-cofb
                    ctr_bytes_rst   <= '1';
                    iDataReg_rst    <= '1'; 
                    if (last_M_reg = '1' and decrypt_reg = '0') then -- End of data in encryption
                        n_state     <= output_tag;
                    elsif (last_M_reg = '1') then -- End of data in decryption                           
                        n_state     <= load_tag;
                    else
                        n_state     <= load_data;
                    end if;
                end if;
                
            when output_data => -- Only for comet
                bdo_valid               <= '1';
                ctr_words_inc           <= '1';
                ctr_bytes_dec           <= '1';                              
                if (ctr_words = 3 or ctr_bytes <= 4) then -- All 4 words of CT are done
                    ctr_words_rst       <= '1';
                    ctr_bytes_rst       <= '1';
                    iDataReg_rst        <= '1';
                    if (last_M_reg = '1') then -- No more data, go to process tag
                        ZstateReg_en    <= '1';
                        iHeaderReg_en   <= '1'; 
                        n_state         <= send_key;
                    else
                        n_state         <= load_data;
                    end if;
                else
                    n_state             <= output_data;
                end if;
                
            when process_tag => -- Only for comet
                if (HL_done = '1') then
                    ctr_HL_inc      <= '1'; 
                    HL_dinReg_en    <= '1';
                end if;
                if (ctr_HL = 15) then
                    ctr_HL_rst      <= '1';
                    if (decrypt_reg = '0') then -- Encryption
                        n_state     <= output_tag;
                    else                        -- Decryption
                        n_state     <= load_tag;   
                    end if;
                else
                    n_state         <= process_tag;
                end if;
                
            when output_tag =>                
                bdo_valid           <= '1';               
                bdo_t_mux_sel       <= '1'; -- Tag
                ctr_words_inc       <= '1';
                if (ctr_words = 3) then
                    ctr_words_rst   <= '1';
                    n_state         <= idle;
                else
                    n_state         <= output_tag;
                end if; 
             
            when load_tag =>
                bdi_ready           <= '1';
                ctr_words_inc       <= '1';
                iDataReg_en         <= '1';
                if (ctr_words = 3) then
                    ctr_words_rst   <= '1';
                    n_state         <= verify_tag;
                else
                    n_state         <= load_tag;
                end if;   
            
            when verify_tag =>
                if (msg_auth_ready = '1') then
                    msg_auth_valid  <= '1';
                    n_state         <= idle; 
                else
                    n_state         <= verify_tag;
                end if;
 
            when others =>
                n_state  <= idle;            
        end case;
    end process Controller;
    
--================================================================================
------------------------------- Multiplexers FSM ---------------------------------
--================================================================================  
    bdo_valid_bytes_fsm: process(state, ctr_bytes, bdi_valid_bytes)
    begin
        bdo_valid_bytes <= (others => '1');
        case state is
            when load_data =>
                bdo_valid_bytes     <=  bdi_valid_bytes; 
            when output_data =>
                if (ctr_bytes <= 4) then -- Last 4 bytes of data
                    bdo_valid_bytes <= ValidBytesReg_out;                   
                end if;
            when others => null;
         end case;
    end process bdo_valid_bytes_fsm;
    -----------------------------------------------------------------
    end_of_block_fsm: process(state, ctr_bytes, ctr_words, bdi_eoi)
    begin
        end_of_block <= '0';
        case state is
            when load_data =>
                end_of_block        <= bdi_eoi; 
            when output_data =>
                if (ctr_bytes <= 4) then -- Last 4 bytes of data
                    end_of_block    <= last_M_reg;                    
                end if;
            when output_tag =>
                if (ctr_words = 3) then
                    end_of_block    <= '1'; -- Last word of Tag
                end if;             
            when others => null;
         end case;
    end process end_of_block_fsm;
    -----------------------------------------------------------------
    iData_fsm: process(state, ctr_words, no_AD_reg, first_M_reg, bdi_eoi)
    begin
        iData_mux_sel <= "11";  -- AD/PT/CT  
        case state is 
            when load_npub =>
                iData_mux_sel       <= "00";  -- Nonce 
            when load_data =>
                if (cipher = 0 and decrypt_reg = '1') then -- gift-cofb: during decryption
                    iData_mux_sel   <= "10";
                end if;
            when load_tag =>
                if (cipher = 0) then
                    iData_mux_sel   <= "00"; -- gift-cofb: tag
                end if;
            when others => null;
         end case;
    end process iData_fsm;
    -----------------------------------------------------------------     
    Ystate_fsm: process(state, ctr_words, no_AD_reg, first_M_reg, bdi_eoi)
    begin
        Ystate_mux_sel <= "11";  -- Y = Ek_out xor AD/PT  
        case state is 
            when load_npub =>
                Ystate_mux_sel      <= "00";  -- Y = Nonce
            when after_npub_c =>
                Ystate_mux_sel      <= "01";  -- Y = Key
            when after_data =>
                if (decrypt_reg = '1') then -- Decryption 
                    Ystate_mux_sel  <= "10";
                end if;
            when others => null;
        end case;
    end process Ystate_fsm;
    -----------------------------------------------------------------
    Zstate_fsm: process(state, ctr_words, no_AD_reg, first_M_reg, bdi_eoi)
    begin
        Zstate_mux_sel <= "111"; -- Z = phi(Z xor Ctrl) 
        case state is 
            when load_npub =>
                Zstate_mux_sel      <= "000"; -- Z = Key
            when after_npub_c =>
                Zstate_mux_sel      <= "001"; -- Z = Ek(K, N)
                if (no_AD_reg = '1') then
                    Zstate_mux_sel  <= "010"; -- Z = phi(Ek(K, N) xor Ctrl_tg)
                end if;
            when load_data =>
                if (first_M_reg = '1') then -- First block of M
                    Zstate_mux_sel  <= "011"; -- Ctrl_m                
                end if;      
            when others => null;
        end case;
    end process Zstate_fsm;
    -----------------------------------------------------------------
    Zstate_ctrl_fsm: process(state, ctr_words, no_AD_reg, first_AD_reg, no_M_reg, last_M_reg, bdi_eot)
    begin
        Z_ctrl_mux_sel <= "000"; -- All zeros  
        case state is 
            when after_npub_c | after_AD | output_data =>
                if (no_AD_reg = '1' or no_M_reg = '1' or last_M_reg = '1') then
                    Z_ctrl_mux_sel      <= "111"; -- Ctrl_tg   
                end if;  
            when load_AD =>
                if (first_AD_reg = '1') then -- First block of AD
                    if (bdi_size /= "100" or ctr_words /= 3) then -- Last and partial block of AD 
                        Z_ctrl_mux_sel  <= "011"; -- Ctrl_ad + Ctrl_p_ad
                    else                                          -- First, but not last block of AD
                        Z_ctrl_mux_sel  <= "001"; -- Ctrl_ad
                    end if;
                elsif (bdi_eot = '1' and (bdi_size /= "100" or ctr_words /= 3)) then -- Last and partial block of AD
                    Z_ctrl_mux_sel      <= "010"; -- Ctrl_p_ad                  
                end if;            
            when load_data =>
                if (bdi_eot = '1' and (bdi_size /= "100" or ctr_words /= 3)) then -- Last and partial block of m
                    Z_ctrl_mux_sel      <= "101"; -- Ctrl_p_m                  
                end if;  
            when others => null;
        end case;
    end process Zstate_ctrl_fsm;   
    -----------------------------------------------------------------
    HL_mux_fsm: process(state)
    begin
        HL_mux_sel <= "00"; -- Cipher 
        case state is 
            when send_key =>
                HL_mux_sel <= "01"; -- key
            when send_data =>
                HL_mux_sel <= "10"; -- data
            when others => null;
        end case;
    end process HL_mux_fsm;
    -----------------------------------------------------------------
    iHeader_mux_fsm: process(state, no_AD_reg, no_M_reg, last_M_reg)
    begin
        iHeader_mux_sel <= "00"; -- HDR_NPUB
        case state is 
            when after_npub_g | load_AD =>
                iHeader_mux_sel     <= "01"; -- HDR_AD
            when after_npub_c | after_AD | output_data =>
                if (no_AD_reg = '1' or no_M_reg = '1' or last_M_reg = '1') then
                    iHeader_mux_sel <= "11"; -- HDR_TAG
                end if;
            when load_data =>
                iHeader_mux_sel     <= "10"; -- HDR_MSG               
            when others => null;
        end case;
    end process iHeader_mux_fsm;
    -----------------------------------------------------------------
    Dstate_fsm: process(state, last_AD_reg, half_AD_reg, no_AD_reg, no_M_reg, last_M_reg, half_M_reg)
    begin
        Dstate_mux_sel <= "11"; -- Doubling
        case state is 
            when after_npub_g =>
                Dstate_mux_sel      <= "00"; -- Trunc(Ek(N))
            when AD_delta1 | AD_delta2 =>
                if (last_AD_reg = '1' or half_AD_reg = '1' or no_AD_reg = '1') then -- Last/Partial/No block of AD  
                    Dstate_mux_sel  <= "01"; -- Tripling
                end if;
            when AD_delta3 | AD_delta4 =>
                if (no_M_reg = '1') then -- No data, so delta state needs two triples. This is the first one
                    Dstate_mux_sel  <= "01";
                end if;
            when M_delta1 | M_delta2 =>
                if (last_M_reg = '1' or half_M_reg = '1') then -- Last/Partial block of data
                    Dstate_mux_sel  <= "01";
                end if;
            when others => null;
        end case;
    end process Dstate_fsm;
  
end Behavioral;
