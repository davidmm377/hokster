# SoftLoader_Artix_7

Soft loader with for target board XC7A100TFTG256-3.

# Usage

This repo contains an archived Vivado project for the softloader program with the HOKSTER core. To run, unzip the archived project and open in Vivado. Generate a bitstream and export the hardware with the bitstream included. Depending on the system, the pins for reset and the UART may need to be adjusted. Then open XilinxSDK and create a new "Hello World" project. Remove the helloworld.c file from the project and copy the files in SoftLoader_program/ directory into the project. This should allow you to run a program on the HOKSTER core. The GCD program is already set up in mem_data.h and prog_data.h, but these files can be replace with the output of the assembler to run other programs.

The SoftLoader uses a UART with a baud rate of 9600 to communicate with the user. The easiest way to view the output is to use MobaXterm to connect to the device. At the end of operation, the SoftLoader will perform a dump of the CORE's memory. NOTE: using ISRs to catch the stop signal is not implemented yet, currently the softloader just delays a set amount of time (line 54 of main.c) to give the core time to finish.


# Current issues
- Add ability for soft loader to catch changes to SBUS using ISRs
- Testing on other boards: As of 3/13/20, the SoftLoader has only been tested on an Arty A7-35T. The specific Artix-7 and Nexys A7 targets need to be checked.