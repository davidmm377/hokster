import time
#progtime = time.time()
import sys
try: 
    from bitstring import BitArray
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "bitstring"])
    from bitstring import BitArray

import re
from enum import IntEnum, unique

@unique
class Debug(IntEnum):
    Non = 0
    Err = 1
    Warn = 2
    Test = 3

class Timeout(object):
    def __init__(self, seconds = 30):
        self._sec = seconds
        self._tamt = time.time() + self._sec
    def start(self, seconds = None):
        if seconds is not None:
            self._sec = seconds
        self._tamt = time.time() + self._sec
    def expired(self):
        return self._tamt < time.time()

class System(object):
    def __init__(self, sBits = 8):
        self._sBits = sBits
        self._sys = BitArray(int=0,length=sBits)
        self.DEBUG = Debug.Warn
    def isGood(self, sys):
        if sys is None:
            if self.DEBUG >= Debug.Err:
                print("SYS Error: sys is None")
            return sys
        if type(sys) is not BitArray:
            try:
                sys = BitArray(uint=sys, length=self._sBits)
            except ValueError as verror:
                if self.DEBUG >= Debug.Err:
                    print(verror)
                    print("SYS Error: {} is type {}".format(sys, type(sys)))
                return None
        return sys
    def write(self, sys):
        self._sys = sys
        self._changed = True
        if self.DEBUG >= Debug.Test:
            print("Write {} to SYS".format(sys.uint))
    def read(self):
        if self.DEBUG >= Debug.Test:
            print("Read {} from SYS".format(self._sys.hex))
        if self._sys.hex == 255:
            return "SYS: Exit"
        return self._sys.hex
    def bus(self,sys=None):
        if self.DEBUG >= Debug.Test:
            print("SYS: bus {}".format(sys))
        if sys is None:
            return self.read()
        else:
            sys = self.isGood(sys)
            if sys is not None:
                self.write(sys)

class ProgramState(object):
    def __init__(self, state = None):
        self._states = [
            "Op",
            "None",
            "Halt",
        ]
        self._intr = False
        if self.isGood_state(state):
            self._state = state
        else:
            self._state = "None"
    def isGood_state(self, state):
        if state in self._states:
            return True
        return False
    def _set_(self, state):
        if self.isGood_state(state):
            self._state = state
    def _get_(self):
        return self._state

def get_imm(args, base = 10):
    return int(''.join(args),base)

def reg_map(arg):
    if type(arg) is list:
        if len(arg) == 1:
            arg = arg[0]
    if 0 <= arg.uint < 8:
        return "r{}".format(arg.uint)
    elif arg.uint < 16:
        return "a{}".format(arg.uint-8)
    else:
        print ("unknown reg {}".format(arg.uint))
        return None

class Registers(object):
    def __init__(self, num_regs = 16, rbits = 8):
        self._rbits = rbits
        self._num_regs = num_regs
        self._reg = [BitArray(length = self._rbits) for i in range(num_regs)]
        self._regShadow = [BitArray(length = self._rbits) for i in range(num_regs)]
        self.DEBUG = Debug.Warn
    def validReg(self, reg):
        if 0 <= reg < self._num_regs:
            return True
        if self.DEBUG >= Debug.Err:
            print("Register Error: Invalid reg {}".format(reg))
        return False
    def toPair(self,reg):
        halfRegs = (int) (self._num_regs/2)
        if self.validReg(reg.uint):
            if reg.uint >= halfRegs:
                bx = self._reg[reg.uint-halfRegs].__copy__()
                bx.prepend(self._reg[reg.uint].__copy__())
                return bx
            else:
                bx = self._reg[reg.uint].__copy__()
                bx.prepend(self._reg[reg.uint-halfRegs].__copy__())
                return bx
        return None
    def _shadow_(self, write = False, Ns = 2):
        halfRegs = (int) (self._num_regs/2)
        if write:
            for i in range(Ns):
                self._regShadow[i].overwrite(self._reg[i],0)
                self._regShadow[i+halfRegs].overwrite(self._reg[i+halfRegs],0)
            #for i, bA in enumerate(self._reg):
            #    self._regShadow[i].overwrite(bA,0)
        else:
            for i in range(Ns):
                self._reg[i].overwrite(self._regShadow[i],0)
                self._reg[i+halfRegs].overwrite(self._regShadow[i+halfRegs],0)
            #for i, bA in enumerate(self._regShadow):
            #    self._reg[i].overwrite(bA,0)
        if self.DEBUG >= Debug.Test:
            if write:
                print("Copied registers to shadow registers.")
            else:
                print("Restored registers from shadow registers.")
    def isGood_reg(self, reg):
        if reg is None:
            if self.DEBUG >= Debug.Err:
                print("Register Error: reg is None")
            return reg
        if type(reg) is list:
            if len(reg) == 1:
                reg = reg[0]
        if type(reg) is BitArray:
            reg = reg.uint
        elif type(reg) is not int:
            try:
                print("Reg: {}".format(reg))
                reg = int(reg)
            except TypeError:
                if self.DEBUG >= Debug.Err:
                    print("Register Error: {} is type {}".format(reg, type(reg)))
                return None
        if 0 <= reg <= self._num_regs:
            return reg
        if self.DEBUG >= Debug.Err:
            print("Register Error: {} is out of register bounds of 0 to {}".format(reg, self._num_regs))
        return None
    def isGood_word(self,word):
        if word is None:
            return None
        if type(word) is not BitArray:
            raise TypeError("Reg Word must be bit array.")
        return word
    def write(self, reg, word):
        if type(word) is BitArray:
            self._reg[reg] = word
        elif type(word) is int:
            self._reg[reg].int = word
        if self.DEBUG >= Debug.Test:
            print("Write {} at {}".format(word, reg))
    def read(self,reg):
        if self.DEBUG >= Debug.Test:
            print("Read {} at {}".format(self._reg[reg].int, reg))
        return self._reg[reg].__copy__()
    def bus(self, reg, word=None):
        if self.DEBUG >= Debug.Test:
            print("bus reg: {} word: {}".format(reg,word))
        reg = self.isGood_reg(reg)
        if reg is not None:
            if word is None:
                return self.read(reg)
            else:
                word = self.isGood_word(word)
                if word is not None:
                    self.write(reg,word)

class Memory(object): # TODO: add handling for reading unitialized memory
    def __init__(self, size = 0, word_width = 8, addr_width = 16):
        self._size = size
        self._maxaddr = size-1
        self._minaddr = 0
        self._w_width = word_width
        self._a_width = addr_width
        self._mem = [BitArray(length = self._w_width) for i in range(self._size)]
        self.DEBUG = Debug.Warn
    def isGood_word(self, word):
        if word is None:
            return word
        if type(word) is not BitArray:
            raise TypeError("Mem Word must be BitArray")
            # try:
            #     word = BitArray(int=word, length=self._w_width)
            # except ValueError:
            #     if self.DEBUG >= Debug.Err:
            #         print("Word Error: {} does not fit in word width {}.".format(word, self._w_width))
            #     return None
        return word
    def isGood_addr(self,address):
        if address is None:
            if self.DEBUG >= Debug.Err:
                print("Address Error: address is None")
            return address
        if type(address) is not int:
            if type(address) is BitArray:
                address = address.uint
                return address
            try:
                address = int(address)
            except ValueError:
                if self.DEBUG >= Debug.Err:
                    print("Address Error: {} is type {}".format(address, type(address)))
                return None
        return address
    def write(self, address, word):
        self._mem[address] = word
        if self.DEBUG >= Debug.Test:
            print("Write {} at {}".format(word, address))
    def read(self,address):
        if self.DEBUG >= Debug.Test:
            print("Read {} at {}".format(self._mem[address].int, address))
        return self._mem[address].__copy__()
    def bus(self,address,word=None):
        if self.DEBUG >= Debug.Test:
            print("bus addr: {} word: {}".format(address,word))
        address = self.isGood_addr(address)
        if address is not None:
            if word is None:
                return self.read(address)
            else:
                word = self.isGood_word(word)
                if word is not None:
                    self.write(address, word)

