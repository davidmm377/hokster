#!/usr/bin/env python3
'''
File:    HoksterAsm.py
Purpose: Parses a Hokster Assembly file into VHDL, C, or Hex
Author:  Matthew Bozzay
Version: 1.1
Date: 5/14/2020
'''
import os
import math
import argparse
import datetime
import platform

#TODO: Pseudoinstructions
#TODO: Macros/Assembly Functions
#TODO: Document Code
#TODO: Clean up code
#TODO: Better directive parser
#TODO: Implement exit codes
#TODO: add verbose output
#TODO: add .org constant
#       sys constant

if __name__ == "__main__":
    EXIT_SUCCESS = 1
    EXIT_FAILURE = 2

    #currently supported formats
    VALID_FORMATS = ["vhdl", "c", "h", "hex"]

    ########################### Initialize Argparse ###########################
    parser = argparse.ArgumentParser(description='Hokster Assembler, version 1.0')
    parser.add_argument('input',  type=str, help="the input file for the assembler")
    parser.add_argument('--output', '-o', type=str, help='file to output the assembled code to', default=None, required=False)
    parser.add_argument('--data', '-d', type=str, help='file to output the data to', default=None, required=False)
    parser.add_argument('--comments', '-c', help="output comments to the assembled files", action='store_true', default=False, required=False)
    parser.add_argument('--format', '-f', type=str, help="output format.  Possible options are: {}".format(", ".join([f for f in VALID_FORMATS])), default='hex', required=False)

    args = parser.parse_args()

    args.format = args.format if args.format != 'c' else 'h'

    if platform.system() == "Windows":
        os.system('color') #this line magically lets windows acknowledge terminal colors.


    ################# Error checking for command line Args ####################
    #decide the name of the output file
    if args.output is None:
        path,ext = os.path.splitext(args.input)

        #if we didn't find an output file name, create one after the input file
        args.output = "_prog.".join([path, args.format])

    #add the format of the output file if given in the file name
    else:
        path,ext = os.path.splitext(args.output)
        args.format = ext

    #add the name of the data file
    if args.data is None:
        path,ext = os.path.splitext(args.input)
        args.data = "_data.".join([path, args.format])

########################### Print Functions ###############################
def prRed(s):    print("\033[91m{}\033[00m".format(s))
def prGreen(s):  print("\033[92m{}\033[00m".format(s))
def prYellow(s): print("\033[93m{}\033[00m".format(s))
###########################  END Print      ###############################

########################### Bit Operations ################################
def str_is_valid_hex(s, check_prefix=True):
    """Returns whether an input string is a valid Hex code
       String must start with 0x and be convertable to an integer of base 16
    """
    if not check_prefix or ("0x" in s[:2] or "0X" in s[:2]):
        try:
            int(s, 16)
            return True
        except:
            return False
    return False

def str_is_valid_int(s):
    """Returns whether an input string is a valid integer
       String must be numeric and be convertable to an integer of base 10
    """
    try:
        int(s)
        return True
    except:
        return False

def str_is_valid_bin(some_string, check_prefix=True):
    """Returns whether an input string is a valid binary code
       make sure string starts with 0b and is convertable to an integer of base 2
    """
    if not check_prefix or ("0b" in some_string[:2] or "0B" in some_string[:2]):
        try:
            int(some_string, 2)
            return True
        except:
            return False
    return False

