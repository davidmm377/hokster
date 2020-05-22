----------------------------------------------------------------------------------
-- Company: SAL-VT
-- Engineer: Behnaz Rezvani
-- Description: Some functions, like pad, double, truncate, etc.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Declarations
----------------------------------------------------------------------------------
package SomeFunction is
    
    function cofb_pad   (I         : in std_logic_vector(127 downto 0);
                         bytes_Num : in natural)                        return std_logic_vector;
    function comet_pad  (I         : in std_logic_vector(127 downto 0);
                         bytes_Num : in natural)                        return std_logic_vector;
    function doubling   (Zp0       : in std_logic_vector(63 downto 0))  return std_logic_vector;
    function tripling   (L         : in std_logic_vector(63 downto 0))  return std_logic_vector;
    function G          (Y         : in std_logic_vector(127 downto 0)) return std_logic_vector;
    function rho1       (Y, M      : in std_logic_vector(127 downto 0)) return std_logic_vector;
    function phi        (Zp        : in std_logic_vector(127 downto 0)) return std_logic_vector;
    function shuffle    (X         : in std_logic_vector(127 downto 0)) return std_logic_vector;
    function cofb_mux   (X         : in std_logic_vector(127 downto 0); 
                         ctr_words : in std_logic_vector(1 downto 0);
                         last_word : in std_logic)                      return std_logic_vector;
    function comet_mux  (Reg_out   : in std_logic_vector(127 downto 0);
                         bdi       : in std_logic_vector(31 downto 0);
                         ctr_words : in std_logic_vector(1 downto 0))   return std_logic_vector;
    function trunc      (output    : in std_logic_vector(31 downto 0);
                         bdi_size  : in std_logic_vector(4 downto 0))   return std_logic_vector;  
    function BE2LE      (output    : in std_logic_vector(31 downto 0))  return std_logic_vector;
    function BS2C       (B         : in std_logic_vector(127 downto 0))  return std_logic_vector;
    function C2BS       (B         : in std_logic_vector(127 downto 0))  return std_logic_vector;
    
end package SomeFunction;

