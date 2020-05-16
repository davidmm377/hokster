Description
The Hokster Assembler takes a single input file <file> and converts it to <file>_prog.hex and <file>_data.hex.
The assembler defaults to hex for both the data and the program file.  If an output filename is given, the assembler
will guess the desired output format based on the output.


Arguments:
The assembler takes several optional commands
1 - help (-h, --help).  Prints help and usage for the Hokster Assembler
2 - output (-o, --output).  Sets the name of the output file
3 - data (-d, --data).  Sets the name of the output data file
4 - format (-f, --format).  Set the format of the output file.  Options are: "c", "hex", "vhdl"


Examples:

Simple usage:
    python hoksterAsm.py inputfile.txt

Print help for the assembler:
    python hoksterAsm.py --help

Output to a .c header file:
    python hoksterAsm.py inputfile.txt -f c

Output to a vhdl file named "output":
    python hoksterASm.py inputfile.txt -o output.vhdl

