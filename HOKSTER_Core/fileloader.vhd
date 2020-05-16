----------------------------------------------------------------------------------
-- Engineer: Tom Conroy

-- Design Name: 
-- Module Name: fileloader - Dataflow
-- Project Name: HOKSTER Core
-- Target Devices: 
-- Tool Versions: 
-- Description: Loads memory from a file
--  Given a file with name FILE_NAME
--  of format:
--      <byte>\n
--      <byte>
--      ...
--
--  where <byte> is two hexadecimal digits, this module loads the contents
--  of the file into an array. It also finds the end of the file and stores
--  the 0-indexed line number of the last byte as endloc.
--
--  The done signal is asserted when the input addr = endloc
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity fileloader is
	Generic (
		LOADER_SIZE : integer;
		FILE_NAME : string
    );
	Port (
		addr : in STD_LOGIC_VECTOR(LOADER_SIZE-1 downto 0);
		dout : out STD_LOGIC_VECTOR(7 downto 0);
		done : out STD_LOGIC
	);

end fileloader;

architecture Dataflow of fileloader is

signal index: integer range 0 to 2**LOADER_SIZE-1;
type vector_array is array (0 to 2**LOADER_SIZE-1) of STD_LOGIC_VECTOR(7 downto 0);

impure function memory_init(filename : string) return vector_array is
    variable temp : vector_array;
    file file_handle : text;
    variable file_line : line;
    variable address : integer;
begin
    address := 0;
    
    file_open(file_handle, filename, READ_MODE);
    
    while not endfile(file_handle) loop
        readline(file_handle, file_line);
        hread(file_line, temp(address));
        address := address + 1;
    end loop;
    
    file_close(file_handle);
    
    return temp;
end function;

impure function find_endloc(filename : string) return integer is
    file file_handle : text;
    variable file_line : line;
    variable line_count : integer;
begin
    line_count := 0;
    
    file_open(file_handle, filename, READ_MODE);
    readline(file_handle, file_line); -- read line 0
    
    while not endfile(file_handle) loop
        readline(file_handle, file_line);
        line_count := line_count + 1;
    end loop;
    
    file_close(file_handle);
    
    return line_count;
end function;

constant memory : vector_array := memory_init(filename => FILE_NAME);

constant endloc : STD_LOGIC_VECTOR(15 downto 0) :=
    STD_LOGIC_VECTOR(to_unsigned(find_endloc(filename => FILE_NAME), 16));

begin
	index <= to_integer(unsigned(addr));
	dout <= memory(index);
    done <= '1' when (addr = endloc(LOADER_SIZE-1 downto 0)) else '0';
end Dataflow;