class Special_Regs(object):
    def __init__(self, dram: Memory = None, pc = 0, pcBits = 12, ie = 0, ieBits = 16, sp = 0):
        self._SP = self.StackPointer(sp, dram)
        self._IE = self.iEnable(ie, ieBits)
        self._wait = {}
        self._PC = self.ProgCount(pc, pcBits, self._wait)
        self._SR = self.StatusReg()
        
        self.DEBUG = Debug.Warn
    # nested Status Register class
    class StatusReg(object):
        def __init__(self, srBits = 8):
            self._srBits = srBits
            self._stat = BitArray(uint=0,length=self._srBits)
            self._sr = {
                "z" : 0,
                "n" : 1,
                "c" : 2,
                "x" : 3,   
                "u1" : 4,
                "u2" : 5,
                "u3" : 6,
                "u4" : 7
            }
            self._statShadow = self._stat.__copy__()
            self.DEBUG = Debug.Warn
        def status(self,flag = None):
            if flag is None:
                return self._stat.bin[::-1]
            return self._stat[self._sr[flag]]
        def _shadow_(self, write = False):
            if write:
                self._statShadow.overwrite(self._stat, 0)
            else:
                self._stat.overwrite(self._statShadow, 0)
            if self.DEBUG >= Debug.Test:
                if write:
                    print("Copying sr to shadow sr.")
                else:
                    print("Restoring sr from shadow sr.")
        def _set_(self, word):
            if type(word) is not BitArray:
                try:
                    word = BitArray(int=word, length=self._srBits)
                except Exception as ex:
                    print("StatusReg Error: In _set_, {}".format(ex))
            self._stat.overwrite(word, 0)
        def clear(self):
            self._stat.set(0)
        def zeroed(self, z):
            # arithmetic result of 0
            self._stat.set(z,self._sr["z"])
        def neged(self, n):
            # MSB = 1 in arithmetic
            self._stat.set(n,self._sr["n"])
        def carried(self, c):
            # carried in addition, borrowed in subtraction
            self._stat.set(c,self._sr["c"])
    # nested Program Counter class
    class ProgCount(object):
        def __init__(self, pc, pcBits, wait):
            self._pcBits = pcBits
            self._minPC = 0
            self._maxPC = 2**pcBits-1
            self._pc = BitArray(uint=pc, length=pcBits)
            self.DEBUG = Debug.Warn
            self._changed = False
            self._wait = wait
            self._pcShadow = self._pc.__copy__()
        def incr(self):
            if self._pc.uint + 1 > self._maxPC:
                return False
            self._pc.uint += 1
            if self.DEBUG >= Debug.Test:
                print("Incrementing PC.")
            return True
        def isGood(self, pc): # TODO: check for mid cycle
            if pc is None:
                if self.DEBUG >= Debug.Err:
                    print("PC Error: pc is None")
                return pc
            if type(pc) is not BitArray:
                try:
                    pc = BitArray(uint=pc, length=self._pcBits)
                except ValueError as verror:
                    if self.DEBUG >= Debug.Err:
                        print(verror)
                        print("PC Error: {} is type {}".format(pc, type(pc)))
                    return None
            return pc
        def _shadow_(self, write = False):
            if write:
                self._pcShadow = self._pc.__copy__()
            else:
                self.bus(self._pcShadow.__copy__())
            if self.DEBUG >= Debug.Test:
                if write:
                    print("Copying pc to shadow pc.")
                else:
                    print("Restoring pc from shadow pc.")
        def check_wait(self):
            for w in self._wait.keys():
                if self._wait[w][0]:
                    if self.DEBUG >= Debug.Test:
                        print("Waiting",w,self._wait[w][0])
                    return True
            return False
        def advance(self):
            if self.check_wait():
                return True
            if not self._changed:
                return self.incr()
            self._changed = False
            return True
        def write(self, pc):
            self._pc = pc
            self._changed = True
            if self.DEBUG >= Debug.Test:
                print("Write {} to PC".format(pc.hex))
        def read(self):
            if self.DEBUG >= Debug.Test:
                print("Read {} from PC".format(self._pc.hex))
            return self._pc
        def bus(self,pc=None):
            if self.DEBUG >= Debug.Test:
                print("bus pc: {}".format(pc))
            if pc is None:
                return self.read()
            else:
                pc = self.isGood(pc)
                if pc is not None:
                    self.write(pc)
    # nested interrupt Enable class
    class iEnable(object):
        def __init__(self, ie, ieBits):
            self._ieBits = ieBits
            self._ie = BitArray(uint=ie, length=ieBits)
            self.DEBUG = Debug.Warn
        def isGood_word(self, word):
            if word is None:
                return None
            if type(word) is not BitArray:
                raise TypeError("ienable Word must be BitArray")
            return word
        def read(self):
            a = int(self._ie.__len__()/2)
            if self.DEBUG >= Debug.Test:
                print("Read {} {} from iEnable a={}.".format(self._ie[:a].bin,self._ie[a:].bin,a))
            return (self._ie[:a], self._ie[a:])
        def write(self, words):
            if self.DEBUG >= Debug.Test:
                s = "".join(str(words))
                print("Write {} to iEnable.".format(s))
            for i, w in enumerate(words):             
                self._ie.overwrite(w,i*int(w.__len__()))
        def bus(self, words = None):
            if words is None:
                return self.read()
            else:
                for w in words:
                    w = self.isGood_word(w)
                if not any(w is None for w in words):
                    self.write(words)
    # nested Stack Pointer class
    class StackPointer(object):
        def __init__(self, sp, dram: Memory):
            self._dram = dram
            self._sp = BitArray(uint=sp, length=dram._a_width)
            self.DEBUG = Debug.Warn
        def isGood_addr(self, sp):
            sp = self._dram.isGood_addr(sp)
            if sp is not None:
                if type(sp) is BitArray:
                    return sp
                if type(sp) is not BitArray: #? unnecessary?
                    try:
                        sp = BitArray(uint=sp, length=self._dram._a_width)
                        return sp
                    except:
                        if self.DEBUG >= Debug.Err:
                            print("SP Error: {} is type {}".format(sp, type(sp)))
            return None
        def isGood_word(self, word):
            #//print("isGood_word?", word)
            word = self._dram.isGood_word(word)
            #//print("dram.word:",word)
            if word is not None:
                #//print("not none",type(word))
                if type(word) is BitArray:
                    return word
                if type(word) is not BitArray: #? unnecessary?
                    try:
                        word = BitArray(int=word, length=self._dram._w_width)
                        #//print("wordbA",word)
                        return word
                    except:
                        if self.DEBUG >= Debug.Err:
                            print("SP Error: {} is type {}".format(word, type(word)))
            return None
        def set_(self, sp):
            #print("SET??")
            sp = self.isGood_addr(sp)
            #print("sp set")
            if sp is not None:
                #print("not none")
                if type(sp) is int:
                    sp = BitArray(uint=sp, length=self._dram._a_width)
                #print("sp: {} type: {}".format(sp,type(sp)))
                if self.DEBUG >= Debug.Test:
                    print("SP set to {}".format(sp.hex))
                self._sp = sp#.__copy__()
            #else:
                #print("isGood_addr: ", sp)
        def isUnderflow(self, sp):
            if sp > self._dram._maxaddr:
                return 1
            return 0
        def isOverflow(self): # TODO: implement
            return 0
        def decr(self):
            #pass
            # # TODO: check for overflow into mem
            #sp = self._sp.uint
            if self._sp.uint > 0:
                self._sp.uint -= 1
                #sp -= 1
                #self._sp = BitArray(uint=sp, length=self._dram._a_width)
        def incr(self):
            if not self.isUnderflow(self._sp.uint + 1):
                self._sp.uint += 1
                #self._sp = BitArray(self._sp+1, length=self._dram._a_width)
        def write(self, word):
            self._dram.bus(self._sp, word)
            if self.DEBUG >= Debug.Test:
                print("Write {} to SP={} over d-bus".format(word.int,self._sp.hex))
        def read(self):
            word = self._dram.bus(self._sp)
            if self.DEBUG >= Debug.Test:
                print("Read {} from SP={} over d-bus".format(word.int,self._sp.hex))
            return word
        def bus(self,word=None):
            if self.DEBUG >= Debug.Test:
                print("bus SP: {}".format(word))
            self._sp = self.isGood_addr(self._sp)
            if self._sp is not None:
                #//print("read/write")
                if word is None:
                    #//print("read")
                    return self.read()
                else:
                    #//print("write?")
                    word = self.isGood_word(word)
                    if word is not None:
                        #//print("write")
                        self.write(word)
        def push(self, word=None):
            if self.DEBUG >= Debug.Test:
                print("Pushing {} onto stack".format(word))
            if word is not None:
                self.bus(word)
                self.decr() #* stack grows downwards
            elif self.DEBUG >= Debug.Warn:
                print("Stack Warning: pushing None onto stack ignored.")
        def pop(self):
            self.incr() #* stack shrinks upwards
            word = self.bus()
            if self.DEBUG >= Debug.Test:
                print("Popping {} from stack".format(word))
            return word

class Instruction(object):
    def __init__(self, mnem, call, opc1, opc2 = None, cycles = 2):
        self._mnem = mnem
        self._opc1 = opc1
        self._opc2 = opc2
        self._call = call
        self._cycles = cycles

class Instr_ALU(Instruction):
    def __init__(self, mnem, call, opc2, cycles = 2):
        super(Instr_ALU,self).__init__(mnem, call, 9, opc2)

class Instr_GEN1(Instruction):
    def __init__(self, mnem, call, opc2, cycles = 2):
        super(Instr_GEN1,self).__init__(mnem, call, 12, opc2, cycles=cycles)

class Instr_ALUC1(Instruction):
    def __init__(self, mnem, call, opc2, cycles = 2):
        super(Instr_ALUC1,self).__init__(mnem, call, 10, opc2)

class Instr_ALUC2(Instruction):
    def __init__(self, mnem, call, opc2, cycles = 2):
        super(Instr_ALUC2,self).__init__(mnem, call, 11, opc2)

class Occurrence(object):
    def __init__(self):
        self.occ = {}
    def occur(self, mnem):
        if mnem in self.occ:
            self.occ[mnem] += 1
        else:
            self.occ[mnem] = 1
        
class Operation(object):
    def __init__(self, instr : Instruction, meta):
        self._instr = instr
        self._meta = meta
        self._cycles = instr._cycles
        self._op = {i:None for i in range(instr._cycles)}
        self._op[0] = self.recognize
        self._op[self._cycles-1] = self._instr._call
        self._cur = 0
        self.DEBUG = Debug.Warn
    def recognize(self, *args, **kwargs):
        if self.DEBUG >= Debug.Test:
            return "{} recognized.".format(self._instr._mnem)
        return self._instr._mnem
    def zero(self,*args,**kwargs):
        ret = self._op[0](args)
        self._meta._occur.occur(self._instr._mnem)
        return ret
    def call(self, cycle, *args, **kwargs):
        return self._op[cycle](*args,**kwargs)

class OpISE(Operation):
    def __init__(self, instr : Instruction, meta):
        super(OpISE,self).__init__(instr, meta)
        self._states = {}
        self._mapst = {}
        self._enumst = {}
        self._wait_req = [0]
    def state_init(self, sts, stm):
        self.states(sts)
        self.mapst(stm)
    def states(self, sts):
        self._states = sts.copy()
        self._enumst = dict([(value, key) for key, value in self._states.items()])
        self._state = self._enumst[len(self._enumst)-1]
    def mapst(self, stm):
        self._mapst = stm.copy()    
    def is_Done(self):
        return self._state == self._enumst[len(self._enumst)-1]

