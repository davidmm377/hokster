# Core
This directory contains the VHDL design of the HOKSTER core (and hardloader) and associated testbenches. A general description of the operation of the core can be found in the HOKSTER Manual: [upd6](https://github.com/willja001/hokster/blob/master/documentation/Hokster_Manual_upd6.pdf).

This README describes the steps needed to get started with the core.

Directory Structure:
```
core
|-- tb/
|   |-- various VHDL testbench files for core and hardloader modules
|
|-- core and hardloader VHDL design files
```

Setting up Vivado
-----------------
Vivado HL WebPACK Version 2019.2 was used to create this model. Other versions may also work.

1. Open Vivado and create a new project
2. Choose the name ("core" for example) and location of the project (this should be outside the cloned git repository)
3. Choose to create an *RTL Project*
4. Add the sources in the main directory and [ISEs](https://github.com/willja001/hokster/tree/master/ISEs)/[peripherals](https://github.com/willja001/hokster/tree/master/peripherals) directories of the repo as both *Synthesis & Simulation* and the sources in the `tb` directory as just *Simulation* sources
5. Add constraints (if applicable)
6. Choose the part/board you are targeting
7. Click *Finish*

Make sure `loader` is the top module of the design.

Simulation
----------
To simulate the full core in operation:

1. In the hierarchy view of Sources, choose a `loader_tb_<tb_name>` module as the top module of the simulation sources
2. Using the HOKSTER [assembler](https://github.com/willja001/hokster/tree/master/assembler), assemble the corresponding program under `../applications/<tb_name>` or `../peripherals/dma/test_prog/`
3. Add the `.hex` files the assembler created as simulation sources in the Vivado project (don't copy the file into project). This allows you to use just `"<tb_name>_prog.hex"` and `"<tb_name>_data.hex"` as the paths in the `loader_tb_<tb_name>` as is default. Alternatively, open the VHDL module and change the `PROG_FILE` and `DATA_FILE` strings to point to the absolute path `<tb_name>_prog.hex` and `<tb_name>_data.hex`, respectively

When making a change to a program, you may have to change the `loader_tb_<tb_name>.vhd` file to get Vivado to reload the `.hex` files.

Synthesis
---------
When synthesizing the design, the default values of the generics in `loader.vhd` are the ones that are used throughout the project. You are able to choose what program is loaded by changing the `PROG_FILE` and `DATA_FILE` strings as described in the previous section. The `.hex` files in this case need to be design sources and set as *Data Files* in Vivado using "Set file type..."
