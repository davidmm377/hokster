# Simulator

Run hoksterSim.py and pass it a progfile.

Implemented Commands: 
* breakpoints       breakpoints
                    Lists the hex values of all set breakpoints.
* clrbreak          Clears all user-defined breakpoints.
* cont              Continues running the program from its current state until:
                    it completes, a breakpoint is encountered, or an error occurs.
                     
* help                List available commands or provide detailed help for a specific command
 
* history             View, run, edit, save, or clear previously entered commands
 
* quit                Exit this application
 
* reset               Reset: reset
                     Resets the instance of the program. PRAM and DRAM are re-loaded from files.
 
* rmem                Read Memory: 'rmem' 'r'
                     Displays data memory locations from [start] to [end] in groups of
                     16 bytes. <start> and <end> should always be four-digit hex numbers.
 
* run               Re-initialises the program and runs until:
                    it completes, a breakpoint is encountered, or an error occurs.
                    For continuing execution, see 'cont'
 
* set                 Set a settable parameter or show current settings of parameters
* setbreak          Sets a user-defined breakpoint at the three-digit hex address specified in <breakpoint>.
* status              Status: 'status' 'st'
                     Displays current PC, instruction code and mnemonic, register contents, and status register.
 
* step                Step: 'step' 's'
                     Executes a single cycle.
* lmem                Load Memory: 'lmem'
                     Loads the data file to consecutive data memory locations starting at <start>.
                     <start> should always be a four-digit hex number.
                     If <start> is omitted, defaults to 0.
* rprog               Read Prog: 'rprog'
                     Displays program memory locations.
                     '<' in output indicates current PC.
                     With two arguments, from [start] to [end] in groups of
                     16 bytes. <start> and <end> should be four-digit hex numbers.
                     With one argument, <addr> which should be a four-digit hex number.
                     With no arguments, all utilized program memory.
* cycles              Displays current cycle count of core.
                     useful for getting cycles when stepping through code.