class Handle_OPC1(object):
    def __init__(self, core, meta):
        self._core = core
        self._meta = meta
        self._regs = core._regs
        self._dram = core._dram
        self._srgs = core._srgs
        self._iVects = core._iVects
        self._instrs = {
            "mvs" : Instruction("mvs", self.op_mvs, 0),
            "mvv" : Instruction("mvv", self.op_mvv, 1),
            "jmp" : Instruction("jmp", self.op_jmp, 2),
            "jsr" : Instruction("jsr", self.op_jsr, 3),
            "bzi" : Instruction("bzi", self.op_bzi, 4),
            "bni" : Instruction("bni", self.op_bni, 5),
            "bci" : Instruction("bci", self.op_bci, 6),
            "bxi" : Instruction("bxi", self.op_bxi, 7),
            "mvi" : Instruction("mvi", self.op_mvi, 8),
            "alu" : Instruction("alu", self.op_alu, 9,cycles=-2),
            "aluc1":Instruction("aluc1", self.op_aluc1, 10,cycles=-2),
            "aluc2":Instruction("aluc2", self.op_aluc2, 11,cycles=-2),
            "gen1" :Instruction("gen1", self.op_gen1, 12,cycles=-2),
            "psh" : Instruction("psh", self.op_psh, 13, cycles=1),
            "pop" : Instruction("pop", self.op_pop, 14, cycles=1),
        }
        self._ops = {}
        self._opc1_dict = {}
        for ins in self._instrs.values():
            self._ops.update({ins._mnem: Operation(ins, meta)})
            self._opc1_dict.update({ins._opc1:ins._mnem})
            self._meta._occur.occ.update({ins._mnem:0})
        delk = [key for key in self._meta._occur.occ if len(key) > 3]
        for key in delk: del(self._meta._occur.occ[key])
                
        self.DEBUG = Debug.Test
        self._ops["jsr"]._op[0] = self.op_jsr_0
    ##opc1 ops
    def op_mvs(self, args):
        im = BitArray().join(args[0:3])
        im.int = im.int
        #im = BitArray(int=im.int - 1,length=im.len) 
        im = (im << 4)
        self._srgs._SP.set_(im)
        if self.DEBUG >= Debug.Test:
            return "{} called with <im[11..0]>={}".format(sys._getframe().f_code.co_name[3:],im)
        
    def op_mvv(self, args):
        dst = args[0]
        im = BitArray().join(args[1:3])
        # try:
        #     iV = BitArray(uint=im, length=8)
        # except ValueError as verror: #? can this occur
        #     iV = BitArray(uint=0,length=8)
        #     if self.DEBUG >= Debug.Err:
        #         print("op_mvv Error: {}".format(verror))
        self._iVects.bus(dst,im)
        if self.DEBUG >= Debug.Test:
            return "{} called with <opc2=dst>: {} <im[7..0]>={}".format(sys._getframe().f_code.co_name[3:], reg_map(dst), self._meta.repr(im))
        
    def op_jmp(self, args):
        im = BitArray().join(args[0:3])
        self._srgs._PC.bus(im)
        if self.DEBUG >= Debug.Test:
            return "{} called with <im[11..0]>={}".format(sys._getframe().f_code.co_name[3:], im)
        
    def op_jsr_0(self,args): #* first cycle of jsr
        upper = BitArray(uint=self._srgs._PC.bus().uint+2,length=self._srgs._PC._pcBits)[:4]
        upper.prepend('0b0000')
        self._srgs._SP.push(upper)
        if self.DEBUG >= Debug.Test:
            return "{} recognized and PC[11..8]+2={} pushed onto stack.".format(sys._getframe().f_code.co_name[3:],self._meta.repr(upper))
    
    def op_jsr(self, args): #* second cycle of jsr
        im = BitArray().join(args[0:3])
        #pc8 = BitArray(uint=self._srgs._PC.bus()+1,length=12)
        #pc8.__irshift__(8)
        lower = BitArray(uint=self._srgs._PC.bus().uint+1,length=self._srgs._PC._pcBits)[4:]
        self._srgs._SP.push(lower)
        self._srgs._PC.bus(im)
        if self.DEBUG >= Debug.Test:
            return "{} called with <lower>={} <im[11..0]>={}".format(sys._getframe().f_code.co_name[3:], self._meta.repr(lower), self._meta.repr(im))
    def op_bzi(self, args): 
        im = BitArray().join(args[0:3])
        branch = self._srgs._SR.status("z")
        if branch:
            self._srgs._PC.bus(im)
        if self.DEBUG >= Debug.Test:
            return "{} called with <im[11..0]>={} Branched: {}".format(sys._getframe().f_code.co_name[3:], self._meta.repr(im), bool(branch))
    def op_bni(self, args):
        im = BitArray().join(args[0:3])
        branch = self._srgs._SR.status("n")
        if branch:
            self._srgs._PC.bus(im)
        if self.DEBUG >= Debug.Test:
            return "{} called with <im[11..0]>={} Branched: {}".format(sys._getframe().f_code.co_name[3:], self._meta.repr(im), bool(branch))
    def op_bci(self, args):
        im = BitArray().join(args[0:3])
        branch = self._srgs._SR.status("c")
        if branch:
            self._srgs._PC.bus(im)
        if self.DEBUG >= Debug.Test:
            return "{} called with <im[11..0]>={} Branched: {}".format(sys._getframe().f_code.co_name[3:], self._meta.repr(im), bool(branch))
    def op_bxi(self, args):
        im = BitArray().join(args[0:3])
        branch = self._srgs._SR.status("x")
        if branch:
            self._srgs._PC.bus(im)
        if self.DEBUG >= Debug.Test:
            return "{} called with <im[11..0]>={} Branched: {}".format(sys._getframe().f_code.co_name[3:], self._meta.repr(im), bool(branch))
    def op_mvi(self, args):
        dst = args[0].__copy__()
        im = BitArray().join(args[1:3])
        self._regs.bus(dst,im)
        if self.DEBUG >= Debug.Test:
            return "{} called with <opc2=dst>: {} <im[7..0]>={}".format(sys._getframe().f_code.co_name[3:], reg_map(dst), self._meta.repr(im))
    def op_alu(self, args): #? what to do with this
        if self.DEBUG >= Debug.Test:
            print (sys._getframe().f_code.co_name[3:] + " called with args", args)
    def op_aluc1(self, args): #? what to do with this
        if self.DEBUG >= Debug.Test:
            print (sys._getframe().f_code.co_name[3:] + " called with args", args)
    def op_aluc2(self, args): #? what to do with this
        if self.DEBUG >= Debug.Test:
            print (sys._getframe().f_code.co_name[3:] + " called with args", args)
    def op_gen1(self, args): #? what to do with this
        if self.DEBUG >= Debug.Test:
            print (sys._getframe().f_code.co_name[3:] + " called with args", args)
    def op_psh(self, args):
        if type(args[0]) is list:
            src = args[0][0].__copy__()
        else:
            src = args[0].__copy__()
        word = self._regs.bus(src)
        self._srgs._SP.push(word)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src>: {}={}".format(sys._getframe().f_code.co_name[3:], reg_map(src), self._meta.repr(word))
    def op_pop(self, args):
        
        if type(args[0]) is list:
            dst = args[0][0].__copy__()
        else:
            dst = args[0].__copy__()
        word = self._srgs._SP.pop()
        
        self._regs.bus(dst, word)
        if self.DEBUG >= Debug.Test:
            return "{} called with <dst>: {}={}".format(sys._getframe().f_code.co_name[3:], reg_map(dst), self._meta.repr(word))

class Handle_ALU(object):
    def __init__(self, core, meta):
        self._core = core
        self._meta = meta
        self._regs = core._regs
        self._dram = core._dram
        self._srgs = core._srgs
        self._instrs = {
            "add" : Instr_ALU("add",self.op_add,0),
            "sub" : Instr_ALU("sub",self.op_sub,1),
            "and" : Instr_ALU("and",self.op_and,2),
            "lor" : Instr_ALU("lor",self.op_lor,3),
            "sll" : Instr_ALU("sll",self.op_sll,4),
            "rol" : Instr_ALU("rol",self.op_rol,5),
            "slr" : Instr_ALU("slr",self.op_slr,6),
            "ror" : Instr_ALU("ror",self.op_ror,7),
            "alu8": Instr_ALU("alu8",self.op_alu8,8), #* reserved
            "alu9": Instr_ALU("alu9",self.op_alu9,9), #* reserved
            "not" : Instr_ALU("not",self.op_not,10),
            "xor" : Instr_ALU("xor",self.op_xor,11),
            "adc" : Instr_ALU("adc",self.op_adc,12),
            "sbc" : Instr_ALU("sbc",self.op_sbc,13),
            "adi" : Instr_ALU("adi",self.op_adi,14),
            "sbi" : Instr_ALU("sbi",self.op_sbi,15)
        }
        self._ops = {}
        self._opc2_dict = {}
        for ins in self._instrs.values():
            self._ops.update({ins._mnem: Operation(ins,meta)})
            self._opc2_dict.update({ins._opc2: ins._mnem})
            self._meta._occur.occ.update({ins._mnem:0})
        delk = [key for key in self._meta._occur.occ if len(key) > 3]
        for key in delk: del(self._meta._occur.occ[key])
        self.DEBUG = Debug.Test
    ##ALU ops
    def op_add(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        res = BitArray(uint=s1.uint + s2.uint,length=s2.__len__()+1)
        self._srgs._SR.carried(res[0])
        res.__delitem__(0)
        self._srgs._SR.neged(res[0])
        self._srgs._SR.zeroed(res.int == 0)
        self._regs.bus(args[1],res)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={} <src2=dst> {}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),self._meta.repr(res))
        
    def op_sub(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        s2t = BitArray(uint=s2.uint,length=s2.__len__())
        s2t.invert()
        s2t = BitArray(uint=s2t.uint + 1,length=9)
        s2t.__delitem__(0)
        res = BitArray(uint=s1.uint + s2t.uint,length=s2.__len__()+1)
        res.__delitem__(0)
        # self._srgs._SR.carried(res[0] != s1[0])
        self._srgs._SR.carried('0' + s1.bin < '0' + s2.bin)
        self._srgs._SR.neged(res[0])
        self._srgs._SR.zeroed(res.int == 0)
        self._regs.bus(args[1],res)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={} <src2=dst> {}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),self._meta.repr(res))
        
    def op_and(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        s2 = s1 & s2
        self._regs.bus(args[1], s2)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={} <src2=dst> {}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),self._meta.repr(s2))
        
    def op_lor(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        s2 = s1 | s2
        self._regs.bus(args[1], s2)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={} <src2=dst> {}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),self._meta.repr(s2))
        
    def op_sll(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        if s1.int < 0 and self.DEBUG >= Debug.Warn:
            print("Warning: sll with negative value taken as unsigned.")
        s2.__ilshift__(s1.uint)
        self._regs.bus(args[1], s2)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={} <src2=dst> {}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),self._meta.repr(s2))
        
    def op_rol(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        if s1.int < 0 and self.DEBUG >= Debug.Warn:
            print("Warning: rol with negative value taken as unsigned.")
        s2.rol(s1.uint)
        self._regs.bus(args[1], s2)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={} <src2=dst> {}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),self._meta.repr(s2))
        
    def op_slr(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        if s1.int < 0 and self.DEBUG >= Debug.Warn:
            print("Warning: slr with negative value taken as unsigned.")
        s2.__irshift__(s1.uint)
        self._regs.bus(args[1], s2)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={} <src2=dst> {}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),self._meta.repr(s2))
        
    def op_ror(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        if s1.int < 0 and self.DEBUG >= Debug.Warn:
            print("Warning: ror with negative value taken as unsigned.")
        s2.ror(s1.uint)
        self._regs.bus(args[1], s2)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={} <src2=dst> {}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),self._meta.repr(s2))
        
    def op_not(self, args):
        src = self._regs.bus(args[0])
        res = src.__copy__()
        res.invert()
        dst = self._regs.bus(args[1])
        self._regs.bus(args[1], res)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1>{}={} <dst>{}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(src),reg_map(args[1]),self._meta.repr(dst),self._meta.repr(res))
    def op_xor(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        s2 = s1 ^ s2
        self._regs.bus(args[1], s2)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={} <src2=dst> {}={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),self._meta.repr(s2))

    def op_adc(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        cflag = self._srgs._SR.status("c")
        res = BitArray(uint=s1.uint + s2.uint + cflag,length=s2.__len__()+1)
        self._srgs._SR.carried(res[0])
        res.__delitem__(0)
        self._srgs._SR.neged(res[0])
        self._srgs._SR.zeroed(res.int == 0)
        self._regs.bus(args[1],res)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={}, <src2=dst> {}={}, sr[c]={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),cflag,self._meta.repr(res))
        
    def op_sbc(self, args):
        s1 = self._regs.bus(args[0]).__copy__()
        s2 = self._regs.bus(args[1]).__copy__()
        src2 = s2.__copy__()
        cflag = self._srgs._SR.status("c")
        
        s2t = BitArray(uint=s2.uint,length=s2.__len__())
        s2t.invert()
        s2t = BitArray(uint=s2t.uint + 1,length=9)
        s2t.__delitem__(0)
        cft = BitArray(uint=cflag,length=s2.__len__())
        cft.invert()
        cft = BitArray(uint=cft.uint + 1,length=9)
        cft.__delitem__(0)
        res = BitArray(uint=s1.uint + s2t.uint + cft.uint,length=s2.__len__()+1)
        #self._srgs._SR.carried(res[0] != s1[0])
        res.__delitem__(0)
        # self._srgs._SR.carried(res[0] != s1[0])
        bC = BitArray(uint=s2.uint + cflag,length=s2.__len__()+1)
        self._srgs._SR.carried('0' + s1.bin < bC.bin)
        self._srgs._SR.neged(res[0])
        self._srgs._SR.zeroed(res.int == 0)
        self._regs.bus(args[1],res)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1> {}={}, <src2=dst> {}={}, sr[c]={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(s1),reg_map(args[1]),self._meta.repr(src2),cflag,self._meta.repr(res))
        
    def op_adi(self, args):
        s1 = self._regs.bus(args[1]).__copy__()
        im = args[0].__copy__()
        im.uint = im.uint + 1
        src1=s1.__copy__()
        res = BitArray(uint=s1.uint + im.uint,length=s1.__len__()+1)
        self._srgs._SR.carried(res[0])
        res.__delitem__(0)
        self._srgs._SR.neged(res[0])
        self._srgs._SR.zeroed(res.int == 0)
        self._regs.bus(args[1],res)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1=dst> {}={} <im[3..0]>={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[1]),self._meta.repr(src1),self._meta.repr(im),self._meta.repr(res))
        
    def op_sbi(self, args):
        s1 = self._regs.bus(args[1]).__copy__()
        im = args[0].__copy__()
        im.uint = im.uint + 1
        src1=s1.__copy__()
        imt = BitArray(uint=im.uint,length=s1.__len__())
        imt.invert()
        imt = BitArray(uint=imt.uint + 1,length=9)
        imt.__delitem__(0)
        res = BitArray(uint=s1.uint + imt.uint,length=s1.__len__()+1)
        res.__delitem__(0)
        #self._srgs._SR.carried(res[0] != s1[0])
        aINC = BitArray(uint=im.uint,length=s1.__len__()+1)
        self._srgs._SR.carried('0' + s1.bin < aINC.bin)
        self._srgs._SR.neged(res[0])
        self._srgs._SR.zeroed(res.int == 0)
        self._regs.bus(args[1],res)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src1=dst> {}={} <im[3..0]>={} result: {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[1]),self._meta.repr(src1),self._meta.repr(im),self._meta.repr(res))
        
    def op_alu8(self, args): #* unused
        print (sys._getframe().f_code.co_name[3:] + " called with args", args)
    def op_alu9(self, args): #* unused
        print (sys._getframe().f_code.co_name[3:] + " called with args", args)

