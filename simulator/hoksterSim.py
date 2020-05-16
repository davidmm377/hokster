import sys
import argparse
import os
try: 
    import cmd2
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "cmd2"])
    import cmd2
try: 
    from bitstring import BitArray
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable,"-m", "pip", "install", "bitstring"])
    from bitstring import BitArray
import hoksterCore

class SimLoop(cmd2.Cmd):
    def __init__(self, source = None):
        self.progloaded = False
        shortcuts = {}
        super().__init__(shortcuts=shortcuts)#?,allow_cli_args=False
        
        #* getting rid of some unused cmd2 commands
        del cmd2.Cmd.do_edit
        del cmd2.Cmd.do_macro
        del cmd2.Cmd.do_run_pyscript
        del cmd2.Cmd.do_run_script
        del cmd2.Cmd.do_shell
        del cmd2.Cmd.do_py
        del cmd2.Cmd.do_shortcuts
        
        #* instantiating the core
        self.hokster = hoksterCore.HOKSTER()
        
        #* hiding shortcuts from help
        shrt = ['r', 's', 'st', 'stats']
        for sh in shrt:
            self.hidden_commands.append(sh)
        self.trace = False
        self.log = False
        self.print = True
        self.timeout = 30
        self.add_settable(cmd2.Settable('timeout',int,'Timeout is how long run/cont will execute before pausing in seconds, default 30.'))
        self.add_settable(cmd2.Settable('log',bool,'Log causes the output from run/step/cont to be appended to a log file.'))
        self.add_settable(cmd2.Settable('trace',bool,'Trace causes a status to be displayed on every clock cycle.'))
        self.add_settable(cmd2.Settable('print',bool,'Print causes the result of execution through run/cont/step to be displayed.'))
        
        self.Ns = 2
        self.add_settable(cmd2.Settable('Ns',int,'Generic for Number of pair registers Ri&Ai to shadow on interrupt.'))
        self.io = self.IO(source)
        self._psource = source
        #self._psource = source
        self.dir = self.io._dir
        self.source = self.io._sname
        self.out = self.source
        self.add_settable(cmd2.Settable('out',str,'Outfile name for log, dumpstats, progSeq'))
        self._proglines = None
        self._datalines = None
        self._interrupts = {}
        self._cycinterr = {}
    prompt = 'Sim> '
    intro = "HOKSTER Simulator. Type 'help' to list commands. Version: 0.05081056"
    
    def fname(self, key):
        if key in self.io._in.keys():
            return "".join([self.dir,self.source, self.io._in[key][1]])
        elif key in self.io._out.keys():
            return "".join([self.dir,self.out, self.io._out[key][1]])
        else:
            return None
    
    class IO(object):
        def __init__(self, source):
            
            self._in = {
                "asm" : [[], ".txt", False],
                "data" : [[], "_data.hex", False],
                "prog" : [[], "_prog.hex", False]
            }
            self._out = {
                "log" : [[], "_Log.csv", False],
                "psq" : [[], "_ProgSeq.txt", False],
                "stt" : [[], "_Stats.txt", False],
            }
            self._dir = self.init_dir(source)
            self._sname = self.init_sname(source,len(self._dir))
        def init_dir(self, source):
            return os.path.dirname(source)
        def init_sname(self, source,dirlen):
            src = ""
            if dirlen > 0:
                src = source[dirlen+1:]
            else:
                src = source
            for inf in self._in:
                if src.lower().endswith(self._in[inf][1]):
                    self._in[inf][2] = True
                    return src[:-len(self._in[inf][1])]
            raise IOError("Source does not end with valid suffix.\nSuffixes are:\nasm : '.txt'\ndata : '_data.hex'\nprog : '_prog.hex'\nSource is: {}".format(source))
    
    def valid_timeout(self):
        if type(self.timeout) is int:
            if self.timeout < 0:
                self.pwarning("Timeout: {} is less than zero, setting it to abs value, {}".format(self.timeout,abs(self.timeout)))
                self.timeout = abs(self.timeout)
            return True
        self.pwarning("Timeout: {} is type {} but must be int, setting it to {}".format(self.timeout, type(self.timeout), self.hokster.meta._timeout))
        self.timeout = self.hokster.meta._timeout
        return False
    
    def valid_iv(self, iv):
        try:
            iv = BitArray(hex=iv)
            if iv.__len__() == 16:
                return True, iv
        except ValueError:
            pass
        return False, iv
    
    def valid_cyc(self,cyc):
        try:
            cyc = int(cyc)
            if cyc >= 0:
                return True, cyc
        except TypeError:
            pass
        return False, cyc
    
    def valid_pc(self,addr):
        try:
            pc = BitArray(hex=addr)
            if pc.__len__() == 12:
                return True, pc
        except ValueError:
            pass
        return False, addr
    
    def pass_flags(self):
        if self.valid_timeout():
            self.hokster.meta._timeout = self.timeout
        self.hokster.meta._print = self.print
        self.hokster.meta._trace = self.trace
        self.hokster.meta._log = self.log
        self.hokster.meta._interrupts = {key: value[:] for key, value in self._interrupts.items()}
        self.hokster.meta._cycinterr = {key: value[:] for key, value in self._cycinterr.items()}
        if 0 < self.Ns <= self.hokster.core._regs._num_regs/2:
            self.hokster.meta._num_pairs_shadowed = self.Ns
        else:
            self.pwarning("Ns = {} is not valid, using {} instead.".format(self.Ns,self.hokster.meta._num_pairs_shadowed))
            self.Ns = self.hokster.meta._num_pairs_shadowed
    def do_rmem(self, inp):
        '''Read Memory: 'rmem' 'r'
    Displays data memory locations from [start] to [end] in groups of
    16 bytes. <start> and <end> should always be four-digit hex numbers.
    
    Usage: "rmem <start> <end>" or "r <start> <end>"
    Example: rmem 0000 0100'''
        inp = inp.arg_list
        if inp.__len__() != 2:
            self.perror("Read Memory Error: rmem requires 2 arguments")
        elif inp[0].__len__() != 4:
            self.perror("Read Memory Error: <start>={} must be a four-digit hex number.".format(inp[0]))
        elif inp[1].__len__() != 4:
            self.perror("Read Memory Error: <end>={} must be a four-digit hex number.".format(inp[1]))
        else:
            start = hoksterCore.get_imm(inp[0], 16)
            end = hoksterCore.get_imm(inp[1], 16)
            if end > self.hokster.core._dram._maxaddr:
                self.perror("Read Memory Warning: End value {} for rmem greater than DRAM max address. Setting it to max: {}".format("{0:#0{1}x}".format(end,6)[2:], "{0:#0{1}x}".format(self.hokster.core._dram._maxaddr,6)[2:]))
                end = self.hokster.core._dram._maxaddr
            self.poutput("Data Memory from {} to {}:".format(inp[0],"{0:#0{1}x}".format(end,6)[2:]))
            it = start
            while it <= end:
                dword = self.hokster.core._dram.bus(it).hex
                self.poutput(dword,end=" ")
                it += 1
                if it % 16 == 0:
                    self.poutput("\n",end="")
            pass
            if (it % 16):
                self.poutput("\n",end="")
    do_r = do_rmem
    def do_rprog(self, inp):
        '''Read Prog: 'rprog'
    Displays program memory locations.
    '<' in output indicates current PC.
    With two arguments, from [start] to [end] in groups of
    16 bytes. <start> and <end> should be four-digit hex numbers.
    With one argument, <addr> which should be a four-digit hex number.
    With no arguments, all utilized program memory.
    
    Usage: "rprog <start> <end>", "rprog <addr>", "rprog" 
    Example: rprog 0000 0100'''
        inp = inp.arg_list
        if inp.__len__() ==  2:
            start = int(inp[0],16)
            end = int(inp[1],16)
            if start > end:
                self.pwarning("Warning: <start> greater than <end>. Swapping them.")
                start, end = end, start
            if start > self.hokster.core._srgs._PC._maxPC:
                self.perror("Error: <start> is {} but max PC is {}".format(hex(start)[2:].zfill(3),hex(self.hokster.core._srgs._PC._maxPC)[2:].zfill(3)))
            if end > self.hokster.core._srgs._PC._maxPC:
                self.perror("Error: <end> is {} but max PC is {}".format(hex(end)[2:].zfill(3),hex(self.hokster.core._srgs._PC._maxPC)[2:].zfill(3)))
            self.poutput("PC  : Progword")
            for it,pword in enumerate(self.hokster.core._pram._mem[start:end+1]):
                pc = it + start
                if pc > self.hokster.core._srgs._PC._maxPC:
                    break
                if self.hokster.core._srgs._PC._pc.uint == pc:
                    self.poutput("{} : {} <".format(hex(pc)[2:].zfill(3),pword.hex))
                else:
                    self.poutput("{} : {}".format(hex(pc)[2:].zfill(3),pword.hex))
        elif inp.__len__() == 1:
            addr = int(inp[0],16)
            if addr > self.hokster.core._srgs._PC._maxPC:
                self.perror("Error: <addr> is {} but max PC is {}".format(hex(addr)[2:].zfill(3),hex(self.hokster.core._srgs._PC._maxPC)[2:].zfill(3)))
            pword = self.hokster.core._pram._mem[addr]
            self.poutput("PC  : Progword")
            if self.hokster.core._srgs._PC._pc.uint == addr:
                self.poutput("{} : {} <".format(hex(addr)[2:].zfill(3),pword.hex))
            else:
                self.poutput("{} : {}".format(hex(addr)[2:].zfill(3),pword.hex))
        elif inp.__len__() == 0:
            self.poutput("PC  : Progword")
            for pc,pword in enumerate(self.hokster.core._pram._mem):
                if pc > self.hokster.core._srgs._PC._maxPC:
                    break
                if self.hokster.core._srgs._PC._pc.uint == pc:
                    self.poutput("{} : {} <".format(hex(pc)[2:].zfill(3),pword.hex))
                else:
                    self.poutput("{} : {}".format(hex(pc)[2:].zfill(3),pword.hex))
        else:
            self.perror("Read Prog Error: Too many arguments passed to rprog.\n'help rprog' for syntax.")
    def do_lmem(self, inp):
        '''Load Memory: 'lmem'
    Loads the data file to consecutive data memory locations starting at <start>.
    <start> should always be a four-digit hex number.
    If <start> is omitted, defaults to 0.
    
    Usage: "lmem [datafile] <start>", "lmem [datafile]"
    Example: lmem GCD_data.hex 0000'''
        # inp = inp.arg_list
        # if not (0 < inp.__len__() < 3):
        #     self.perror("Load Memory Error: lmem requires 1 or 2 arguments")
        #     return
        # if not inp[0].endswith(".hex"):
        #     self.perror("Load Memory Error: data file must end with .hex")
        #     return
        # if inp.__len__() == 2:
        #     if inp[1].__len__() != 4:
        #         self.perror("Load Memory Error: <start>={} must be a four-digit hex number.".format(inp[1]))
        #         return
        #     start = hoksterCore.get_imm(inp[1], 16)
        # else:
        #     start = 0
        # self.poutput (self.hokster._h.data_load(inp[0], start))
        
        # else:
        #     try:
        #         count = 0
        #         with open(inp[0],'r') as dfile:
        #             for line in dfile:
        #                 count += 1
        #         if count+hoksterCore.get_imm(inp[1],16) > hokster.core._dram._size:
                    
        #     except IOError as er:
        #         print("Load Memory Error: {}".format(er))
        print("{} not yet implemented".format(sys._getframe().f_code.co_name[3:]))
    def do_wmem(self, inp):
        '''Write Memory: 'wmem'
    Writes the two-digit hex value at <value> to the four-digit hex data memory address <addr>.
    
    Usage: "wmem <addr> <value>"
    Example: wmem 00ce a0'''
        inp = inp.arg_list
        if len(inp) < 2:
            self.perror("Write Memory Error: Requires at least two arguments <addr> and <value>")
            return
        elif inp[0].__len__() != 4:
            self.perror("Write Memory Error: <addr>={} must be a four-digit hex number.".format(inp[0]))
            return
        for it, v in enumerate(inp):
            if it == 0:
                continue
            if v.__len__() != 2:
                self.perror("Write Memory Error: <value #{}>={} must be a two-digit hex number.".format(it,v))
                return
            try:
                inp[it] = BitArray(hex=inp[it])
            except ValueError:
                self.perror("Write Memory Error: <value #{}>={} must be a two-digit hex number.".format(it,v))
        try:
            inp[0] = BitArray(hex=inp[0])
        except ValueError:
            self.perror("Write Memory Error: <addr>={} must be a four-digit hex number.".format(inp[0]))
        addr = inp[0]
        if addr.uint > self.hokster.core._dram._maxaddr:
                self.perror("Write Memory Warning: Address value {} for wmem greater than DRAM max address. Setting it to max: {}".format(addr, "{0:#0{1}x}".format(self.hokster.core._dram._maxaddr,6)[2:]))
                addr.uint = self.hokster.core._dram._maxaddr
        for it, v in enumerate(inp[1:]):
            self.hokster.core._dram.bus(addr,v)
            self.poutput("{} written to {}".format(v.hex, addr.hex))
            addr.uint += 1
            if addr.uint > self.hokster.core._dram._maxaddr:
                self.perror("Write Memory Warning: Address value {} for wmem greater than DRAM max address. Stopped writing values after {} have been written.".format(addr, it))
                break
        #print("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def do_jump(self, inp):
        '''Jump: 'jump'
    Adjusts the program counter to the three-digit hex value in <newPC>.
    
    Usage: "jump <newPC>"
    Example: jump 03a'''
        inp = inp.arg_list
        if len(inp) != 1:
            self.perror("Jump Error: Requires one three-digit hex argument <newPC>")
            return
        if inp[0].__len__ != 3:
            self.perror("Jump Error: <newPC> must be a three-digit hex value")
        try:
            newPC = BitArray(hex=inp[0])
        except ValueError:
            self.perror("Jump Error: <newPC> must be a three-digit hex value")
            return
        self.hokster.core._srgs._PC._pc = newPC.__copy__()
        self.poutput("Jumped to {}".format(newPC.hex))
        #print("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def get_intr(self):
        self._interrupts = {key: value[:] for key, value in self.hokster.meta._interrupts.items()}
    def do_step(self, inp):
        '''Step: 'step' 's'
    Executes a single cycle.'''
        self.pass_flags()
        inp = inp.arg_list
        if self.hokster.core._sbus._sys.hex != 'ff':
            errc = self.hokster._h.step()
            if errc is not None:
                if errc == "System End signal received.":
                    self.pwarning("System End signal received.")
                if "Error" in errc:
                    self.perror(errc)
            # if self.trace:
            #     pass
            #     self.poutput(self.hokster._h.status())
        else:
            self.perror("Cannot step with System End Signal received.")
        self.get_intr()
        #print("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    do_s = do_step
  
    def do_clrbrkins(self, inp):
        ''' Clear Break Instructions: 'clrbrkins'
        Clear a specific brkins by mnemonic or clear all.
        '''
        inp = inp.arg_list
        nb = 0
        if len(inp) > 0:
            for b in inp:
                if b in self.hokster.meta._brkins:
                    nb += 1
                    self.hokster.meta._brkins.__delitem__(b)
        else:
            nb = len(self.hokster.meta._brkins)
            self.hokster.meta._brkins.clear()
        self.poutput("Cleared {} brkins.".format(nb))
        
    def do_brkins(self, inp):
        '''Break on Instruction: 'brkins'
        Break on occurrence of a given instruction mnemonic. 
        Only triggers on first cycle of an instruction. 
        '-1' count causes brkins to occur an unlimited number of times.
        
        Usage: "brkins <mnem> [optional count]"
        Example: "brkins ret"
        '''
        inp = inp.arg_list
        if 0 < len(inp) < 3:
            if 1 < len(inp):
                try:
                    count = int(inp[1])
                except TypeError:
                    self.pwarning("{} cannot be parsed as an integer. Assuming 1.".format(inp[1]))
                    count = 1
            else:
                count = -1
            self.hokster.meta._brkins.update({inp[0]:count})
            self.poutput("{} added to brkins with count {}".format(inp[0],count))
        else:
            for k,v in self.hokster.meta._brkins.items():
                self.poutput("{} : {}".format(k,v))
  
    def do_cycles(self,inp):
        '''Cycles: 'cycles'
    Outputs the current cycle count of the simulated core.
    Useful for getting cycle count when stepping through code.'''
        self.poutput(self.hokster.core._cycle)
        
    def do_run(self, inp):
        '''Run: 'run'
    Re-initialises the program and runs until:
    it completes, a breakpoint is encountered, or an error occurs.
    For continuing execution, see 'cont' '''
        self.ex_reset()
        self.pass_flags()
        errc, ret = self.hokster._h.run()
        if errc is not None:
            if errc == "System End signal received.":
                self.pwarning(errc)
            if "Error" in errc:
                self.perror(errc)
        self.poutput(ret)
    
    def do_cont(self, inp):
        '''Cont: 'cont'
    Continues running the program from its current state until:
    it completes, a breakpoint is encountered, or an error occurs.'''
        #global hokster
        # sysFF = self._core._sbus.bus()
        # if sysFF == "ff":
        self.pass_flags()
        if self.hokster.core._sbus._sys.hex != 'ff':
            errc, ret = self.hokster._h.run()
            if errc is not None:
                if errc == "System End signal received.":
                    self.pwarning(errc)
                if "Error" in errc:
                    self.perror(errc)
            self.poutput(ret)
        else:
            self.perror("Program end already reached.")
    #do_cont = do_run
    def do_setbreak(self, inp):
        '''Set Break: setbreak
    Sets a user-defined breakpoint at the three-digit hex address specified in <breakpoint>.
    
    Usage: "setbreak: <breakpoint>"
    Example: setbreak 1ae'''
        inp = inp.arg_list
        if len(inp) >= 1:
            for bp in inp:
                if len(bp) <= 3:
                    bpc = BitArray(hex=bp)
                    if bpc.uint not in self.hokster.meta._breakpoints:
                        self.hokster.meta._breakpoints.update({bpc.uint : 1})
                        self.poutput("Breakpoint set at pc = {}".format(self.hokster.meta.repr(bpc)))
                    else:
                        self.poutput("Breakpoint already set at pc = {}".format(self.hokster.meta.repr(bpc)))
        #self.poutput("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def do_breakpoints(self, inp):
        '''Breakpoints: breakpoints
        Lists the hex values of all set breakpoints.
        '''
        for bp in self.hokster.meta._breakpoints.keys():
            self.poutput(hex(bp))
    def do_clrbreak(self, inp):
        '''Clear Break: clrbreak
    Clears all user-defined breakpoints.'''
        inp = inp.arg_list
        nb = 0
        if len(inp) > 0:
            for b in inp:
                if len(b) <= 3:
                    bpc = BitArray(hex=b)
                    if bpc.uint in self.hokster.meta._breakpoints:
                        nb += 1
                        self.hokster.meta._breakpoints.__delitem__(bpc.uint)
        else:
            nb = len(self.hokster.meta._breakpoints)
            self.hokster.meta._breakpoints.clear()
        self.poutput("Cleared {} breakpoints.".format(nb))
        #self.poutput("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def do_wreg(self, inp):
        '''Write Register: wreg
    Writes a two-digit hex <vlaue> into a <reg>. <reg> must be a0 through a7 or r0 through r7.
    
    Usage: "wreg <reg> <value>"
    Example: wreg r1 f6'''
        inp = inp.arg_list
        self.poutput("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def ex_reset(self):
        self.hokster.reset()
        self.hokster._h.pram_load(self._proglines,self._psource)
        if (self._datalines is not None):
            self.hokster._h.data_load(self._datalines, self._dsource)
    def do_reset(self, inp):
        '''Reset: reset
    Resets the instance of the program. PRAM and DRAM are re-loaded from files.'''
        self.ex_reset()
        
    def do_status(self, inp):
        '''Status: 'status' 'st'
    Displays current PC, instruction code and mnemonic, register contents, and status register.'''
        #inp = inp.arg_list
        self.poutput(self.hokster._h.status())
    do_st = do_status
    def do_statistics(self, inp):
        '''Statistics: 'statistics 'stats'
    Displays total cycles, total instructions, instructions per cycle (IPC), 
    and cumulative occurrence of each instruction.'''
        cycles = self.hokster.core._cycle
        self.poutput("Cycles: {}".format(cycles))
        total_instr = 0
        for o in self.hokster.meta._occur.occ:
            total_instr += self.hokster.meta._occur.occ[o]
        self.poutput("Instructions: {}".format(total_instr))
        self.poutput("IPC: {}".format(total_instr/cycles))
        self.poutput("Occurrence:")
        for o in self.hokster.meta._occur.occ:
            self.poutput("  {} : {}".format(o,self.hokster.meta._occur.occ[o]))
    do_stats = do_statistics
    
    
    def do_clrintr(self, inp):
        '''Clear Interrupts: 'clrintr'
    Clears all PC and Cycle interrupts.'''
        inp = inp.arg_list
        pcints = len(self._interrupts)
        cycints = len(self._cycinterr)
        self._interrupts.clear()
        self._cycinterr.clear()
        self.poutput("{} PC & {} Cycle interrupts cleared.".format(pcints,cycints))
    
    def do_intrc(self, inp):
        '''Interrupt on Cycle: 'intrc'
    Causes an interrupt <iv=4 digit hex> to occur on a specific cycle.
    
    Usage: "intrc <cycle> <iv>"
    Example: "intrc 50 0001"'''
        inp = inp.arg_list
        if len(inp) == 0:
            self.poutput("Cycle Interrupts:")
            for k,v in self._cycinterr.items():
                self.poutput("{} : {}".format(k,v.hex))
        elif 1 < len(inp) and len(inp) % 2 == 0:
            it = iter(inp)
            for addr in it:
                iv = next(it)
                viv, iv = self.valid_iv(iv)
                if not viv:
                    self.perror("Error: Intrc iv={} is not valid four digit hex.".format(iv))
                    return
            cyc = addr
            vcyc, cyc = self.valid_cyc(cyc)
            if not vcyc:
                self.perror("Error: Intrc cyc={} is not valid unsigned int.".format(cyc))
                return
            if cyc in self._cycinterr:
                self._cycinterr[cyc] |= iv

            if cyc in self._cycinterr:
                self.poutput("Cycle Interrupt: already exists at {}, with value: {}".format(cyc,self._cycinterr[cyc].hex))
                self._cycinterr[cyc] |= iv
                self.poutput("Modified to {}".format(self._cycinterr[cyc].hex))
            else:
                    self._cycinterr.update({cyc:iv})
                    self.poutput("Cycle Interrupt: {} added at cyc={}".format(iv.hex, cyc))
        else:
            self.perror("intrc requires zero or a multiple of 2 number of arguments.")
            return
    def do_intr(self, inp):
        '''Interrupt on PC: 'intr'
    Causes an interrupt <iv=4 digit hex> to occur on a specific PC <pc=3 digit hex>.
    
    Usage: "intr <pc> <iv>"
    Example: "intr 00a 0001"'''
        inp = inp.arg_list
        if len(inp) == 0:
            self.poutput("PC Interrupts:")
            for k,v in self._interrupts.items():
                self.poutput("{} : {}".format(k,v.hex))
        elif len(inp) % 2 == 0:
            it = iter(inp)
            for addr in it:
                iv = next(it)
                viv, iv = self.valid_iv(iv)
                if not viv:
                    self.perror("Error: Intr iv= {} is not valid four digit hex.".format(iv))
                    return
                vpc, pc = self.valid_pc(addr)
                if not vpc:
                    self.perror("Error: Intr pc= {} is not valid three digit hex.".format(pc))
                    return
                if pc.hex in self._interrupts:
                    self.poutput("Interrupt: already exists at {}, with value: {}".format(pc.hex,self._interrupts[pc.uint].hex))
                    self._interrupts[pc.hex] |= iv
                    self.poutput("Modified to {}".format(self._interrupts[pc.hex].hex))
                else:
                    self._interrupts.update({pc.hex:iv})
                    self.poutput("Interrupt: {} added at PC={}".format(iv.hex, pc.hex))
        else:
            self.perror("intr requires zero or a multiple of 2 number of arguments.")
            return
    
    def do_dumpstats(self, inp):
        '''Dump Statistics: 'dumpstats'
    Writes occurrence of each instruction to "<source>_Stats.csv"
    and program sequence list to "<source>_ProgSeq.csv"
    where <source> precedes _prog.hex in the given program file.'''
        #inp = inp.arg_list
        # if self.outfn is not None:
        #     ds = open(self._outdir + self.outfn + "_Stats.csv", 'w+')
        ds = open(self.source + "_Stats.csv","w+")
        cycles = self.hokster.core._cycle
        ds.write("Cycles, {}\n".format(cycles))
        total_instr = 0
        for o in self.hokster.meta._occur.occ:
            total_instr += self.hokster.meta._occur.occ[o]
        ds.write("Instructions, {}\n".format(total_instr))
        if cycles > 0:
            ds.write("IPC, {}\n".format(total_instr/cycles))
        else:
            ds.write("IPC, 0\n")
        ds.write("Occurrence\n")
        first = True
        for o in self.hokster.meta._occur.occ:
            if first:
                first = False
                ds.write("{},{}".format(o,self.hokster.meta._occur.occ[o]))
            else:
                ds.write("\n{},{}".format(o,self.hokster.meta._occur.occ[o]))
        ds.close()
        # else:
        #self.poutput("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def do_logon(self, inp):
        '''Log Enable: 'logon'
    Enables logging instructions to <source>_Log.txt
    where <source> precedes _prog.hex in the given program file."'''
        inp = inp.arg_list
        self.poutput("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def do_logoff(self, inp):
        '''Log Disable: 'logoff'
    Disables logging instructions to <source>_Log.txt
    where <source> precedes _prog.hex in the given program file."'''
        inp = inp.arg_list
        self.poutput("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def do_traceon(self, inp):
        '''Trace Enable: 'traceon'
    Causes a status to be displayed on every clock cycle during program execution
    using the "run" or "cont" commands. If log is enabled, also dumps this status to the log file.'''
        #inp = inp.arg_list
        self.trace = True
        self.poutput("Trace enabled.")
        #self.poutput("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def do_traceoff(self, inp):
        '''Trace Disable: 'traceoff'
    Turns off trace.'''
        #inp = inp.arg_list
        self.trace = False
        self.poutput("Trace disabled.")
        #self.poutput("{} not yet implemented.".format(sys._getframe().f_code.co_name[3:]))
    def default(self, inp):
        if self.progloaded:
            self.perror("Command Not Recognized.")
        else:
            self.progloaded = True
    
    def loader(self):
        ext = self._psource[-4:]
        if ext.lower() != ".hex":
            return "Error loading prog file: Must end with .hex", None
        retp = self.load_proglines()
        if "Success" in retp:
            if "prog" in self._psource:
                self._dsource = self._psource.replace("prog","data")
                try:
                    dfile = open(self._dsource,'r')
                    dfile.close()
                    retd = self.load_datalines()
                    return retp, retd
                except IOError:
                    pass
        return retp, None
    def load_proglines(self):
        try:
            pfile = open(self._psource,'r')
        except IOError as er:
            return "Error loading program file: \"{}\"".format(er)
        self._proglines = pfile.readlines()
        
        if len(self._proglines) == 0:
            return "Error: Program file {} is empty".format(self._psource)
        ret = self.hokster._h.pram_load(self._proglines,self._psource)
        return ret
    def load_datalines(self):
        try:
            dfile = open(self._dsource, 'r')
        except IOError as er:
            return "Error loading data file: \"{}\"".format(er)
        self._datalines = dfile.readlines()
        if len(self._proglines) == 0:
            return "Error: Data file {} is empty".format(self._dsource)
        ret = self.hokster._h.data_load(self._datalines, self._dsource)        
        return ret
    def loadfiles(self):
        load = self.loader()
        if "Error" in load[0]:
            raise IOError(load[0])
        elif "Success" in load[0]:
            self.poutput(load[0])
        if load[1] is not None:
            if "Error" in load[1]:
                raise IOError(load[1])
            elif "Success" in load[1]:
                self.poutput(load[1])
 
if __name__ == '__main__':
    source = ""
    
    try:
        source = sys.argv[1]
    except IndexError:
        while source.__len__() == 0:
            source = input("Program source file: ")
    simulator = SimLoop(source)
    simulator.loadfiles()
    simulator.cmdloop()