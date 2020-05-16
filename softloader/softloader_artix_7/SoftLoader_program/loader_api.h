/*
 * loader_api.h
 *
 *  Created on: Feb 28, 2020
 *      Author: lukeb
 */
#ifndef SRC_LOADER_API_H_
#define SRC_LOADER_API_H_

#include <stdio.h>

// peripheral base address
#define DUMMY_ADDR 0x44a00000
#define CORE_ADDR  0x44a10000
#define BASE_ADDR CORE_ADDR

// CTRL reg bits
#define CTRL_REG 0
#define RST_MASK           0x00000001
#define START_MASK         0x00000002
#define EXT_PROG_LOAD_MASK 0x00000004
#define EXT_DATA_LOAD_MASK 0x00000008
#define EXT_DADDR_SEL_MASK 0x00000010

// DATA reg bits
#define DATA_REG 1
#define EXT_PROG_IN_MASK 0
#define EXT_DIN_MASK 1

// ADDR reg bits
#define ADDR_REG 2
#define EXT_DADDR_MASK 0
#define EXT_PADDR_MASK 1

// OUTPUT reg bits
#define OUTPUT_REG 3
#define EXTDOUT_MASK 0
#define SBUS_MASK 1

// Check for "magic value" 0xBEEF on AXI IP. Return 1 if it was found
int check_hokster_conn();

// Sends reset signal to HOKSTER core
void reset_hokster();

// Sends start signal to HOKSTER core
void start_hokster();

// Loads byte array into program memory
void load_program(uint8_t *prog, uint8_t prog_size);

// loads byte array into data memory
void load_memory(uint8_t *mem, uint8_t mem_size);

// displays memory to depth over UART
void dump_memory(int depth);

// generic call to read a 32-bit AXI register
uint32_t read_gen_reg(int i);

// read value on sbus
uint8_t read_sbus();

// read current output value
uint8_t read_extdout();


#endif /* SRC_LOADER_API_H_ */