class Handle_GEN1(object):
    def __init__(self, core, meta):
        self._core = core
        self._meta = meta
        self._regs = core._regs
        self._dram = core._dram
        self._srgs = core._srgs
        self._pState = core._pState
        self.DEBUG = Debug.Test
        
        self._instrs = {
            "mov" : Instr_GEN1("mov", self.op_mov, 0),
            "lxb" : Instr_GEN1("lxb", self.op_lxb, 1),
            "sxb" : Instr_GEN1("sxb", self.op_sxb, 2),
            "ret" : Instr_GEN1("ret", self.op_ret, 3),
            "str" : Instr_GEN1("str", self.op_str, 4, cycles=1),
            "lsr" : Instr_GEN1("lsr", self.op_lsr, 5, cycles=1),
            "rie" : Instr_GEN1("rie", self.op_rie, 6),
            "sie" : Instr_GEN1("sie", self.op_sie, 7),
            "hlt" : Instr_GEN1("hlt", self.op_hlt, 8, cycles=1),
            "rti" : Instr_GEN1("rti", self.op_rti, 9, cycles=1),
            "sys" : Instr_GEN1("sys", self.op_sys, 15)
        }
        self._ops = {}
        self._opc2_dict = {}
        for ins in self._instrs.values():
            self._ops.update({ins._mnem: Operation(ins, meta)})
            self._opc2_dict.update({ins._opc2: ins._mnem})
            self._meta._occur.occ.update({ins._mnem:0})
        self._ops["ret"]._op[0] = self.op_ret_0
    def op_mov(self, args):
        src = args[0].__copy__()
        dst = args[1].__copy__()
        word = self._regs.bus(src)
        self._regs.bus(dst,word)
        if self.DEBUG >= Debug.Test:
            return "{} called with <src>: {}, <dst>: {}, word= {}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),reg_map(args[1]),self._meta.repr(word))
    def op_lxb(self, args):
        src = args[0].__copy__()
        Ri = src[1:].__copy__()
        wRi = self._regs.bus(Ri).__copy__()
        pairR = self._regs.toPair(Ri)
        dst = args[1].__copy__()
        word = self._dram.bus(pairR)
        self._regs.bus(dst,word)
        incr = src[0]
        if incr:
            wRi.int += incr
            self._regs.bus(Ri,wRi.__copy__())
        if self.DEBUG >= Debug.Test:
            if incr:
                return "lpb called with <src>: a{}&r{}, <dst>: {} word: {}".format(Ri.uint,Ri.uint,reg_map(args[1]),self._meta.repr(word))
            else:
                return "ldb called with <src>: a{}&r{}, <dst>: {} word: {}".format(Ri.uint,Ri.uint,reg_map(args[1]),self._meta.repr(word))
    def op_sxb(self, args):
        src = args[0].__copy__()
        dst = args[1].__copy__()
        Ri = dst[1:].__copy__()
        wRi = self._regs.bus(Ri).__copy__()
        pairR = self._regs.toPair(Ri)
        word = self._regs.bus(src)
        self._dram.bus(pairR,word)
        incr = dst[0]
        if incr:
            wRi.int += incr
            self._regs.bus(Ri,wRi.__copy__())
        if self.DEBUG >= Debug.Test:
            if incr:
                return "spb called with <src>: {} <dst>: a{}&r{} word: {}".format(reg_map(args[0]),Ri.uint,Ri.uint,self._meta.repr(word))
            else:
                return "stb called with <src>: {} <dst>: a{}&r{} word: {}".format(reg_map(args[0]),Ri.uint,Ri.uint,self._meta.repr(word))
    def op_ret_0(self,args): #? args not needed
        '''
        pc[11..8] = [sp+1]
        sp = sp + 1
        '''
        lower = self._srgs._SP.pop()
        #curPC = BitArray(uint=self._srgs._PC.bus(),length=self._srgs._PC._pcBits)
        curPC = self._srgs._PC.bus()
        curPC.overwrite(lower, curPC.__len__()-lower.__len__())
        self._srgs._PC.bus(curPC)
            
        if self.DEBUG >= Debug.Test:
            return "{} recognized. PC = {}.".format(sys._getframe().f_code.co_name[3:], self._meta.repr(curPC))
    def op_ret(self,args): #? args not needed
        '''
        pc[7..0] = [sp+1]
        sp = sp + 1
        '''
        upper = None
        try:
            upper = BitArray(self._srgs._SP.pop(),length=8)[4:]
        except Exception as ex:
            print("ret_Cycle_0 Error: {}".format(ex))
        if upper is not None:
            #curPC = BitArray(uint=self._srgs._PC.bus(),length=self._srgs._PC._pcBits)
            curPC = self._srgs._PC.bus()
            curPC.overwrite(upper, 0)
            self._srgs._PC.bus(curPC)
        
        if self.DEBUG >= Debug.Test:
            return "{} called. PC = {}".format(sys._getframe().f_code.co_name[3:], self._meta.repr(curPC))
    def op_str(self,args): #? args not needed
        status = self._srgs._SR.status()
        self._srgs._SP.push(status)
        if self.DEBUG >= Debug.Test:
            return "{} called with sr = {}.".format(sys._getframe().f_code.co_name[3:], status)
    def op_lsr(self,args): #? args not needed
        status = self._srgs._SP.pop()
        self._srgs._SR._set_(status)
        if self.DEBUG >= Debug.Test:
            return "{} called with status = {}.".format(sys._getframe().f_code.co_name[3:], status)
    def op_rie(self, args):
        dst = args[0].__copy__()
        Ri = dst[1:]
        Ai = Ri.__copy__()
        Ri.prepend('0b0')
        Ai.prepend('0b1')
        Aw, Rw = self._srgs._IE.bus()
        self._regs.bus(Ai, Aw)
        self._regs.bus(Ri, Rw)
        if self.DEBUG >= Debug.Test:
            return "{} called. IE={}{}".format(sys._getframe().f_code.co_name[3:],self._meta.repr(Aw),self._meta.repr(Rw))
    def op_sie(self, args):
        dst = args[0].__copy__()
        Ri = dst[1:]
        Ai = Ri.__copy__()
        Ri.prepend('0b0')
        Ai.prepend('0b1')
        Aw = self._regs.bus(Ai)
        Rw = self._regs.bus(Ri)
        self._srgs._IE.bus([Aw,Rw])
        if self.DEBUG >= Debug.Test:
            return "{} called. new IE={}{}".format(sys._getframe().f_code.co_name[3:],self._meta.repr(Aw),self._meta.repr(Rw))
    def op_hlt(self,args):
        self._pState._set_("Halt")
        if self.DEBUG >= Debug.Test:
            return "{} called. Program execution halted until valid interrupt.".format(sys._getframe().f_code.co_name[3:])
    def op_rti(self,args):
        self._srgs._PC._shadow_()
        self._srgs._SR._shadow_()
        self._regs._shadow_(False,self._meta._num_pairs_shadowed)
        self._pState._intr = False
        if self.DEBUG >= Debug.Test:
            return "{} called. Ns={} Ri, Ai Regs & SR, PC restored from shadows.".format(sys._getframe().f_code.co_name[3:],self._meta._num_pairs_shadowed)
    def op_sys(self, args):
        im = BitArray().join(args[0:2])
        self._core._sbus.bus(im)
        if self.DEBUG >= Debug.Test:
            return "{} called. im[7..0] = {}".format(sys._getframe().f_code.co_name[3:], self._meta.repr(im))

class AMC(OpISE):
        def __init__(self, instr : Instruction, meta):
            super(AMC,self).__init__(instr, meta)
            #self._core = core
            self._xtime_result = BitArray(hex='00')
            self._xtime_input = BitArray(hex='00')
            self._s = [0 for i in range(0,4)]
            self._sum = BitArray(hex='00')
        def reset(self):
            self._xtime_result = BitArray(hex='00')
            self._xtime_input = BitArray(hex='00')
            self._s = [0 for i in range(0,4)]
            self._sum = BitArray(hex='00')
            self._state = self._enumst[len(self._enumst)-1]
        
        def set_xtime(self):
            if self._xtime_input[0]:
                self._xtime_result = (self._xtime_input[1:] + 1) ^ BitArray(hex='1b')
            else:
                self._xtime_result = (self._xtime_input[1:] + 1)

