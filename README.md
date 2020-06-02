# HOKSTER

![HOKSTER Logo](/documentation/Hokster_Logo.png)

Hardware-Oriented *Kustom* Security Test & Evaluation Resource (HOKSTER) is a custom-designed 8-bit soft core processor. Intended to be lightweight, HOKSTER is a load-store architecture that supports only 38 instructions by default (although more can be added via instruction set extensions). Details of the architecture and HOKSTER assembly language can be found in the [HOKSTER Manual](/documentation/Hokster_Manual_upd6.pdf) under documentation/, but for a summary of the primary features of HOKSTER:

* Harvard architecture with separate program memory (up to 4 KiB) and data memory (up to 64 KiB) configurable at synthesis time.
* 16 near-general-purpose 8-bit registers (a7-a0 and r7-r0) with the ability to address 16 bits of data memory using register pairs of the form ai || ri.
* Supports up to 16 hardware instruction set extensions (ISEs) that can take a variable number of clock cycles to complete.
* Supports (data) memory-mapped peripherals allowing for more advanced accelerators, interfacing, and other hardware operations, such as a DMA controller.
* Supports up to 16 vectored, maskable interrupts from peripherals and external sources. Interrupts have priority, but nested interrupts are not supported. HOKSTER can halt operation pending a valid interrupt to save energy.

Currently, there is no high-level language compiler for the architecture, so programs are written in the HOKSTER assembly language and assembled using HoksterAssembler (found under assembler/ in this repository). Assembled programs can be run in HoksterSim, a cycle-accurate python simulator of the processor with the ability to step through programs, set breakpoints, and manipulate memory.

There are two supported pathways for loading assembled programs into the core. The hard loader found under Core/ in this repository loads the program and data memories and starts the soft core. This loader is useful for hardware simulation of HOKSTER, such as in Vivado Sim. The other pathway is called the soft loader, which uses a MicroBlaze to interface with the HOKSTER soft core for programming and output validation. The purpose of this pathway is to allow for easy validation and benchmarking of HOKSTER in FPGA.

Also in this repository is the CryptoCore described in [this paper](https://ia.cr/2020/609), which introduces HOKSTER to implement three NIST Lightweight Cryptography (LWC) Standardization Process Round 2 AEAD candidates (COMET-AES, COMET-CHAM and GIFT-COFB). This work uses HOKSTER configured with four ISE modules (asb, amc, swd, gsp) for improved cryptographic performance.

## Repository Structure

```text
hokster
|-- Core/
|   |-- VHDL files for soft core and associated test benches
|
|-- ISEs/
|   |-- Instruction Set Extension modules
|
|-- LWC/
|   |-- CryptoCore project using HOKSTER to implement 3 NIST LWC Standardization candidate ciphers
|
|-- applications/
|   |-- HOKSTER ASM programs, including AES, GIFT, and CHAM encryption programs
|
|-- assembler/
|   |-- HoksterAssembler - python3 assembler for HOKSTER ASM programs
|
|-- documentation/
|   |-- documentation describing HOKSTER
|
|-- peripherals/
|   |-- Peripherals for the soft core (currently DMA and UART TX)
|
|-- simulator/
|   |-- HoksterSim - python3 simulator of the soft core, allowing for easy debugging
|
|-- softloader/
    |-- project that instantiates a MicroBlaze processor for programming HOKSTER
```

## Getting Started

For getting started with HOKSTER tools, please see the README documents in the subdirectories of this repository.