def cvt_bin_to_hex(bits):
    """Converts a binary string of the format: 1010100 to a hex string without the leading 0x
       make sure string starts with 0b and is convertable to an integer of base 2
    """
    return '{:0{}X}'.format(int(bits, 2), len(bits) // 4)

def cvt_base_to_int(i, check_prefix=True):
    '''Guesses the base then returns it as a single integer value
       takes any input integer format (binary, int, hex)
    '''
    s = str(i)
    if str_is_valid_hex(s, check_prefix):   return(int(s, 16))
    elif str_is_valid_bin(s, check_prefix): return(int(s, 2))
    elif str_is_valid_int(s): return(int(s))
    else: return None

def cvt_int_to_bin(some_int, num_bits, fill_type="ext"):
    '''Takes an integer (some_int) and a desired number of output bits (num_bits)
       and converts it to a binary number with the number sign-extended to num_bits
    '''
    unsigned_bin = "{0:b}".format(abs(some_int))

    if fill_type == "ext":
        fill_type = "one" if some_int < 0 else "zero"

    if fill_type == "zero":
        return(unsigned_bin.zfill(num_bits))

    elif fill_type == "one":
        return(abs(num_bits - len(unsigned_bin))*"0" + unsigned_bin)
########################### End Bit Operations ############################

class HoksterRef():
    '''
    Class: HoksterRef
    Purpose: The HoksterRef class stores all valid instructions and registers for the Hokster Architecture.
            Also stores all labels and constants for the current program
            It also contains methods for determining if an instruction or register is valid
    
    Attributes:
            memloc_bits (int): the required length of a memory address in number of bits
            label_bits (int): the maximum number of bits allowed in a label
            constant_bits (int): the maximum number of bits allowed in a constant
            instructions (dict): a dictionary mapping an assembly line to the assembled output.
            registers (dict): a dictionary mapping each register to it's register address as an integer
            constants (dict): initially empty, eventually populated to a dictionary of: <constant> : <value>
            labels (dict): initially empty, eventually populated to a dictionary of:    <label> : <value>
            data (dict): initially empty, populated with a series of memory addresses and values to populate memory file with
            instructions_list (list): a list of all the instructions in the Instructions dictionary
            directives (list): a list of all valid directive types
    Methods:
            get_instruction_input:  returns the mapped input for a given instruction
            get_instruction_output: returns the mapped output for a given instruction
            get_directive_type:     returns the type of a directive given an input string
            get_cycle_count: calculates how many cycles an instruction takes to run
            arg_defined_by_assembler: returns true if the input string is a value filled in by the assembler
            get_instruction_parent: returns the parent category of an instruction
            get_bounds_from_immediate: get the lower and upper bounds of an immediate string
    '''

    #the maximum # of bits allowed for a constant or a label
    memloc_bits   = 16
    label_bits    = 12
    constant_bits = 8
    directives = ["lbl", "equ", "dat", "align"]

    '''
    Hokster instructions follow this input:
    
    instruction_class : {
        instruction : {
            "input" : { "" }
        }
    }
    '''
    instructions = {
        "general" : {
            "mvs" : { "input" : {"op1" : "mvs", "op2" : "Im[15:0]"},                 "output": {"op1" : "0000", "op2" : "Im[15:12]","op3" : "Im[11:8]","op4" : "Im[7:4]"}},
            "mvv" : { "input" : {"op1" : "mvv", "op2" : "Im[11:0]", "op3" : "<ivsrc>"},"output": {"op1" : "0001", "op2" : "<ivsrc>",    "op3" : "Im[11:8]","op4" : "Im[7:4]"}},
            "jmp" : { "input" : {"op1" : "jmp", "op2" : "Im[11:0]"},                 "output": {"op1" : "0010", "op2" : "Im[11:8]", "op3" : "Im[7:4]", "op4" : "Im[3:0]"}},
            "jsr" : { "input" : {"op1" : "jsr", "op2" : "Im[11:0]"},                 "output": {"op1" : "0011", "op2" : "Im[11:8]", "op3" : "Im[7:4]", "op4" : "Im[3:0]"}},
            "bzi" : { "input" : {"op1" : "bzi", "op2" : "Im[11:0]"},                 "output": {"op1" : "0100", "op2" : "Im[11:8]", "op3" : "Im[7:4]", "op4" : "Im[3:0]"}},
            "bni" : { "input" : {"op1" : "bni", "op2" : "Im[11:0]"},                 "output": {"op1" : "0101", "op2" : "Im[11:8]", "op3" : "Im[7:4]", "op4" : "Im[3:0]"}},
            "bci" : { "input" : {"op1" : "bci", "op2" : "Im[11:0]"},                 "output": {"op1" : "0110", "op2" : "Im[11:8]", "op3" : "Im[7:4]", "op4" : "Im[3:0]"}},
            "bxi" : { "input" : {"op1" : "bxi", "op2" : "Im[11:0]"},                 "output": {"op1" : "0111", "op2" : "Im[11:8]", "op3" : "Im[7:4]", "op4" : "Im[3:0]"}},
            "mvi" : { "input" : {"op1" : "mvi", "op2" : "Im[7:0]","op3" : "<dst>"},  "output": {"op1" : "1000", "op2" : "<dst>",    "op3" : "Im[7:4]", "op4" : "Im[3:0]"}},
        },
        "alu"     : {
            "add" : { "input" : {"op1" : "add", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "0000", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "sub" : { "input" : {"op1" : "sub", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "0001", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "and" : { "input" : {"op1" : "and", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "0010", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "lor" : { "input" : {"op1" : "lor", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "0011", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "sll" : { "input" : {"op1" : "sll", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "0100", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "rol" : { "input" : {"op1" : "rol", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "0101", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "srl" : { "input" : {"op1" : "slr", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "0110", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "ror" : { "input" : {"op1" : "ror", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "0111", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "not" : { "input" : {"op1" : "not", "op2" : "<src1>", "op3" : "<dst>"     }, "output" : {"op1" : "1001", "op2" : "1010", "op3" : "<src1>", "op4" : "<dst>"     }},
            "xor" : { "input" : {"op1" : "xor", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "1011", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "adc" : { "input" : {"op1" : "adc", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "1100", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "sbc" : { "input" : {"op1" : "sbc", "op2" : "<src1>", "op3" : "<src2=dst>"}, "output" : {"op1" : "1001", "op2" : "1101", "op3" : "<src1>", "op4" : "<src2=dst>"}},
            "adi" : { "input" : {"op1" : "adi", "op2" : "Im[4:0]","op3" : "<src1=dst>"}, "output" : {"op1" : "1001", "op2" : "1110", "op3" : "Im[3:0]","op4" : "<src1=dst>"}},
            "sbi" : { "input" : {"op1" : "sbi", "op2" : "Im[4:0]","op3" : "<src1=dst>"}, "output" : {"op1" : "1001", "op2" : "1111", "op3" : "Im[3:0]","op4" : "<src1=dst>"}},
        },
        "aluc" : {
            "asb" : { "input" : {"op1" : "asb", "op2" : "<src1>","op3" : "<src2=dst>"}, "output" : {"op1" : "1010", "op2" : "0000", "op3" : "<src1>","op4" : "<src2=dst>"}},
            "aib" : { "input" : {"op1" : "aib", "op2" : "<src1>","op3" : "<src2=dst>"}, "output" : {"op1" : "1010", "op2" : "0001", "op3" : "<src1>","op4" : "<src2=dst>"}},
            "amc" : { "input" : {"op1" : "amc", "op2" : "<src1>","op3" : "<src2=dst>"}, "output" : {"op1" : "1010", "op2" : "0010", "op3" : "<src1>","op4" : "<src2=dst>"}},
            "aic" : { "input" : {"op1" : "aic", "op2" : "<src1>","op3" : "<src2=dst>"}, "output" : {"op1" : "1010", "op2" : "0011", "op3" : "<src1>","op4" : "<src2=dst>"}},
            "swd" : { "input" : {"op1" : "swd", "op2" : "<src1>","op3" : "<src2=dst>"}, "output" : {"op1" : "1010", "op2" : "0100", "op3" : "<src1>","op4" : "<src2=dst>"}},
            "gsp" : { "input" : {"op1" : "gsp", "op2" : "<src1>","op3" : "<src2=dst>"}, "output" : {"op1" : "1010", "op2" : "0101", "op3" : "<src1>","op4" : "<src2=dst>"}},
            "gip" : { "input" : {"op1" : "gip", "op2" : "<src1>","op3" : "<src2=dst>"}, "output" : {"op1" : "1010", "op2" : "0110", "op3" : "<src1>","op4" : "<src2=dst>"}},
        },
        "gen1" : {
            "mov" : { "input" : {"op1" : "mov", "op2" : "<src>", "op3"  : "<dst>"}, "output" : {"op1" : "1100", "op2" : "0000", "op3" : "<src>", "op4"  : "<dst>"}},
            "ldb" : { "input" : {"op1" : "ldb", "op2" : "Im[2:0]", "op3" : "<dst>"}, "output" : {"op1" : "1100", "op2" : "0001", "op3" : "0", "op4": "Im[2:0]", "op5" : "<dst>"}},
            "lpb" : { "input" : {"op1" : "lpd", "op2" : "Im[2:0]", "op3" : "<dst>"}, "output" : {"op1" : "1100", "op2" : "0001", "op3" : "1", "op4": "Im[2:0]", "op5" : "<dst>"}},
            "stb" : { "input" : {"op1" : "stb", "op2" : "<dst>" , "op3" : "Im[2:0]"}, "output" : {"op1" : "1100", "op2" : "0010", "op3" : "<dst>" , "op4" : "0", "op5": "Im[2:0]"}},
            "spb" : { "input" : {"op1" : "spb", "op2" : "<dst>" , "op3" : "Im[2:0]"}, "output" : {"op1" : "1100", "op2" : "0010", "op3" : "<dst>" , "op4" : "1", "op5": "Im[2:0]"}},
            "ret" : { "input" : {"op1" : "ret" }, "output" : {"op1" : "1100", "op2" : "0011" }},
            "str" : { "input" : {"op1" : "str" }, "output" : {"op1" : "1100", "op2" : "0100" }},
            "lsr" : { "input" : {"op1" : "lsr" }, "output" : {"op1" : "1100", "op2" : "0101" }},
            "rie" : { "input" : {"op1" : "rie", "op2" : "Im[2:0]"}, "output" : {"op1" : "1100", "op2" : "0110", "op3" : "0", "op4" : "Im[2:0]", "op5" : "0000"}},
            "sie" : { "input" : {"op1" : "sie", "op2" : "Im[2:0]"}, "output" : {"op1" : "1100", "op2" : "0111", "op3" : "0", "op4" : "Im[2:0]", "op5" : "0000"}},
            "hlt" : { "input" : {"op1" : "hlt" }, "output" : {"op1" : "1100", "op2" : "1000" }},
            "rti" : { "input" : {"op1" : "rti" }, "output" : {"op1" : "1100", "op2" : "1001" }},
            "sys" : { "input" : {"op1" : "sys", "op2" : "Im[7:0]"}, "output" : {"op1" : "1100", "op2" : "1111", "op3" : "Im[7:0]"}},
            "psh" : { "input" : {"op1" : "psh", "op2" : "<src>"}, "output" : {"op1" : "1101", "op2" : "<src>"}},
            "pop" : { "input" : {"op1" : "pop", "op2" : "<dst>"}, "output" : {"op1" : "1110", "op2" : "<dst>"}},
        },
        "pseudo" : {
            "nop"  : { "input" : {"op1" : "nop"}, "output" : {"op1" : "1100", "op2" : "0000", "op3" : "0000", "op4": "0000"}},
        },
        "protected" : {
            "single_cycle_nop"  : { "input" : {"op1" : "single_cycle_nop"}, "output" : {"op1" : "00000000"}},
        }
    }

    registers = {
        "a7" : 15, "a6" : 14, "a5" : 13, "a4" : 12, "a3" : 11, "a2" : 10, "a1" : 9, "a0" : 8,
        "r7" : 7, "r6" : 6, "r5" : 5, "r4" : 4, "r3" : 3, "r2" : 2, "r1" : 1, "r0" : 0,
    }
    interrupt_vectors = {
        "iv15" : 15, "iv14" : 14, "iv13" : 13, "iv12" : 12, "iv11" : 11, "iv10" : 10, "iv9" : 9, "iv8" : 8,
        "iv7" : 7, "iv6" : 6, "iv5" : 5, "iv4" : 4, "iv3" : 3, "iv2" : 2, "iv1" : 1, "iv0" : 0,
    }

    constants = dict() #constant : val
    labels    = dict() #label : PC
    data      = dict() #mem_locations  : [mem_values]

    #populate the instructions_list variable with all valid instructions
    instructions_list = []
    for i in instructions.keys():
        for k in instructions[i].keys():
            instructions_list.append(k)


    #COMMENT PARSING:
    valid_single_line_comments = ["#", "//"]#, "//", ";"]
    valid_multi_line_comments  = []

    def is_valid_mem_address(self, addr):
        '''
        Method: is_valid_mem_address
        Inputs:
            addr (str): a valid address as an unparsed string in the format of hex, binary, or integer
        Outputs:
            output (bool): whether the address is valid or not
        '''
        try:
            #convert to an integer and make sure the bit length is valid
            addr_int = cvt_base_to_int(addr)
            if addr_int.bit_length() <= self.memloc_bits:
                return True
        except:
            return False
        return False

    def is_valid_label(self, addr):
        '''
        Method: is_valid_label
        Inputs:
            addr (str): a valid label as an unparsed string in the format of hex, binary, or integer
        Outputs:
            output (bool): whether the label is valid or not
        '''
        try:
            #convert to an integer and make sure the bit length is valid
            addr_int = abs(cvt_base_to_int(addr))
            if addr_int.bit_length() <= self.label_bits:
                return True
        except:
            return False
        return False
    
    def is_valid_constant(self, addr):
        '''
        Method: is_valid_label
        Inputs:
            addr (str): a constant as an unparsed string in the format of hex, binary, or integer
        Outputs:
            output (bool): whether the address is valid or not
        '''
        try:
            #convert to an integer and make sure the bit length is valid
            addr_int = abs(cvt_base_to_int(addr))
            if addr_int.bit_length() <= self.constant_bits:
                return True
        except:
            return False
        return False


    def get_instruction_input(self, ins):
        '''
        Method: get_instruction_input
        Inputs:
            ins (str): a valid instruction type from the instructions dictionary(add, sub, ...etc)
        Outputs:
            output (dict): the corresponding input dictionary for the instruction
        '''
        for d in self.instructions.keys():
            for k in self.instructions[d].keys():
                if ins == k:
                    if "input" in self.instructions[d][k]:
                        return self.instructions[d][k]["input"]
                    else:
                        return self.instructions[d][k]
        return None
    
    def get_instruction_output(self, ins):
        '''
        Method: get_instruction_output
        Inputs:
            ins (str): a valid instruction type from the instructions dictionary(add, sub, ...etc)
        Outputs:
            output (dict): the corresponding output dictionary for the instruction
        '''
        for d in self.instructions.keys():
            for k in self.instructions[d].keys():
                if ins == k:
                    if "output" in self.instructions[d][k]:
                        return self.instructions[d][k]["output"]
                    elif "input" in self.instructions[d][k]:
                        return self.instructions[d][k]["input"]
                    else:
                        return self.instructions[d][k]
        return None

    def get_directive_type(self, s):
        '''
        Method: get_directive_type
        Inputs:
            s (str): a valid directive type (dat, lbl, equ...)
        Outputs:
            output (str): the corresponding output dictionary for the instruction
        '''
        
        for t in self.directives:
            if s.startswith(t):
                return t
        return None

    def get_cycle_count(self, ins):
        '''
        Method: get_cycle_count
        Inputs:
            ins (str): a valid instruction (add, sub, ...etc)
        Outputs:
            output (int): the number of cycles an instruction takes to complete
        '''
        d = self.get_instruction_output(ins)
        if d is None:
            return 0

        output_len_bin = 0
        imm_len = 0

        for item in d.values():
            if "src" in item or "dst" in item:
                output_len_bin += 4
            elif "Im" in item:
                lb,ub = self.get_bounds_from_immediate(item)
                imm_len += ub - lb + 1
            elif str_is_valid_bin(item,check_prefix=False):
                output_len_bin += len(item)
        output_len_bin += imm_len
        try:
            return(math.ceil(math.log(output_len_bin/4,2)))
        except:
            exit("Fatal error parsing HoksterRef instruction {}".format(ins))
            return(0)

    def get_arg_len_bin(self, ins):
        '''
        Method: get_arg_len_bin
        Inputs:
            ins (str): a valid arg (0101, <src>, Im[7:0], ...etc)
        Outputs:
            output (int): the arguments length in number of binary digits
        '''
        if "src" in ins or "dst" in ins:
            return(4)
        elif "Im" in ins:
            lb,ub = self.get_bounds_from_immediate(ins)
            return(ub - lb + 1)
        elif str_is_valid_bin(ins,check_prefix=False):
            return len(ins)
        else:
            return -1


    def arg_defined_by_assembler(self, arg):
        '''
        Method: arg_defined_by_assembler
        Inputs:
            arg (str): a valid instruction input (add, 0000, <dst>, <src>, <src1=dst>, ...etc)
        Outputs:
            output (bool): true if the instruction is a constant value (add, 0001, etc...) false if decided by user 
        '''
        # if it's an instruction or explicitly a binary opcode then it is a constant
        if arg in self.instructions_list or str_is_valid_bin(arg,check_prefix=False):
            return True
        return False

    def get_instruction_parent(self, ins):
        '''
        Method: get_instruction_parent
        Inputs:
            ins (str): a valid instruction (add, sub, etc..)
        Outputs:
            output (str): the instruction parent of the instruction (gen1, aluc, etc...) 
        '''
        for d in self.instructions.keys():
            if ins in list(self.instructions[d].keys()):
                return d
        return None

    def get_bounds_from_immediate(self, immediate_string):
        '''
        Method: get_bounds_from_immediate
        Inputs:
            ins (str): an immediate string (Im[3:0], Im[10:3], etc)
        Outputs:
            output (tuple(int, int)): the upper and lower values of the immediate string in ascending order
        '''
        #get left_bound, right_bount:
        bounds = immediate_string.split(":")
        lb,rb = bounds[0], bounds[1]

        lb_str = lb.split("[")[-1]
        rb_str = rb.split("]")[0]

        lb_int,rb_int = int(lb_str),int(rb_str)

        return(min(lb_int,rb_int),max(lb_int,rb_int))

    def get_comment_pos(self, line):
        '''
        Method: get_comment_pos
        Input: an unparsed assembly line
        Output: -1 if not found, an integer of the position otherwise
        '''
        comment_pos_list = []
        
        #find the first comment notation in a line
        for comment in self.valid_single_line_comments:
            comment_pos_list.append(line.find(comment))

        #find the smallest comment position that isn't -1
        try:
            return min([n for n in comment_pos_list if n >= 0])
        except:
            return -1

    def get_comment_from_line(self, line, pos=None):
        '''
        Method: parse
        Input: an unparsed assembly line
        Output: HoksterComment if line has a comment, None otherwise
        '''
        comment_format = None

        #get the position of the comment if it exists
        if pos is None:
            pos = self.get_comment_pos(line)

        #decide comment format if it exists
        if pos > -1:
            for item in self.valid_single_line_comments:
                if line[pos] in item:
                    comment_format = item#self.valid_single_line_comments[item]

            return HoksterComment(line[pos:], comment_format, pos)

        #we didn't find a comment
        return None

class HoksterComment():
    '''
    Class: HoksterComment
    Purpose: "encapsulate" all operations related to comments
    Attributes: 
        comment (str): the comment's string
        comment_format: the format of the comment, one of: ["//", "#", ";"] depending on implementation
        pos: the position of the comment in the original line

    Methods:
        rem_format: removes the comment's format from the original instruction
        to_c: converts the original comment to a c-style comment
        to_vhdl: converts the original comment to a vhdl-style comment
    '''
    
    def __init__(self, comment, comment_format="#", pos_in_line=-1):
        """
        Method: __init__
        Purpose: initialize the comment object
        Inputs:
            comment (str): a comment string with or without the format pre-pended to the line
            comment_format (str): the syntax of the comment ("#", "//", etc...)
            pos_in_line (int): the position of the comment from the original line
        """
        self.comment        = comment
        self.comment_format = comment_format
        self.pos            = pos_in_line

    def rem_format(self):
        """
        Method: rem_format
        Purpose: removes the format from the input comment
        Inputs:
            comment (str): a comment string with or without the format pre-pended to the line
            comment_format (str): the syntax of the comment ("#", "//", etc...)
            pos_in_line (int): the position of the comment from the original line
        Output:
            output (str):
        """
        if self.comment_format in self.comment:
            return self.comment[len(self.comment_format):]
        else:
            return self.comment

    def to_c(self):
        """
        Method: to_c
        Purpose: returns the comment as a c comment
        Inputs:
        Output:
            output (str): the current comment object as a c comment
        """
        return "\t//" + str(self.rem_format())

    def to_hex(self):
        """
        Method: to_hex
        Purpose: returns the comment as a hex comment
        Inputs:
        Output:
            output (str): the current comment object as a hex comment
        """
        return "\t--" + str(self.rem_format())

    def to_vhdl(self):
        """
        Method: to_vhdl
        Purpose: returns the comment as a vhdl comment
        Inputs:
        Output:
            output (str): the current comment object as a vhdl comment
        """
        return "\t--" + str(self.rem_format())
    
    def get_comment(self):
        """
        Method: get_comment
        Purpose: returns the comment as a string
        Inputs:
        Output:
            output (str): the current comment as a string
        """
        return self.rem_format()
    
    def get_pos(self):
        """
        Method: get_pos
        Purpose: returns the position of the comment in the line
        Inputs:
        Output:
            output (str): the current comment as a string
        """
        return self.pos

class HoksterInstruction():
    '''
    Class: HoksterInstruction
    Purpose: "encapsulate" all operations related to parsing and storing instructions
    Attributes:
        hokster_ref (HoksterRef): the hokster reference instance with 
        unparsed (str): the unparsed instruction with trailing/leading whitespace removed
        instr_bin (dict): instruction converted to binary format as an ordered dictionary by argument
        instr_format (dict): instruction format from the HoksterRef class
        instr_list (list): instruction split by input arguments.  E.g: ["add", "r1", "r2"]
        PC (int): the program counter address of the beginning of the instruction.
        is_instr (bool): whether this is a valid instruction or not
        comment (HoksterComment): HoksterComment with input assembly line
        directive (): unused at the moment
        errors (list): a list of HoksterErrors associated with the current instruction/directive
        num_cycles (int): the number of PC cycles associated with the current instruction.  Usually 1 or 2

    Methods:
        __init__: sets the class variables, runs first pass on instruction parsing
        hasErrors: returns true if the instruction has any HoksterErrors
        printErrors: prints each instruction error
        to_vhdl: converts the instruction to vhdl
        to_newline_hex: converts the instruction to hex delimited by a newline for every 8-bits
        to_bin: converts the instruction to binary
        to_hex: converts the instruction to hex
        to_vhdl: converts the original comment to a vhdl-style comment
        to_c: converts the instruction to a single item in a C array
        get_next_PC: calculates what the next PC will be based off how many cycles the current instruction takes to run
        set_PC: set the current Program Counter
        split_instruction: parses the instruction off whitespace/comma delimiters and converts it to a list.
        parse: performs the second pass of the instruction parse
    '''
    #instantiate the HoksterRef class
    hokster_ref = HoksterRef()

    def __init__(self, unparsed, PC, comment=None, directive=None, from_asm=False):
        self.unparsed     = unparsed.strip() #the unparsed assembly line (with comments removed)
        self.instr_bin    = dict()           #instruction converted to binary format as an ordered dictionary by argument
        self.instr_format = dict()           #instruction format from the HoksterRef class
        self.instr_list   = []               #the "cleaned" up input with all commands split up nicely
        self.PC           = PC               #the starting PC number for the current line
        self.is_instr     = False            #whether this is an instruction or not
        self.comment      = comment          #HoksterComment object associated with the current line
        self.directive    = directive        #
        self.errors       = []               #List of HoksterError Objects
        self.num_cycles   = 0                #the number of cycles required for this operation to occur

        self.instruction_input = None
        self.instruction_output = None
        self.from_asm           = from_asm

        #comment must be of type HoksterComment
        #split the instruction into it's args
        if len(unparsed.strip()) > 0:
            self.split_instruction(unparsed.strip())

    def hasErrors(self):
        """
        Method: hasErrors
        Purpose: returns True if there were errors in assembly, False otherwise
        Inputs: 
        Output:
            output (bool): True if the number of errors is greater than 0
        """
        return(len(self.errors) > 0)

    def printErrors(self):
        """
        Method: printErrors
        Purpose: prints each HoksterError object
        Inputs: 
        Output:
            output (std:out): each HoksterError for this HoksterInstruction
        """
        for error in self.errors:
            error.print()

    def to_vhdl(self, do_comment=False):
        """
        Method: to_vhdl
        Purpose: returns the instruction as a vhdl string
        Inputs: 
            do_comment (bool): if True, appends comments to the vhdl ouput.
        Output:
            output (str): the entire HoksterInstruction converted to a string
        """
        result = ""
        h = self.to_hex()

        for s_hex in h:
            result += 'x"{}",'.format(s_hex)

            if do_comment:
                result += HoksterComment("\tPC: " + hex(self.PC) + "\t" + self.unparsed).to_vhdl()

                if self.comment is not None:
                    result += "\t{}".format(self.comment.to_vhdl())

            result += '\n'
        return result

    def to_newline_hex(self, do_comment=False):
        """
        Method: to_newline_hex
        Purpose: returns the instruction as a newline-delimited hex string
        Inputs: 
            do_comment (bool): if True, appends comments to output as a vhdl comment.
        Output:
            output (str): the entire HoksterInstruction converted to a hex string
        """
        as_bin = self.to_bin()
        h = cvt_bin_to_hex(as_bin)
        split_hex = [h[i:i+2] for i in range(0, len(h), 2)]

        if do_comment:
            split_hex[0] += HoksterComment("\tPC: " + hex(self.PC) + "\t" + self.unparsed).to_hex()

            if self.comment is not None:
                split_hex[0] += "\t{}".format(self.comment.to_hex())

        return "\n".join(split_hex)

    def to_bin(self):
        """
        Method: to_bin
        Purpose: returns the instruction as binary
        Inputs: 
        Output:
            output (str): the instruction as a binary value
        """
        bin_no_correction = "".join(list(self.instr_bin.values()))
        return bin_no_correction + "0"*(len(bin_no_correction) % 2)
    
    def to_hex(self, do_comment=False):
        """
        Method: to_hex
        Purpose: returns the instruction as a hex string
        Inputs: 
            do_comment (bool): if True, appends comments to output as a vhdl comment.
        Output:
            output (str): the entire HoksterInstruction converted to a hex string
        """
        as_bin = self.to_bin()
        h = cvt_bin_to_hex(as_bin)
        split_hex = [h[i:i+2] for i in range(0, len(h), 2)]

        if do_comment:
            split_hex[0] += HoksterComment("\tPC: " + hex(self.PC) + "\t" + self.unparsed).to_hex()

            if self.comment is not None:
                split_hex[0] += "\t{}".format(self.comment.to_hex())
        
        return split_hex

    def to_c(self, do_comment=False):
        """
        Method: to_c
        Purpose: returns the instruction as c array item 
        Inputs: 
            do_comment (bool): if True, appends comments to output as a c comment.
        Output:
            output (str): the entire HoksterInstruction converted to a c array object
        """
        result = ""
        h = self.to_hex()
        #split_hex = [h[i:i+2] for i in range(0, len(h), 2)]

        for s_hex in h:
            result += '\t0x{},'.format(s_hex)

            if do_comment:
                result += HoksterComment("\tPC: " + hex(self.PC) + "\t" + self.unparsed).to_c()

                if self.comment is not None:
                    result += "\t{}".format(self.comment.to_c())
            result += '\n'
        return result

    def get_next_PC(self):
        """
        Method: get_next_PC
        Purpose: calculates what the next PC would be after this instruction.
        Inputs:
        Output:
            output (int): the next PC
        """
        return self.PC + self.num_cycles
    
    def set_PC(self, PC):
        """
        Method: set_PC
        Purpose: sets the PC for this HoksterInstruction object
        Inputs: 
            PC (int): the next PC
        Output:
        """
        self.PC = PC

    def split_instruction(self, unparsed):
        """
        Method: split_instruction
        Purpose: removes whitespace and splits an unparsed instruction into a list.
                 Sets the following class members:
                 is_instr, instr_format, instr_list, num_cycles, errors
        Inputs: 
            unparsed (str): an unparsed HoksterInstruction line
        Output:
        """
        #delete floating whitespace on either end of line
        split_line = unparsed.strip()

        # example worst case line:
        # label: add $a0, $r0 #some comment
        # split instruction based on whitespace, then remove commas
        self.instr_list = [item.replace(",","") for item in split_line.split()]

        #now look up if the command is valid
        for d in self.hokster_ref.instructions.keys():
            if self.instr_list[0] in list(self.hokster_ref.instructions[d].keys()):
                self.is_instr = True
                self.instr_format = d
                break
        
        if not self.is_instr:
            self.errors.append(HoksterError("OPERATOR_DNE"))

        self.num_cycles = self.hokster_ref.get_cycle_count(self.instr_list[0])

    def parse(self, debug_print=False):
        """
        Method: parse
        Purpose: completely parses the instruction during the second pass of the assembler
                 sets the following class members:
                 instruction_input, instruction_output, instr_bin, errors
        Inputs: 
            debug_print (bool): if True, prints debug information during parsing of instruction.
        Output:
            
        """
        #edge case: trying to parse an invalid instruction
        if not self.is_instr:
            return
        
        #check if the first field is a valid instruction:
        parent     = self.hokster_ref.get_instruction_parent(self.instr_list[0])

        #for non-implemented instructions
        if parent is None or (parent == "protected" and not self.from_asm):
            if debug_print:
                print("invalid operator: {}".format(self.instr_list[0]))
            self.errors.append(HoksterError("OPERATOR_DNE"))
            return

        #get the corresponding instruction dictionary for input/output templates
        self.instruction_input  = self.hokster_ref.get_instruction_input(self.instr_list[0])
        self.instruction_output = self.hokster_ref.get_instruction_output(self.instr_list[0])

        #for each of the remaining items in instr_list, decide if it's a register or constant
        result                = dict()
        instr_simplified      = dict()

        #if we have a mismatch in the # of args, don't try to parse
        if len(self.instr_list) != len(self.instruction_input):
            self.errors.append(HoksterError("OPERATOR_MISSING_ARGS"))
            return

        #now iterate through the rest of the args
        immediate     = {
            "int"      : None,
            "binary"   : "",
            "max_bits" : 0
        }

        #cvt the instruction template to input binary
        for idx,arg_template in enumerate(self.instruction_input.values()):
            arg = self.instr_list[idx]

            #grab the immediate if we're expecting one
            if "Im" in arg_template:
                #define number of bits using the upper_bound
                _,max_index = self.hokster_ref.get_bounds_from_immediate(arg_template)
                immediate["max_bits"] = max_index + 1
                

                #check if user-defined constant, label, or int
                #TODO: check for invalid bit counts for labels
                
                if immediate["max_bits"] == self.hokster_ref.label_bits:
                    immediate["int"] = cvt_base_to_int(self.hokster_ref.labels[arg]) if self.instr_list[idx] in self.hokster_ref.labels else cvt_base_to_int(self.instr_list[idx])
                else:
                    #if immediate["max_bits"] == self.hokster_ref.constant_bits:
                    immediate["int"] = cvt_base_to_int(self.hokster_ref.constants[arg]) if self.instr_list[idx] in self.hokster_ref.constants else cvt_base_to_int(self.instr_list[idx])
                
                #return if unparsable constant or out of range
                if immediate["int"] is None:
                    self.errors.append(HoksterError("CONST_UNPARSABLE"))
                    return
                elif immediate["int"].bit_length() > immediate['max_bits']:
                    self.errors.append(HoksterError("CONST_INVALID"))
                    return

                if self.instruction_input["op1"] in ["sbi", "adi"]:
                    if immediate["int"] == 0:
                        self.errors.append(HoksterError("CONST_INVALID"))
                        return
                    elif immediate["int"] > 16:
                        self.errors.append(HoksterError("CONST_INVALID"))
                        return

                    immediate["int"] = immediate["int"] - 1

                #guess what sign extend to do:
                immediate["binary"] = cvt_int_to_bin(immediate["int"], immediate['max_bits'], 'zero')
                instr_simplified[arg_template] = immediate["binary"]
            
            elif "src" in arg_template or "dst" in arg_template:
                #decide what the register value is
                temp_reg_dict = self.hokster_ref.interrupt_vectors if "iv" in arg_template else self.hokster_ref.registers
                if arg in temp_reg_dict:
                    #TODO: check for 0/1-fill, check for registers out of range
                    instr_simplified[arg_template] = cvt_int_to_bin(temp_reg_dict[arg], 4, 'zero')
                else:
                    try:
                        a = int(arg)
                        if a in temp_reg_dict.values():
                            #TODO: check for 0/1-fill, check for registers out of range
                            instr_simplified[arg_template] = cvt_int_to_bin(a, 4, 'zero')

                        else:
                            self.errors.append(HoksterError("REGISTER_SYNTAX"))
                    except:
                        self.errors.append(HoksterError("REGISTER_SYNTAX"))
                        return
                
                if arg_template.startswith("0") or arg_template.startswith("1"):
                    instr_simplified[arg_template] = arg_template[0] + instr_simplified[arg_template][1:]
            else:
                #for non-registers, non-immediate values (usually just hard-coded by the assembler)
                instr_simplified[arg_template] = arg
        
        #check if we filled in all required args
        if len(instr_simplified) != len(self.instruction_input):
            self.errors.append(HoksterError("OPERATOR_MISSING_ARGS"))
            return
        
        #now convert the instruction into output binary
        for output_template in self.instruction_output.values():
            
            if "Im" in output_template:
                #grab the substring from the binary number
                lb,ub = self.hokster_ref.get_bounds_from_immediate(output_template)

                #grab the substring of the immediate
                result[output_template] = immediate["binary"][-ub-1:] if lb == 0 else immediate["binary"][-ub-1:-lb]

            elif "src" in output_template or "dst" in output_template:
                #decide which argument it corresponds to
                result[output_template] = instr_simplified[output_template]

            elif str_is_valid_bin(output_template, check_prefix=False):
                result[output_template] = output_template

        self.instr_bin = result

        if debug_print:
            print("Instruction {} decoded to: PC: {} - {}".format(self.unparsed, hex(self.PC),self.to_hex()))

class HoksterParser():
    '''
    Class: HoksterParser
    Purpose: parses an input file and converts it to c, assembly, or hex
    Attributes:
        hokster_ref (HoksterRef): an instance of the HoksterRef class
        instructions (list): a list of HoksterInstructions parsed from the input file
        self.has_errors (bool): a boolean flag that returns true if the assembler failed to parse to due errors

    Methods:
        __init__: sets the class variables
        to_file: outputs the instructions and data to two files
        c_constant: creates a C constant from a variable's name and value
        c_array: converts the list of HoksterInstructions to a C array string
        data_to_clist: converts the program memory data to a C array string
        to_vhdl: converts the instructions to VHDL
        to_hex: converts the instuctions to a hex file
        to_c: converts the instructions to a c file
        write_data_file: outputs the data array to a file
        parse_file: parses HoksterInstructions from an input file
    '''
    hokster_ref         = HoksterRef()

    #instantiate the HoksterRef class
    def __init__(self):
        """
        Method: __init__
        Purpose: instantiates the HoksterParser class
        Inputs: 
        Output:
        """
        self.instructions        = []
        self.parsed_instructions = []
        self.has_errors          = False
        

    def to_file(self, output, data, f="hex", do_comments=False, debug_print=False):
        """
        Method: to_file
        Purpose: writes the hokster instructions and data to files.  Function causes no file output itself,
                 but calls a function to write the output files.
        Inputs: 
            output (string): the program output filename
            data (string): the data output filename
            f (string): the desired output format
            do_comments (bool): include comments in the program output
            debug_print (bool): print debug info to the terminal
        Output:
        """
        if debug_print:
            print("Writing to {}, {}".format(output, data))

        if f == "c" or f == 'h':
            self.to_c(output, data, do_comments=do_comments)
        elif f == "vhdl":
            self.to_vhdl(output, data, do_comments)
        elif f == "hex":
            self.to_hex(output, data, do_comments)
        else:
            print("Error, unsupported format: {}".format(f))

        if len(self.hokster_ref.data) != 0 and f != "c" and f != 'h':
            self.write_data_file(data)

        #.write_data_file(args.data)
    def c_constant(self, var_name, var_value):
        """
        Method: c_constant
        Purpose: generates a dictionary of a C constant
        Inputs: 
            var_name (string): the name of the c constant
            var_value (string): the value to give the c constant
        Output:
            constant (dict): the output dictionary for the C constant
                string (string): the c string equivalent of the constant
                name (string): the constant's name
                value (string): the constant's original value
        """
        constant = {
            "string" : " ".join([r"#define", var_name, str(var_value)]),
            "name" : var_name,
            "value" : var_value,
        }
        return constant

    def c_array(self, datatype, name, length=None, var_list=None, do_comments=False):
        """
        Method: c_array
        Purpose: converts all the HoksterInstructions to a large C array
        Inputs: 
            datatype (string): the output datatype of the C array.  Should be "char" or "uint8_t"
            name (string): the name of the c array
            length (int): number of instructions in the C array, if None, set to length of instructions
            var_list (list): a list of values to insert into the c array.  Generally used for hokster memory
            do_comments (bool): if true, append the original comments to the c array item
        Output:
            c_string (string): a string containing the resultant C array.
        """
        if length == None:
            length = str(len(self.instructions))

        c_string = datatype + " " + name + "[" + length + "] = {\n"

        #for non-instructions
        if var_list != None:
            c_string += "\t"
            c_string += ",\n\t".join(var_list)

        #for instructions
        else:
            for instruction in self.instructions:
                if instruction.is_instr:
                    c_string += instruction.to_c(do_comments)

        c_string += "\n};"
        return c_string
    
    def data_to_clist(self):
        """
        Method: data_to_clist
        Purpose: converts the program data to a c-ready python list
        Inputs:
        Output:
            data_list (list): the data memory converted to a list of valid c hex values
        """
        addr = 0
        data_list = []
        for key in self.hokster_ref.data.keys():
            #zero fill until we hit our target address
            while addr != cvt_base_to_int(key):
                data_list.append("0x00")
                addr += 1

            #output each memory address
            for idx,v in enumerate(self.hokster_ref.data[key]):
                addr += 1
                val_int = cvt_base_to_int(v)
                val_bin = cvt_int_to_bin(val_int, 8)
                val_hex = cvt_bin_to_hex(val_bin)
                data_list.append("0x" + str(val_hex))

                if key == list(self.hokster_ref.data.keys())[-1] and idx == len(self.hokster_ref.data[key]) - 1:
                    break
        return data_list

    def to_vhdl(self, asm_file, data_file, do_comments=False):
        """
        Method: to_vhdl
        Purpose: converts the list of HoksterInstructions to VHDL (obsolete-- no need for VHDL output.)
                 Remove this in later versions
        Inputs: 
            asm_file (string): the name of the program file to output to
            data_file (string): data file to ouput to
            do_comments (bool): if true, appends vhdl comments to the end of every instruction
        Output:
            f (file): the program file to write output to
        """
        vhdl_str = ""
        for instruction in self.instructions:
            if instruction.is_instr:
                vhdl_str += instruction.to_vhdl(do_comments)
        
        with open(asm_file, 'w') as f:
            f.write(vhdl_str)

    def to_hex(self, asm_file, data_file, do_comments=False):
        """
        Method: to_hex
        Purpose: writes the hokster instructions to a hex file
        Inputs: 
            asm_file (string): the name of o
        Output:
        """
        with open(asm_file, "w") as asm_f:
            for instruction in self.instructions:
                if instruction.is_instr:
                    asm_f.write(instruction.to_newline_hex(do_comments) + '\n')


    def to_c(self, prog_output, data_output, do_comments=False):
        instructions = sum([i.num_cycles for i in self.instructions if i.is_instr])
        prog_len = self.c_constant("PROG_LEN", instructions)
        prog_arr = self.c_array("uint8_t", "HOKSTER_INSTRUCTIONS", prog_len["name"], do_comments=do_comments)

        #write the data array
        if len(self.hokster_ref.data) != None:
            data_list = self.data_to_clist()
            data_len = self.c_constant("DATA_LEN", len(data_list))
            data_arr = self.c_array("uint8_t", "HOKSTER_MEMORY", data_len["name"], var_list=self.data_to_clist(), do_comments=do_comments)

        #write program file
        with open(prog_output, "w") as prog:
            prog.write("\n{}\n".format(prog_len["string"]))

            #if we're writing everything to the same file
            if prog_output == data_output:
                prog.write("\n{}\n".format(data_len["string"]))
                prog.write("\n{}\n".format(data_arr))

            prog.write("\n{}\n".format(prog_arr))

        #data in a seperate file
        if prog_output != data_output:
            with open(data_output, "w") as d:
                d.write("\n{}\n".format(data_len["string"]))
                d.write("\n{}\n".format(data_arr))
            

    def write_data_file(self, output, f="hex", debug_print=False):
        if debug_print:
            print("Writing data to {}".format(output))

        #don't write anything if there's no data file
        if len(self.hokster_ref.data) != 0:
            with open(output, "w") as out:
                addr = 0
                for key in self.hokster_ref.data.keys():
                    #zero fill until we hit our target address
                    while addr != cvt_base_to_int(key):
                        out.write("00\n")
                        addr += 1

                    #output each memory address
                    for idx,v in enumerate(self.hokster_ref.data[key]):
                        if debug_print:
                            print("Memory Location {} == {}".format(str(key), hex(v)))

                        addr += 1
                        val_int = cvt_base_to_int(v)
                        val_bin = cvt_int_to_bin(val_int, 8)
                        val_hex = cvt_bin_to_hex(val_bin)
                        out.write("{}".format(val_hex))

                        if key == list(self.hokster_ref.data.keys())[-1] and idx == len(self.hokster_ref.data[key]) - 1:
                            break
                        out.write("\n")


    def parse_file(self, filename, debug_print=False):
        '''
        Do two passes: 
            1st pass grabs labels, constants, directives, and addresses
            2nd pass parses the assembly
        '''
        parse_file = open(filename, "r")
        first_pass_errors = []

        #first pass, grab all directives
        PC                  = 0

        #first pass, fetch labels and constants
        for idx,line in enumerate(parse_file.readlines()):
            line = line.strip()
            temp_line = {
                'unparsed'  : '',
                'comment': None,
                'label'  : None,
                'PC'     : PC,
            }

            # if the line has a comment, ignore it for now
            comment_pos = self.hokster_ref.get_comment_pos(line)
            if comment_pos != -1:
                temp_line["comment"] = self.hokster_ref.get_comment_from_line(line, comment_pos)
                line = line[:comment_pos]

            #check for directives, add any we find to the HoksterRef
            #blank lines and directives don't contribute to the PC counter
            #TODO: directive parser class
            if line.startswith('.'):
                type_d = self.hokster_ref.get_directive_type(line[1:])

                #if we're looking at a label, add the label and value to self.hokster_ref
                if type_d == 'lbl':
                    #split labels on whitespace, strip and add to label set
                    lbl_name = line[1:].split()[1].strip()
                    temp_line['label'] = lbl_name
                    self.hokster_ref.labels[lbl_name] = hex(PC)
                
                elif type_d == 'equ':
                    #add constants
                    args       = line[1:].split()
                    name, val  = args[1].strip(),args[2].strip()
                    self.hokster_ref.constants[name] = val

                    if not self.hokster_ref.is_valid_constant(val):
                        first_pass_errors.append((HoksterError("CONST_INVALID"),"Error on line {}, '{}' ".format(idx+1, line)))

                elif type_d == "dat":
                    #add data
                    args       = line[1:].split()
                    memloc     = args[1].strip()

                    if not self.hokster_ref.is_valid_mem_address(memloc):
                        first_pass_errors.append((HoksterError("INVALID_MEM_ADDRESS"),"Error on line {}, '{}' ".format(idx+1, line)))

                    other_args = [a.replace(",", "").strip() for a in args[2:]]

                    for arg in other_args:
                        if not self.hokster_ref.is_valid_constant(arg):
                            first_pass_errors.append((HoksterError("CONST_INVALID"),"Error on line {}, '{}' ".format(idx+1, line)))

                    self.hokster_ref.data[memloc] = other_args

                elif type_d == "align":

                    #make sure we have space to align to a 16-byte boundary
                    next_boundary = 16 * math.ceil(PC/16)
                    num_nops      = next_boundary - PC

                    if next_boundary > pow(2, 12):
                        first_pass_errors.append((HoksterError("ADDRESS_OUT_OF_BOUNDS"),"Error on line {}, '{}' ".format(idx+1, line)))

                    for i in range(num_nops):
                        new_instr = HoksterInstruction("single_cycle_nop", PC, None, from_asm=True)
                        self.instructions.append(new_instr)
                        PC    = new_instr.get_next_PC()
                        

                #TODO: .end
                else:
                    pass
            
            else:
                new_instr = HoksterInstruction(line, PC, temp_line["comment"])

                if new_instr.is_instr:
                    PC    = new_instr.get_next_PC()
                
                #add to our unparsed lines
                self.instructions.append(new_instr)
        
        if len(first_pass_errors) > 0:
            for error,msg in first_pass_errors:
                error.printError(msg)
            if debug_print:
                prRed("Failed first pass of assembler.")
            self.has_errors = True
            return

        if debug_print:
            print("CONSTANTS: {}".format(self.hokster_ref.constants))
            print("LABELS: {}".format(self.hokster_ref.labels))
            print("DATA: {}".format(self.hokster_ref.data))
        

        self.found_sys = False
        for index,instruction in enumerate(self.instructions):
            line_num = index + 1
            instruction.parse(debug_print=debug_print)

            if instruction.hasErrors():
                self.has_errors = True

                if debug_print:
                    for err in instruction.errors:
                        err.printError("Error on Line {}, '{}' ".format(str(line_num),instruction.unparsed))
            
            elif instruction.instr_list != None:
                if instruction.instr_list == ["sys", "0xFF"]:
                    self.found_sys = True
        
        if self.found_sys == False:
            if debug_print:
                prRed("Missing 'sys 0xFF' call at end of program")
            self.has_errors = True

class HoksterError():
    '''
    Class: HoksterError
    Purpose: Store, define, and output errors for the Hokster Architecture

    '''
    _errors = {
        #map the error to the corresponding output function
        'NONE'          :  {"priority" : 0, "print" : ""}, #No error found
        'UNKNOWN_ERR'   :  {"priority" : 2, "print" : "Unknown error"}, #Error not known or undefined
        'LABEL_DNE'     :  {"priority" : 2, "print" : "Unknown label"}, #reference to a label that does not exist
        'LABEL_SYNTAX'  :  {"priority" : 2, "print" : "Label syntax invalid"}, #a line contains a label that is formatted improperly
        'LABEL_DUPLICATE': {"priority" : 2, "print" : "Duplicate label"}, #duplicate labels
        'OPERATOR_DNE'  :  {"priority" : 2, "print" : "Operator does not exist"}, #reference to an operator that is not yet implemented or doesn't exist
        'OPERATOR_SYNTAX': {"priority" : 2, "print" : "Operator syntax is invalid"}, #operator exists but is not correctly formatted
        'OPERATOR_MISSING_ARGS': {"priority" : 2, "print" : "Operator is missing args"}, #operator is missing required arguments
        'REGISTER_DNE'  :  {"priority" : 2, "print" : "Invalid register"}, #reference to a register that does not exist
        'REGISTER_SYNTAX': {"priority" : 2, "print" : "Register improperly formatted"}, #improperly referenced register (a$1, a, etc)
        'CONST_UNPARSABLE':{"priority" : 2, "print" : "Constant unparsable"}, #input constant is not parsable (unsupported number format)
        'CONST_INVALID' :  {"priority" : 2, "print" : "Constant invalid"}, #input constant is larger/smaller than the allowed value
        'CONST_DUPLICATE': {"priority" : 1, "print" : "Constant already defined"}, #constant is recorded twice
        'UNKNOWN_ARG': {"priority" : 2, "print" : "Unknown argument"}, #constant is recorded twice
        'INVALID_REG_FOR_ARG': {"priority" : 2, "print" : "Register invalid for argument"},
        'INVALID_MEM_ADDRESS': {"priority" : 2, "print" : "Invalid memory address"},
        'ADDRESS_OUT_OF_BOUNDS': {"priority" : 2, "print" : "Address out of bounds"},
        'NOT_POWER_OF_TWO': {"priority" : 2, "print" : "Constant must be a power of two"},
    }
    def __init__(self, error=None):
        self.error          = None
        self.error_type     = None
        self.error_level    = 0
        self.setError(error)

    def printError(self, prepend="", postpend=""):
        err_str = prepend + self.error["print"] + postpend
        if self.error["priority"] > 1:
            prRed(err_str)
        elif self.error["priority"] > 0:
            prYellow(err_str)

    def setError(self, error):
        if error is None:
            self.error = self._errors["NONE"]
        elif error in self._errors.keys():
            self.error_type = error
            self.error = self._errors[error]
        else:
            self.error = self._errors["UNKNOWN_ERR"]

def main():

    #check if the input file exists:
    if not os.path.exists(args.input):
        print("Error, unable to find input file {}".format(str(args.input)))
        exit(EXIT_FAILURE)
    
    #make sure the user entered a valid output format
    if not args.format.lower() in VALID_FORMATS:
        print("Invalid input format {}".format(args.format))
        exit()

    #instantiate the file parser:
    hokster_parser = HoksterParser()

    #parse the file
    hokster_parser.parse_file(args.input, debug_print=True)

    #verify there are no errors
    if not hokster_parser.has_errors:
        hokster_parser.to_file(args.output, args.data, args.format, args.comments, debug_print=True)

    #otherwise output errors
    else:
        prRed("Unable to assemble file {}".format(args.input))

if __name__ == "__main__":
    main()