class ASB(OpISE):
    def __init__(self, instr : Instruction, meta):
        super(ASB, self).__init__(instr,meta)
        self.init_map()
    def init_map(self):
        self._map = {
            0 : '63',
            1 : '7C',
            2 : '77',
            3 : '7B',
            4 : 'F2',
            5 : '6B',
            6 : '6F',
            7 : 'C5',
            8 : '30',
            9 : '01',
            10 : '67',
            11 : '2B',
            12 : 'FE',
            13 : 'D7',
            14 : 'AB',
            15 : '76',
            16 : 'CA',
            17 : '82',
            18 : 'C9',
            19 : '7D',
            20 : 'FA',
            21 : '59',
            22 : '47',
            23 : 'F0',
            24 : 'AD',
            25 : 'D4',
            26 : 'A2',
            27 : 'AF',
            28 : '9C',
            29 : 'A4',
            30 : '72',
            31 : 'C0',
            32 : 'B7',
            33 : 'FD',
            34 : '93',
            35 : '26',
            36 : '36',
            37 : '3F',
            38 : 'F7',
            39 : 'CC',
            40 : '34',
            41 : 'A5',
            42 : 'E5',
            43 : 'F1',
            44 : '71',
            45 : 'D8',
            46 : '31',
            47 : '15',
            48 : '04',
            49 : 'C7',
            50 : '23',
            51 : 'C3',
            52 : '18',
            53 : '96',
            54 : '05',
            55 : '9A',
            56 : '07',
            57 : '12',
            58 : '80',
            59 : 'E2',
            60 : 'EB',
            61 : '27',
            62 : 'B2',
            63 : '75',
            64 : '09',
            65 : '83',
            66 : '2C',
            67 : '1A',
            68 : '1B',
            69 : '6E',
            70 : '5A',
            71 : 'A0',
            72 : '52',
            73 : '3B',
            74 : 'D6',
            75 : 'B3',
            76 : '29',
            77 : 'E3',
            78 : '2F',
            79 : '84',
            80 : '53',
            81 : 'D1',
            82 : '00',
            83 : 'ED',
            84 : '20',
            85 : 'FC',
            86 : 'B1',
            87 : '5B',
            88 : '6A',
            89 : 'CB',
            90 : 'BE',
            91 : '39',
            92 : '4A',
            93 : '4C',
            94 : '58',
            95 : 'CF',
            96 : 'D0',
            97 : 'EF',
            98 : 'AA',
            99 : 'FB',
            100 : '43',
            101 : '4D',
            102 : '33',
            103 : '85',
            104 : '45',
            105 : 'F9',
            106 : '02',
            107 : '7F',
            108 : '50',
            109 : '3C',
            110 : '9F',
            111 : 'A8',
            112 : '51',
            113 : 'A3',
            114 : '40',
            115 : '8F',
            116 : '92',
            117 : '9D',
            118 : '38',
            119 : 'F5',
            120 : 'BC',
            121 : 'B6',
            122 : 'DA',
            123 : '21',
            124 : '10',
            125 : 'FF',
            126 : 'F3',
            127 : 'D2',
            128 : 'CD',
            129 : '0C',
            130 : '13',
            131 : 'EC',
            132 : '5F',
            133 : '97',
            134 : '44',
            135 : '17',
            136 : 'C4',
            137 : 'A7',
            138 : '7E',
            139 : '3D',
            140 : '64',
            141 : '5D',
            142 : '19',
            143 : '73',
            144 : '60',
            145 : '81',
            146 : '4F',
            147 : 'DC',
            148 : '22',
            149 : '2A',
            150 : '90',
            151 : '88',
            152 : '46',
            153 : 'EE',
            154 : 'B8',
            155 : '14',
            156 : 'DE',
            157 : '5E',
            158 : '0B',
            159 : 'DB',
            160 : 'E0',
            161 : '32',
            162 : '3A',
            163 : '0A',
            164 : '49',
            165 : '06',
            166 : '24',
            167 : '5C',
            168 : 'C2',
            169 : 'D3',
            170 : 'AC',
            171 : '62',
            172 : '91',
            173 : '95',
            174 : 'E4',
            175 : '79',
            176 : 'E7',
            177 : 'C8',
            178 : '37',
            179 : '6D',
            180 : '8D',
            181 : 'D5',
            182 : '4E',
            183 : 'A9',
            184 : '6C',
            185 : '56',
            186 : 'F4',
            187 : 'EA',
            188 : '65',
            189 : '7A',
            190 : 'AE',
            191 : '08',
            192 : 'BA',
            193 : '78',
            194 : '25',
            195 : '2E',
            196 : '1C',
            197 : 'A6',
            198 : 'B4',
            199 : 'C6',
            200 : 'E8',
            201 : 'DD',
            202 : '74',
            203 : '1F',
            204 : '4B',
            205 : 'BD',
            206 : '8B',
            207 : '8A',
            208 : '70',
            209 : '3E',
            210 : 'B5',
            211 : '66',
            212 : '48',
            213 : '03',
            214 : 'F6',
            215 : '0E',
            216 : '61',
            217 : '35',
            218 : '57',
            219 : 'B9',
            220 : '86',
            221 : 'C1',
            222 : '1D',
            223 : '9E',
            224 : 'E1',
            225 : 'F8',
            226 : '98',
            227 : '11',
            228 : '69',
            229 : 'D9',
            230 : '8E',
            231 : '94',
            232 : '9B',
            233 : '1E',
            234 : '87',
            235 : 'E9',
            236 : 'CE',
            237 : '55',
            238 : '28',
            239 : 'DF',
            240 : '8C',
            241 : 'A1',
            242 : '89',
            243 : '0D',
            244 : 'BF',
            245 : 'E6',
            246 : '42',
            247 : '68',
            248 : '41',
            249 : '99',
            250 : '2D',
            251 : '0F',
            252 : 'B0',
            253 : '54',
            254 : 'BB',
            255 : '16',
        }
    
    def get(self,a):
        return BitArray(hex=self._map[a.uint]).__copy__()

class SWD(OpISE):
    def __init__(self, instr : Instruction, meta):
        super(SWD, self).__init__(instr,meta)
        self._shifter_out = BitArray(hex='00000000')
        self._shifter_in = BitArray(hex='00000000')
        self._shift_amount = BitArray(bin='00000')
    def reset(self):
        self._shifter_out = BitArray(hex='00000000')
        self._shifter_in = BitArray(hex='00000000')
        self._shift_amount = BitArray(bin='00000')
        self._state = self._enumst[len(self._enumst)-1]
    def set_shift_out(self):
        tmp = self._shifter_in << self._shift_amount.uint
        tmp2 = self._shifter_in >> 32 - self._shift_amount.uint
        self._shifter_out = tmp | tmp2

class GSP(OpISE):
    def __init__(self, instr : Instruction, meta):
        super(GSP, self).__init__(instr,meta)
        self._sbox_a = BitArray(hex='00')
        self._sbox_b = BitArray(hex='00')
        self._in = BitArray(uint=0, length=128)
        self._out = BitArray(uint=0, length=128)
    def reset(self):
        self._sbox_a = BitArray(hex='00')
        self._sbox_b = BitArray(hex='00')
        self._in = BitArray(uint=0, length=128)
        self._out = BitArray(uint=0, length=128)
        self._state = self._enumst[len(self._enumst)-1]
    def gift_sbox(self, inp):
        sbox_map = [
            "1",
            "a", 
            "4",
            "c",
            "6",
            "f",
            "3",
            "9",
            "2",
            "d",
            "b",
            "7",
            "5",
            "0",
            "8",
            "e" ]
        return BitArray(hex=sbox_map[inp[0:4].uint]+sbox_map[inp[4:].uint])
    def gift_perm(self):
        inp = self._in.__copy__()[::-1]
        out = BitArray(uint=0,length=128)
        out[0]   = inp[0]
        out[33]  = inp[1]
        out[66]  = inp[2]
        out[99]  = inp[3]
        out[96]  = inp[4]
        out[1]   = inp[5]
        out[34]  = inp[6]
        out[67]  = inp[7]
        out[64]  = inp[8]
        out[97]  = inp[9]
        out[2]   = inp[10]
        out[35]  = inp[11]
        out[32]  = inp[12]
        out[65]  = inp[13]
        out[98]  = inp[14]
        out[3]   = inp[15]
        out[4]   = inp[16]
        out[37]  = inp[17]
        out[70]  = inp[18]
        out[103] = inp[19]
        out[100] = inp[20]
        out[5]   = inp[21]
        out[38]  = inp[22]
        out[71]  = inp[23]
        out[68]  = inp[24]
        out[101] = inp[25]
        out[6]   = inp[26]
        out[39]  = inp[27]
        out[36]  = inp[28]
        out[69]  = inp[29]
        out[102] = inp[30]
        out[7]   = inp[31]
        out[8]   = inp[32]
        out[41]  = inp[33]
        out[74]  = inp[34]
        out[107] = inp[35]
        out[104] = inp[36]
        out[9]   = inp[37]
        out[42]  = inp[38]
        out[75]  = inp[39]
        out[72]  = inp[40]
        out[105] = inp[41]
        out[10]  = inp[42]
        out[43]  = inp[43]
        out[40]  = inp[44]
        out[73]  = inp[45]
        out[106] = inp[46]
        out[11]  = inp[47]
        out[12]  = inp[48]
        out[45]  = inp[49]
        out[78]  = inp[50]
        out[111] = inp[51]
        out[108] = inp[52]
        out[13]  = inp[53]
        out[46]  = inp[54]
        out[79]  = inp[55]
        out[76]  = inp[56]
        out[109] = inp[57]
        out[14]  = inp[58]
        out[47]  = inp[59]
        out[44]  = inp[60]
        out[77]  = inp[61]
        out[110] = inp[62]
        out[15]  = inp[63]
        out[16]  = inp[64]
        out[49]  = inp[65]
        out[82]  = inp[66]
        out[115] = inp[67]
        out[112] = inp[68]
        out[17]  = inp[69]
        out[50]  = inp[70]
        out[83]  = inp[71]
        out[80]  = inp[72]
        out[113] = inp[73]
        out[18]  = inp[74]
        out[51]  = inp[75]
        out[48]  = inp[76]
        out[81]  = inp[77]
        out[114] = inp[78]
        out[19]  = inp[79]
        out[20]  = inp[80]
        out[53]  = inp[81]
        out[86]  = inp[82]
        out[119] = inp[83]
        out[116] = inp[84]
        out[21]  = inp[85]
        out[54]  = inp[86]
        out[87]  = inp[87]
        out[84]  = inp[88]
        out[117] = inp[89]
        out[22]  = inp[90]
        out[55]  = inp[91]
        out[52]  = inp[92]
        out[85]  = inp[93]
        out[118] = inp[94]
        out[23]  = inp[95]
        out[24]  = inp[96]
        out[57]  = inp[97]
        out[90]  = inp[98]
        out[123] = inp[99]
        out[120] = inp[100]
        out[25]  = inp[101]
        out[58]  = inp[102]
        out[91]  = inp[103]
        out[88]  = inp[104]
        out[121] = inp[105]
        out[26]  = inp[106]
        out[59]  = inp[107]
        out[56]  = inp[108]
        out[89]  = inp[109]
        out[122] = inp[110]
        out[27]  = inp[111]
        out[28]  = inp[112]
        out[61]  = inp[113]
        out[94]  = inp[114]
        out[127] = inp[115]
        out[124] = inp[116]
        out[29]  = inp[117]
        out[62]  = inp[118]
        out[95]  = inp[119]
        out[92]  = inp[120]
        out[125] = inp[121]
        out[30]  = inp[122]
        out[63]  = inp[123]
        out[60]  = inp[124]
        out[93]  = inp[125]
        out[126] = inp[126]
        out[31]  = inp[127]
        self._out = out.__copy__()[::-1]
    def sbox(self, a, b):
        self._sbox_a = self.gift_sbox(a)
        self._sbox_b = self.gift_sbox(b)
    def perm(self):
        self.gift_perm()
        