-- Body
----------------------------------------------------------------------------------
package body SomeFunction is

    -- Padding -------------------------------------------------------------------
    -- COFB padding function
    function cofb_pad (I : in std_logic_vector(127 downto 0); bytes_Num : in natural) return std_logic_vector is
    variable temp  : std_logic_vector(127 downto 0);
    begin
        if (bytes_Num = 0) then
            temp(127)           := '1';
            temp(126 downto 0)  := (others => '0');
        elsif (bytes_Num < 16) then
            temp(127 downto (128 - 8*bytes_Num)) := I(127 downto (128 - 8*bytes_Num));
            temp(127 - 8*bytes_Num)              := '1';
            temp(126 - 8*bytes_Num downto 0)     := (others => '0');
        else
            temp := I;
        end if;
        return temp;
    end function;
    
    -- COMET padding function
    function comet_pad (I : in std_logic_vector(127 downto 0); bytes_Num : in natural) return std_logic_vector is
    variable temp : std_logic_vector(127 downto 0);
    begin
        if (bytes_Num = 0) then -- pad_I = 0*1
            temp(127 downto 1)  := (others => '0');
            temp(0)             := '1'; 
        elsif (bytes_Num < 16) then -- pad_I = 0*1 || I
            temp(127 downto 8*bytes_Num + 1)    := (others => '0');
            temp(8*bytes_Num)                   := '1';
            temp(8*bytes_Num - 1 downto 0)      := I(8*bytes_Num - 1 downto 0);
        else -- pad_I = I
            temp := I;
        end if;
        return temp;
    end function;

    -- 2*b -----------------------------------------------------------------------
    function doubling (Zp0 : in std_logic_vector(63 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(63 downto 0);
    begin
        if (Zp0(63) = '0') then
            temp := Zp0(62 downto 0) & '0'; -- A<<1, if a(63)=0
        else
            temp := Zp0(62 downto 4) & ( (Zp0(3 downto 0) & '0') xor "11011"); -- (A<<1) xor 27, if a(63)=1
        end if;
        return temp;
    end function;  
    
    -- 3*b -----------------------------------------------------------------------
    function tripling (L : in std_logic_vector(63 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(63 downto 0);
    begin
        temp := Doubling (L) xor L;
        return temp;
    end function; 
    
    -- G ------------------------------------------------------------------------
    function G (Y : in std_logic_vector(127 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(127 downto 0);
    begin
        temp := Y(63 downto 0) & Y(126 downto 64) & Y(127); -- G(Y) = (Y[2], Y[1] <<< 1);
        return temp;
    end function;
    
    -- rho1 ---------------------------------------------------------------------
    function rho1 (Y, M : in std_logic_vector(127 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(127 downto 0);
    begin
        temp := G(Y) xor M; -- rho1(Y, M) = G(Y) xor M
        return temp;
    end function;
    
    -- phi -----------------------------------------------------------------------
    function phi (Zp : in std_logic_vector(127 downto 0)) return std_logic_vector is -- permute function (get_blk_key)
    variable Z0 : std_logic_vector(63 downto 0);
    variable Z : std_logic_vector(127 downto 0);
    begin
        Z0  := doubling (Zp(63 downto 0)); -- Zp = (Zp1, Zp0), Z0 = Zp0 * 2
        Z   := Zp(127 downto 64) & Z0; -- Z = (Zp1, Z0)
        return Z;     
    end function;
    
    -- shuffle -------------------------------------------------------------------
    function shuffle (X : in std_logic_vector(127 downto 0)) return std_logic_vector is
    variable X2     : std_logic_vector(31 downto 0);
    variable temp   : std_logic_vector(127 downto 0);
    begin
        X2   := X(64) & X(95 downto 65); -- X2 >>> 1
        temp := X(63 downto 32) & X(31 downto 0) & X2 & X(127 downto 96); -- (X1, X0, Xp2, X3)
        return temp;
    end function;
    
    -- Multiplexer ---------------------------------------------------------------
    -- COFB multiplexer function
    function cofb_mux (X         : in std_logic_vector(127 downto 0); 
                       ctr_words : in std_logic_vector(1 downto 0);
                       last_word : in std_logic) return std_logic_vector is
    variable temp : std_logic_vector(127 downto 0);
    begin
        if (last_word = '1' and ctr_words = 0) then
            temp := X(31 downto 0) & X(127 downto 32);
        elsif (last_word = '1' and ctr_words = 1) then
            temp := X(63 downto 0) & X(127 downto 64);
        elsif (last_word = '1' and ctr_words = 2) then
            temp := X(95 downto 0) & X(127 downto 96);
        else
            temp := X;
        end if;
        return temp;
    end function;
    
    -- COMET multiplexer function
    function comet_mux (Reg_out     : in std_logic_vector(127 downto 0);
                        bdi         : in std_logic_vector(31 downto 0);
                        ctr_words   : in std_logic_vector(1 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(127 downto 0);
    begin
        if (ctr_words = 0) then
            temp := Reg_out(127 downto 32) & bdi;
        elsif (ctr_words = 1) then
            temp := Reg_out(127 downto 64) & bdi & Reg_out(31 downto 0);
        elsif (ctr_words = 2) then
            temp := Reg_out(127 downto 96) & bdi & Reg_out(63 downto 0);
        else
            temp := bdi & Reg_out(95 downto 0);
        end if;
        return temp;
    end function;
    
    -- Truncate -----------------------------------------------------------------
    function trunc (output : in std_logic_vector(31 downto 0); bdi_size : in std_logic_vector(4 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(31 downto 0);
    begin
        if (bdi_size = 1) then
            temp := output(31 downto 24) & x"000000";
        elsif (bdi_size = 2) then
            temp := output(31 downto 16) & x"0000";
        elsif (bdi_size = 3) then
            temp := output(31 downto 8) & x"00";
        else
            temp := output;
        end if;
        return temp;
    end function;
    
    -- Big endian to little endian ----------------------------------------------
    function BE2LE (output : in std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return output(7 downto 0) & output(15 downto 8) & output(23 downto 16) & output(31 downto 24);
    end function;
    
    -- Bit-sliced to conventional format for GIFT -------------------------------
    function BS2C (B : in std_logic_vector(127 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(127 downto 0);
    begin
        nibbles: for i in 0 to 31 loop
            temp(4*i)     := B(i + 96);
            temp(4*i + 1) := B(i + 64);
            temp(4*i + 2) := B(i + 32);
            temp(4*i + 3) := B(i);       
        end loop;
        return temp;
    end function;
    
    -- Conventional to bit-sliced format for GIFT -------------------------------
    function C2BS (B : in std_logic_vector(127 downto 0)) return std_logic_vector is
    variable temp : std_logic_vector(127 downto 0);
    begin
        nibbles: for i in 0 to 31 loop
            temp(i + 96) := B(4*i);
            temp(i + 64) := B(4*i + 1);
            temp(i + 32) := B(4*i + 2);
            temp(i)      := B(4*i + 3);       
        end loop;
        return temp;
    end function;
    
end package body SomeFunction;