class Handle_ALUC(object):
    def __init__(self, core, meta):
        self._core = core
        self._meta = meta
        self._regs = core._regs
        self._dram = core._dram
        self._srgs = core._srgs
        self._pState = core._pState
        self.DEBUG = Debug.Test
        
        self._instrs = {
            "asb" : Instr_ALUC1("asb", self.op_asb, 0),
            "amc" : Instr_ALUC1("amc", self.op_amc, 2),
            "swd" : Instr_ALUC1("swd", self.op_swd, 4),
            "gsp" : Instr_ALUC1("gsp", self.op_gsp, 5),
        }
        self._ops = {}
        self._opc2_dict = {}
        self._ops.update({"amc" : AMC(self._instrs["amc"],meta)})
        self._opc2_dict.update({self._instrs["amc"]._opc2 : "amc"})
        self._ops.update({"asb" : ASB(self._instrs["asb"],meta)})
        self._opc2_dict.update({self._instrs["asb"]._opc2 : "asb"})
        self._ops.update({"swd" : SWD(self._instrs["swd"],meta)})
        self._opc2_dict.update({self._instrs["swd"]._opc2 : "swd"})
        self._ops.update({"gsp" : GSP(self._instrs["gsp"],meta)})
        self._opc2_dict.update({self._instrs["gsp"]._opc2 : "gsp"})
        
        self._amc_states = {
            "load01" : 0,
            "ld23u3" : 1,
            "calc_1" : 2,
            "calc_2" : 3,
            "unld_3" : 4,
            "unld_2" : 5,
            "unld_1" : 6,
            "unld_0" : 7,
            "done" : 8
        }
            
        self._amc_state_map = {
            "load01" : self.op_amc_0,
            "ld23u3" : self.op_amc_1_0,
            "calc_1" : self.op_amc_1_1,
            "calc_2" : self.op_amc_1_2,
            "unld_3" : self.op_amc_1_3,
            "unld_2" : self.op_amc_2,
            "unld_1" : self.op_amc_3,
            "unld_0" : self.op_amc_4,
            "done" : self.op_amc_done
        }
        
        self._swd_states = {
            "load01" : 0,
            "load23" : 1,
            "shifam" : 2,
            "unld_3" : 3,
            "unld_2" : 4,
            "unld_1" : 5,
            "unld_0" : 6,
            "done" : 7
        }
        
        self._swd_state_map = {
            "load01" : self.op_swd_0,
            "load23" : self.op_swd_1,
            "shifam" : self.op_swd_2_0,
            "unld_3" : self.op_swd_2_1,
            "unld_2" : self.op_swd_3,
            "unld_1" : self.op_swd_4,
            "unld_0" : self.op_swd_5,
            "done" : self.op_swd_done
        }
        
        self._gsp_states = {
            "load01" : 0,
            "load23" : 1,
            "load45" : 2,
            "load67" : 3,
            "load89" : 4,
            "loadab" : 5,
            "loadcd" : 6,
            "loadef" : 7,
            "unld_f" : 8,
            "unld_e" : 9,
            "unld_d" : 10,
            "unld_c" : 11,
            "unld_b" : 12,
            "unld_a" : 13,
            "unld_9" : 14,
            "unld_8" : 15,
            "unld_7" : 16,
            "unld_6" : 17,
            "unld_5" : 18,
            "unld_4" : 19,
            "unld_3" : 20,
            "unld_2" : 21,
            "unld_1" : 22,
            "unld_0" : 23,
            "done" : 24
        }
        
        self._gsp_state_map = {
            "load01" : self.op_gsp_load,
            "load23" : self.op_gsp_load,
            "load45" : self.op_gsp_load,
            "load67" : self.op_gsp_load,
            "load89" : self.op_gsp_load,
            "loadab" : self.op_gsp_load,
            "loadcd" : self.op_gsp_load,
            "loadef" : self.op_gsp_load,
            "unld_f" : self.op_gsp_unld,
            "unld_e" : self.op_gsp_unld,
            "unld_d" : self.op_gsp_unld,
            "unld_c" : self.op_gsp_unld,
            "unld_b" : self.op_gsp_unld,
            "unld_a" : self.op_gsp_unld,
            "unld_9" : self.op_gsp_unld,
            "unld_8" : self.op_gsp_unld,
            "unld_7" : self.op_gsp_unld,
            "unld_6" : self.op_gsp_unld,
            "unld_5" : self.op_gsp_unld,
            "unld_4" : self.op_gsp_unld,
            "unld_3" : self.op_gsp_unld,
            "unld_2" : self.op_gsp_unld,
            "unld_1" : self.op_gsp_unld,
            "unld_0" : self.op_gsp_unld,
            "done" : self.op_gsp_done
        }
        
        self._ops["amc"].state_init(self._amc_states,self._amc_state_map)
        self._ops["swd"].state_init(self._swd_states,self._swd_state_map)
        self._ops["gsp"].state_init(self._gsp_states,self._gsp_state_map)
        for ins in self._instrs.values():
            self._meta._occur.occ.update({ins._mnem:0})
        self._srgs._wait.update({"amc":self._ops["amc"]._wait_req})
        self._srgs._wait.update({"swd":self._ops["swd"]._wait_req})
        self._srgs._wait.update({"gsp":self._ops["gsp"]._wait_req})
    def op_asb(self,args):
        src = args[0].__copy__()
        dst = args[1].__copy__()
        regA = self._regs.bus(src)
        regB = self._regs.bus(dst)
        result = self._ops["asb"].get(regA)
        self._regs.bus(dst,result)
        return "{} called with <src>{}={} <dst>{}={} result={}".format(sys._getframe().f_code.co_name[3:],reg_map(args[0]),self._meta.repr(regA),reg_map(args[1]),self._meta.repr(regB),self._meta.repr(result))
            
    def op_amc(self,args):
        self._ops["amc"].set_xtime()
        ret = self._ops["amc"]._mapst[self._ops["amc"]._state](args)
        self._srgs._wait.update({"amc":self._ops["amc"]._wait_req})
        #print(self._ops["amc"]._state,self._ops["amc"]._cur)
        
        return ret
    def op_amc_0(self,args):
        '''
        sum = a ^ b
        s0 = a
        s1 = b
        state = load_2_3_unload_3
        '''
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._ops["amc"]._sum = a ^ b
        self._ops["amc"]._s[0] = a
        self._ops["amc"]._s[1] = b
        state = self._ops["amc"]._state
        self._ops["amc"]._state = self._ops["amc"]._enumst[1]
        self._ops["amc"]._wait_req = [0]
        return "{} {} {}={} {}={} sum={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(self._ops["amc"]._sum))
    def op_amc_1_0(self,args):
        '''
        state is load_2_3_unload_3
        sum = sum ^ a
        s2 = a
        state = 
        '''
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._ops["amc"]._sum ^= a
        self._ops["amc"]._s[2] = a
        state = self._ops["amc"]._state
        self._ops["amc"]._state = self._ops["amc"]._enumst[2]
        self._ops["amc"]._wait_req = [1]
        return "{} {} {}={} {}={} sum={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(self._ops["amc"]._sum))
    def op_amc_1_1(self,args):
        '''
        calc_1
        sum = sum ^ b
        '''
        
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._ops["amc"]._sum ^= b
        self._ops["amc"]._xtime_input = b ^ self._ops["amc"]._s[0]
        state = self._ops["amc"]._state
        self._ops["amc"]._state = self._ops["amc"]._enumst[3]
        self._ops["amc"]._wait_req = [1]
        return "{} {} {}={} {}={} sum={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(self._ops["amc"]._sum))
    def op_amc_1_2(self,args):
        '''
        calc_2
        result = b ^ xtime_result ^ sum
        xtime_input = s2 ^ b
        wait_req = 1
        '''
        
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._ops["amc"]._res = (b ^ self._ops["amc"]._xtime_result ^ self._ops["amc"]._sum).__copy__()
        
        self._ops["amc"]._xtime_input = self._ops["amc"]._s[2] ^ b
        state = self._ops["amc"]._state
        self._ops["amc"]._state = self._ops["amc"]._enumst[4]
        self._ops["amc"]._wait_req = [1]
        return "{} {} {}={} {}={} sum={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(self._ops["amc"]._sum))
    def op_amc_1_3(self,args):
        '''
        unload_3
        wait_req = 0
        '''
        dst = args[1].__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._regs.bus(dst,self._ops["amc"]._res)
        state = self._ops["amc"]._state
        self._ops["amc"]._state = self._ops["amc"]._enumst[5]
        self._ops["amc"]._wait_req = [0]
        return "{} {} <dst>{}={} res={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[1]),self._meta.repr(b),self._meta.repr(self._ops["amc"]._res))
    def op_amc_2(self,args):
        '''
        unload_2
        result = s2 ^ xtime_result ^ sum
        xtime_input = s1 ^ s2
        wait_req = 0
        '''
        dst = args[1].__copy__()
        res = self._ops["amc"]._s[2] ^ self._ops["amc"]._xtime_result ^ self._ops["amc"]._sum
        self._ops["amc"]._xtime_input = self._ops["amc"]._s[1] ^ self._ops["amc"]._s[2]
        self._regs.bus(dst,res)
        state = self._ops["amc"]._state
        self._ops["amc"]._state = self._ops["amc"]._enumst[6]
        self._ops["amc"]._wait_req = [0]
        return "{} {} <dst>{}={} sum={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[1]),self._meta.repr(res),self._meta.repr(self._ops["amc"]._sum))
    def op_amc_3(self,args):
        '''
        unload_1
        result = s1 ^ xtime_result ^ sum
        xtime_input = s0 ^ s1
        wait_req = 0
        '''
        dst = args[1].__copy__()
        res = self._ops["amc"]._s[1] ^ self._ops["amc"]._xtime_result ^ self._ops["amc"]._sum
        self._ops["amc"]._xtime_input = self._ops["amc"]._s[0] ^ self._ops["amc"]._s[1]
        self._regs.bus(dst,res)
        state = self._ops["amc"]._state

        self._ops["amc"]._state = self._ops["amc"]._enumst[7]
        self._ops["amc"]._wait_req = [0]
        return "{} {} <dst>{}={} sum={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[1]),self._meta.repr(res),self._meta.repr(self._ops["amc"]._sum))
    def op_amc_4(self,args):
        '''
        unload_0
        result = s0 ^ xtime_result ^ sum
        wait_req = 0
        '''
        dst = args[1].__copy__()
        res = self._ops["amc"]._s[0] ^ self._ops["amc"]._xtime_result ^ self._ops["amc"]._sum
        self._regs.bus(dst,res)
        state = self._ops["amc"]._state
        self._ops["amc"]._state = self._ops["amc"]._enumst[8]
        self._ops["amc"]._wait_req = [0]
        return "{} {} <dst>{}={} sum={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[1]),self._meta.repr(res),self._meta.repr(self._ops["amc"]._sum))
    def op_amc_done(self,args):
        self._ops["amc"].reset()
        self._ops["amc"]._state = self._ops["amc"]._enumst[0]
        return self._ops["amc"]._mapst[self._ops["amc"]._state](args)
    
    def op_swd(self,args):
        self._ops["swd"].set_shift_out()
        ret = self._ops["swd"]._mapst[self._ops["swd"]._state](args)
        self._srgs._wait.update({"swd":self._ops["swd"]._wait_req})
        #print(self._ops["swd"]._state,self._ops["swd"]._cur)
        
        return ret
    def op_swd_0(self, args):
        '''
        LOAD_0_1
        shifter_in[7:0] <= a;
        shifter_in[15:8] <= b;
        state = LOAD_2_3
        wait_req = 0
        '''
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._ops["swd"]._shifter_in.overwrite(b+a,16)
        state = self._ops["swd"]._state
        self._ops["swd"]._state = self._ops["swd"]._enumst[1]
        self._ops["swd"]._wait_req = [0]
        return "{} {} {}={} {}={} shifter_in={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(self._ops["swd"]._shifter_in))
    def op_swd_1(self, args):
        '''
        LOAD_2_3
        shifter_in[23:16] <= a;
        shifter_in[31:24] <= b;
        state = SHIFT_UNLOAD_3
        wait_req = 0
        '''
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._ops["swd"]._shifter_in.overwrite(b+a,0)
        state = self._ops["swd"]._state
        self._ops["swd"]._state = self._ops["swd"]._enumst[2]
        self._ops["swd"]._wait_req = [0]
        return "{} {} {}={} {}={} shifter_in={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(self._ops["swd"]._shifter_in))
    def op_swd_2_0(self, args):
        '''
        SHIFT AMOUNT
        shift_amount <= a[4:0];
        wait_req_reg <= 1'b1;
        state = UNLOAD_3
        '''
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._ops["swd"]._shift_amount.overwrite(a[3:].__copy__(),0)
        
        state = self._ops["swd"]._state
        self._ops["swd"]._state = self._ops["swd"]._enumst[3]
        self._ops["swd"]._wait_req = [1]
        return "{} {} {}={} {}={} shift_amount={} (uint)".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._ops["swd"]._shift_amount.uint)
    def op_swd_2_1(self, args):
        '''
        UNLOAD_3
        result <= shifter_out[31:24];
        wait_req_reg <= 1'b0;
        state = UNLOAD_2
        '''
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        res = self._ops["swd"]._shifter_out.__copy__()[:8]
        self._regs.bus(args[1], res.__copy__())
        
        state = self._ops["swd"]._state
        self._ops["swd"]._state = self._ops["swd"]._enumst[4]
        self._ops["swd"]._wait_req = [0]
        return "{} {} {}={} {}={} res={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(res))
    def op_swd_3(self, args):
        '''
        UNLOAD_2
        result <= shifter_out[23:16];
        wait_req_reg <= 1'b0;
        state = UNLOAD_1
        '''
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        res = self._ops["swd"]._shifter_out.__copy__()[8:16]
        self._regs.bus(args[1], res.__copy__())
        
        state = self._ops["swd"]._state
        self._ops["swd"]._state = self._ops["swd"]._enumst[5]
        self._ops["swd"]._wait_req = [0]
        return "{} {} {}={} {}={} res={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(res))
    def op_swd_4(self, args):
        '''
        UNLOAD_1
        result <= shifter_out[15:8];
        wait_req_reg <= 1'b0;
        state = UNLOAD_0
        '''
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        res = self._ops["swd"]._shifter_out.__copy__()[16:24]
        self._regs.bus(args[1], res.__copy__())
        
        state = self._ops["swd"]._state
        self._ops["swd"]._state = self._ops["swd"]._enumst[6]
        self._ops["swd"]._wait_req = [0]
        return "{} {} {}={} {}={} res={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(res))
    def op_swd_5(self, args):
        '''
        UNLOAD_0
        result <= shifter_out[8:0];
        wait_req_reg <= 1'b0;
        state = done
        '''
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        res = self._ops["swd"]._shifter_out.__copy__()[24:]
        self._regs.bus(args[1], res.__copy__())
        
        state = self._ops["swd"]._state
        self._ops["swd"]._state = self._ops["swd"]._enumst[7]
        self._ops["swd"]._wait_req = [0]
        return "{} {} {}={} {}={} res={}".format(sys._getframe().f_code.co_name[3:6],state,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(res))
    def op_swd_done(self, args):
        self._ops["swd"].reset()
        self._ops["swd"]._state = self._ops["swd"]._enumst[0]
        return self._ops["swd"]._mapst[self._ops["swd"]._state](args)

    def op_gsp(self, args):
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._ops["gsp"].sbox(a,b)
        self._ops["gsp"].perm()
        ret = self._ops["gsp"]._mapst[self._ops["gsp"]._state](args)
        self._srgs._wait.update({"gsp":self._ops["gsp"]._wait_req})
        return ret

    def op_gsp_load(self, args):
        curstate = self._ops["gsp"]._state
        if self._ops["gsp"]._state.startswith("load"):
            state = self._gsp_states[self._ops["gsp"]._state]
            a = self._regs.bus(args[0].__copy__()).__copy__()
            b = self._regs.bus(args[1].__copy__()).__copy__()
            self._ops["gsp"]._in[120-state*16:128-state*16] = self._ops["gsp"]._sbox_a.__copy__()
            self._ops["gsp"]._in[112-state*16:120-state*16] = self._ops["gsp"]._sbox_b.__copy__()
            self._ops["gsp"]._state = self._ops["gsp"]._enumst[state+1]
            self._ops["gsp"]._wait_req = [0]
            if self._ops["gsp"]._state.startswith("unld"):
                self._ops["gsp"]._wait_req = [1]
            return "{} {} {}={} {}={} in[{}:{}]={}".format(sys._getframe().f_code.co_name[3:6],curstate,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),state*16+15,state*16,self._meta.repr(self._ops["gsp"]._in[112-state*16:120-state*16]+self._ops["gsp"]._in[120-state*16:128-state*16]))
        print("ERROR IN GSP load state= {}".format(self._ops["gsp"]._state))
        return "ERROR IN GSP load state= {}".format(self._ops["gsp"]._state)
    def op_gsp_unld(self, args):
        curstate = self._ops["gsp"]._state
        if self._ops["gsp"]._state.startswith("unld"):
            state = self._gsp_states[self._ops["gsp"]._state]
            a = self._regs.bus(args[0].__copy__()).__copy__()
            b = self._regs.bus(args[1].__copy__()).__copy__()
            res = self._ops["gsp"]._out[(state-8)*8:8+(state-8)*8]
            self._regs.bus(args[1], res.__copy__())
            self._ops["gsp"]._state = self._ops["gsp"]._enumst[state+1]
            self._ops["gsp"]._wait_req = [0]
            return "{} {} {}={} {}={} res={}".format(sys._getframe().f_code.co_name[3:6],curstate,reg_map(args[0]),self._meta.repr(a),reg_map(args[1]),self._meta.repr(b),self._meta.repr(res))
        print("ERROR IN GSP load state= {}".format(self._ops["gsp"]._state))
        return "ERROR IN GSP unld state= {}".format(self._ops["gsp"]._state)
    def op_gsp_done(self, args):
        self._ops["gsp"].reset()
        a = self._regs.bus(args[0].__copy__()).__copy__()
        b = self._regs.bus(args[1].__copy__()).__copy__()
        self._ops["gsp"].sbox(a,b)
        self._ops["gsp"].perm()
        self._ops["gsp"]._state = self._ops["gsp"]._enumst[0]
        return self._ops["gsp"]._mapst[self._ops["gsp"]._state](args)

class Instruction_Handler(object):
    def __init__(self, core, meta):
        self._core = core
        self._meta = meta
        self._regs = core._regs
        self._dram = core._dram
        self._srgs = core._srgs
        self._iVects = core._iVects
        self._pState = core._pState
        self._opc1 = Handle_OPC1(core, meta)
        self._alu = Handle_ALU(core, meta)
        self._gen1 = Handle_GEN1(core, meta)
        self._aluc = Handle_ALUC(core, meta)
        self._opc2 = {
            "alu" : self._alu,
            "gen1": self._gen1,
            "aluc1" : self._aluc,
            "aluc2" : self._aluc
        }
    def get_instr(self,pc):
        return self.get_code(pc), self.get_mnem(pc)
    def get_mnem(self, pc):
        progword = self._core._pram.bus(pc)
        if progword[:4].uint in self._opc1._opc1_dict:
            op1 = self._opc1._opc1_dict[progword[:4].uint]
            instr = self._opc1._instrs[op1]
            if instr._cycles == -2: #? -2 cycles used for gen1/alu/aluc
                if op1 in self._opc2:
                    op2 = self._opc2[op1]._opc2_dict[progword[4:].uint]
                    instr = self._opc2[op1]._intrs[op2]
            return instr._mnem
        return ""
    def get_code(self,pc):
        code = ""
        progword = self._core._pram.bus(pc)
        if progword[:4].uint in self._opc1._opc1_dict:
            op1 = self._opc1._opc1_dict[progword[:4].uint]
            instr = self._opc1._instrs[op1]
            if instr._cycles == -2: #? -2 cycles used for gen1/alu/aluc
                if op1 in self._opc2:
                    code = progword.hex
            else:
                code = progword[:4].hex
        return code

class Interrupt_Handler(object):
    def __init__(self, core, meta):
        self._core = core
        self._meta = meta
        self._regs = core._regs
        self._dram = core._dram
        self._srgs = core._srgs
        self._iVects = core._iVects
        self._pState = core._pState
        self._addr = None
    def do_intr(self):
        self._regs._shadow_(True,self._meta._num_pairs_shadowed)
        self._srgs._SR._shadow_(True)
        #if self._pState._get_() == "Halt":
        #    self._srgs._PC.incr()
        self._srgs._PC._shadow_(True)
        if self._addr is None:
            return "Error: Interrupt address of iVect is None."
        pc = self._iVects.bus(self._addr)
        pc <<= 4
        self._srgs._PC._pc = pc.__copy__()
        self._srgs._PC.changed = False
        self._pState._set_("None")
        return None

class Handler(object):
    def __init__(self, core, meta):
        self._core = core
        self._meta = meta
        self._regs = core._regs
        self._dram = core._dram
        self._srgs = core._srgs
        self._iVects = core._iVects
        self._pram = core._pram
        self._pState = core._pState
        self._ins = Instruction_Handler(core, meta)
        self._intr = Interrupt_Handler(core, meta)
        self._maxpc = 0
        self.DEBUG = Debug.Test
        self.progword = None
        self.op1 = None
        self.op2 = None
        self.pw = ""
        self.errc = None
        self.firstCyc = True
        self.tstart = None
        self.bins_firstCyc = True
        self.state_map = {
            "None" : self.state_None,
            "Op"   : self.state_Op,
            "Halt" : self.state_Halt,
        }
        
    def hex_rgx(self, line):
        rgx = re.compile(r"^([0-9a-fA-F]{2})")
        m = rgx.match(line)
        if m is None:
            return None
        return get_imm([char for char in m[1]],16)
 
    def pram_load(self, prog, fn):
        self._maxpc = 0
        for it, progword in enumerate(prog):
            progword = self.hex_rgx(progword)
            if progword is not None:
                self._pram._mem[it] = BitArray(uint=progword,length=self._pram._w_width)
                self._maxpc += 1
        self._maxpc -= 1
        if self._maxpc < 0:
            return "Error: No progwords of hex-pair format found in \"{}\"".format(fn)
        # pass number of proglines to PC and pram
        self._srgs._PC._maxPC = self._maxpc
        self._pram._maxaddr = self._maxpc
        self._pram._size = self._maxpc+1
        
        if self._maxpc >= 2**self._core._pram._a_width:
            return "Error: Lines in program exceeds maximum of {}.".format(2**self._core._pram._a_width)
        return "Success: Loaded program file \"{}\"".format(fn)

    def data_load(self, datalines, fn, start = 0):
        self._meta._highest = start
        for it, data in enumerate(datalines):
            data = self.hex_rgx(data)
            if data is not None:
                self._dram._mem[it+start] = BitArray(uint=data,length=self._pram._w_width)
                self._meta._highest += 1
        self._meta._highest -= 1
        if self._meta._highest < 0:
            return "Error: No data of hex-pair format found in \"{}\"".format(fn)
        if self._maxpc >= 2**self._core._pram._a_width:
            return "Error: Lines in program exceeds maximum of {}.".format(2**self._core._pram._a_width)
        #//if self.DEBUG >= Debug.Test:
        return "Success: Loaded data file \"{}\"".format(fn)
        
    def run_conditions(self):
        #a = self._srgs._PC._pc.uint <= self._maxpc
        b = not self._meta._timer.expired()
        #c = sbus.bus()
        #if a and b and c:
        if b:
            return True
        #print("Timer expired.")
        return False
    
    def status(self):
        pc = self._core._srgs._PC._pc
        status_out = ""
        status_out += "PC: {} ".format(pc.hex)
        if self._core._op._instr._opc1 >= 0:
            if self._core._op._instr._opc2 is not None:
                code = hex(self._core._op._instr._opc1) + hex(self._core._op._instr._opc2)[2:]
            else:
                code = hex(self._core._op._instr._opc1) + "  "
            for x in self._core._args:
                code += x.hex
        else:
            code = -1
        status_out += "Instr: {} Mnem: {} ".format(code, self._core._op._instr._mnem)
        for it, reg in enumerate(self._core._regs._reg[:8]):
            status_out += "r{}: 0x{} ".format(it,reg.hex)
        for it, reg in enumerate(self._core._regs._reg[8:]):
            status_out += "a{}: 0x{} ".format(it,reg.hex)
        status_out += "Z: {} ".format(self._core._srgs._SR.status("z"))
        status_out += "N: {} ".format(self._core._srgs._SR.status("n"))
        status_out += "C: {} ".format(self._core._srgs._SR.status("c"))
        status_out += "X: {} ".format(self._core._srgs._SR.status("x"))
        return status_out
    
    def state_None(self, run = True):
        if self.progword is None:
            self.errc = "Error: Progword is None."
            return -1
        if self.progword[:4].uint in self._ins._opc1._opc1_dict:
            self._pState._set_("Op")
            self._core._args = []
            self.op1 = self._ins._opc1._opc1_dict[self.progword[:4].uint]
            self._core._instr = self._ins._opc1._instrs[self.op1]
            if self._core._instr._cycles == -2: #? -2 cycles used for gen1/alu/aluc
                if self.op1 in self._ins._opc2:
                    if self.progword[4:].uint in self._ins._opc2[self.op1]._opc2_dict:
                        self.op2 = self._ins._opc2[self.op1]._opc2_dict[self.progword[4:].uint]
                        self._core._op = self._ins._opc2[self.op1]._ops[self.op2]
                    else:
                        self.errc = "Error: {} {} not recognized.".format(self.op1,self.progword[4:].hex)
                        return 1
            else:
                self._core._op = self._ins._opc1._ops[self.op1]
                self._core._args.append(self.progword[4:])
            if run:
                if self.bins_firstCyc:
                    self.bins_firstCyc = False
                elif self._core._op._instr._mnem in self._meta._brkins.keys():
                    brkins = False
                    if self._meta._brkins[self._core._op._instr._mnem] > 0:
                        brkins = True
                        self._meta._brkins[self._core._op._instr._mnem] -= 1
                        if self._meta._brkins[self._core._op._instr._mnem] == 0:
                            del self._meta._brkins[self._core._op._instr._mnem]
                    elif self._meta._brkins[self._core._op._instr._mnem] < 0:
                        brkins = True
                    else:
                        del self._meta._brkins[self._core._op._instr._mnem]
                    if brkins:
                        self.errc = "Break on Instruction reached at pc = {}".format(self.curpc.hex)
                        self._pState._set_("None")
                        return 3 
            tmp = self._core._op.zero(self._core._args)
            if tmp is not None:
                self.pw += tmp
            self._core._op._cur += 1
        else:
            self.errc = "Error: Unrecognized opc1: {}".format(self.progword[:4].hex)
            return 2
        return None
    
    def state_Op(self, run = True):
        if self.op1 is None:
            self.errc = "Error: op1 is None."
            return -1
        if "aluc" in self.op1:
            #print(self.op1,self._core._op._instr._mnem)
            self._core._args = []
            self._core._args.append(self.progword[:4])
            self._core._args.append(self.progword[4:])
            tmp = self._core._op.call(self._core._op._cur,self._core._args)
            if tmp is not None:
                    self.pw += tmp
            try:
                if self._core._op._state == "done":
                    self._core._op.reset()
                    self._core._op._cur = 0
                    self._pState._set_("None")
            except AttributeError:
                if self._core._op._cur >= self._core._op._cycles:
                    self._core._op._cur = 0
                    self._pState._set_("None")
            if not self._srgs._PC.check_wait():
                self._core._op._cur = 0
                self._pState._set_("None")
        elif self._core._op._cur < self._core._op._cycles:
                self._core._args.append(self.progword[:4])
                self._core._args.append(self.progword[4:])
                tmp = self._core._op.call(self._core._op._cur,self._core._args)
                if tmp is not None:
                    self.pw += tmp
                self._core._op._cur += 1
        return None
    
    def state_Halt(self, run = True):
        pass

    def check_interrupts(self):
        iv = None
        tmpCyc = self._core._cycle+self._core._haltCycles
        if tmpCyc in self._meta._cycinterr:
            for it, bit in enumerate(self._meta._cycinterr[tmpCyc]):
                if self._core._srgs._IE._ie[it] and bit:
                    iv = it
            if iv is not None:
                self._intr._addr = 15-iv
                print("Interrupt i{} occurring.".format(self._intr._addr))
                del self._meta._cycinterr[tmpCyc]
                return True
        elif self.curpc.hex in self._meta._interrupts:
            for it, bit in enumerate(self._meta._interrupts[self.curpc.hex]):
                if self._core._srgs._IE._ie[it] and bit:
                    iv = it
            if iv is not None:
                self._intr._addr = 15-iv
                print("Interrupt i{} occurring.".format(self._intr._addr))
                del self._meta._interrupts[self.curpc.hex]
                return True
        return False
    
    def pre_state(self, run = True):
        introcc = False
        if run:
            if self._meta._timer.expired():
                touttime = time.time()
                contin = input("Timeout of {} seconds expired. Cont? [y]/n: ".format(self._meta._timeout))
                if contin == "" or 'y' in contin.lower() or '1' in contin.lower() or 'true' in contin.lower():
                    self._meta._timer.start(self._meta._timeout)
                elif 'n' in contin.lower() or contin == '0' or contin.lower() == 'false':
                    self.errc = "Timeout reached at {} seconds.".format(str(touttime - self.tstart)[:10])
                    return 5
        self.curpc = self._srgs._PC.bus()
        if run:
            if self.firstCyc:
                self.firstCyc = False
            elif self.curpc.uint in self._meta._breakpoints.keys():
                self.errc = "Breakpoint reached at pc = {}".format(self.curpc.hex)
                return 6
        sysFF = self._core._sbus.bus()
        if sysFF == "ff":
            self.errc = "System End signal received."
            return 7
        if self._pState._get_() != "Op" and not self._pState._intr:
            self._pState._intr = self.check_interrupts()
            
            if self._pState._intr:
                introcc = True
                ret_di = self._intr.do_intr()
                if ret_di is not None:
                    return ret_di
        if introcc:
            return "intr"
            #self.curpc = self._srgs._PC.bus()
        self.progword = self._pram.bus(self._srgs._PC.bus())
        if self._pState._get_() != "Halt":
            self.pw = ""
            if self._srgs._PC.check_wait():
                self.pw += "Waiting "
            else:
                self.pw += "pc: {} ".format(self._srgs._PC._pc.hex)
    
    def post_state(self, run = True):
        if self._core._op._cur >= self._core._op._cycles:
            if "aluc" not in self.op1:
                self._core._op._cur = 0
                self._pState._set_("None")
        if self._meta._print:
            print(self.pw)
        elif not run:
            print(self.pw)
        sysFF = self._core._sbus.bus()
        self._core._cycle += 1
        if self._meta._trace:
            print(self.status())
        if sysFF == "ff":
            self.errc = "System End signal received."
            return 3
        elif not self._srgs._PC.advance():
            self.errc = "Error: Max PC Exceeded."
            return 4
        return None
    
    def handle_fsm(self, run = True):
        state = self._pState._get_()
        ret_pre = self.pre_state(run)
        if ret_pre == "intr":
            return None
        elif ret_pre is not None:
            return self.errc
        ret_states = self.state_map[self._pState._get_()](run)
        if ret_states is not None:
            return self.errc
        if self._pState._get_() != "Halt":
            ret_pos = self.post_state(run)
            if ret_pos is not None:
                return self.errc
        elif state != "Halt":
            if self._meta._print:
                print(self.pw)
            elif not run:
                print(self.pw)
            if self._meta._trace:
                print(self.status())
            if not self._srgs._PC.advance():
                self.errc = "Error: Max PC Exceeded."
                return self.errc
        else:
            self._core._haltCycles += 1
        return None
    
    def pre_run(self):
        self._meta._timer = Timeout(self._meta._timeout)
        self._meta._timer.start(self._meta._timeout)
        self.tstart = time.time()
        self.firstCyc = True
        self.bins_firstCyc = True
        self._core._args = []
        self.errc = None
    
    def pre_step(self):
        self.errc = None
    
    def run(self):
        self.pre_run()
        while self.errc is None:
            ret_fsm = self.handle_fsm()
            if ret_fsm is not None:
                break
        if self._core._haltCycles != 0:
            return self.errc, "Active Cycles: {} Halted Cycles: {} Time Elapsed: {} s".format(self._core._cycle,self._core._haltCycles, str(time.time() - self.tstart)[:10])
        return self.errc, "Cycles Elapsed: {} Time Elapsed: {} s".format(self._core._cycle, str(time.time() - self.tstart)[:10])
    
    def step(self):
        self.pre_step()
        self.handle_fsm(False)
        return self.errc
  
class HOKSTER(object):
    def __init__(self, p_Size = 2**12, p_Width = 12, d_Size = 2**16, dword_Width = 8, daddr_Width = 16):
        self._ps = p_Size
        self._pw = p_Width
        self._ds = d_Size
        self._dww = dword_Width
        self._daw = daddr_Width
        self.meta = self.Meta()
        self.core = self.Core(self.meta, self._ps, self._pw, self._ds, self._dww, self._daw)
        self._h = Handler(self.core, self.meta)
    def reset(self):
        self.meta.reset()
        self.core = self.Core(self.meta, self._ps, self._pw, self._ds, self._dww, self._daw)
        self._h = Handler(self.core, self.meta)
    class Meta(object):
        def __init__(self):
            self._occur = Occurrence()
            self._debug = {}
            self._timer = Timeout()
            self._highest = 0
            self._timeout = 30
            self._trace = False
            self._print = True
            self._num_pairs_shadowed = 2
            self._validtypes = [
                "hex",
                "uint",
                "bin",
                "int",
                "oct"
            ]
            self._datatype = "hex"
            self._breakpoints = {}
            self._interrupts = {}
            self._cycinterr = {}
            self._brkins = {}
        def reset(self):
            self._occur = Occurrence()
        def timeout(self, seconds = None):
            if seconds is not None:
                self._timeout = seconds
            else:
                return self._timeout
        def datatype(self, dtype):
            if dtype in self._validtypes:
                self._datatype = dtype
        def repr(self, bA : BitArray, dtype = None):
            if dtype is not None:
                self.datatype(dtype)
            if type(bA) is BitArray:
                if self._datatype == "hex":
                    return bA.hex
                elif self._datatype == "uint":
                    return bA.uint
                elif self._datatype == "int":
                    return bA.int
                elif self._datatype == "bin":
                    return bA.bin
                elif self._datatype == "oct":
                    return bA.oct
            else:
                #pass
                raise TypeError("{} is type {} but requires type BitArray.".format(bA, type(bA)))
        def check_break(self, pc):
            return pc.uint in self._breakpoints.keys()
    class Core(object):
        def __init__(self, meta, p_Size, p_Width, d_Size, dword_Width, daddr_Width):
            # Reference to meta
            self._meta = meta
            # Ri,Ai Registers Instance
            self._regs = Registers()
            # Interrupt Vector Registers instance
            self._iVects = Registers()
            # Program State
            self._pState = ProgramState()
            # Data RAM instance
            self._dram = Memory(d_Size, dword_Width, daddr_Width)
            # Program RAM instance
            self._pram = Memory(p_Size,dword_Width, p_Width)
            # System Bus instance
            self._sbus = System()
            # Special Registers instance
            self._srgs = Special_Regs(self._dram)
            self._instr = Instruction("None", None, -1)
            self._op = Operation(self._instr, meta)
            self._cycle = 0
            self._haltCycles = 0
            self._args = []
            # Handler for operations, program execution
        def clearOp(self):
            self._instr = Instruction("None", None, -1)
            self._op = Operation(self._instr, self._meta)



