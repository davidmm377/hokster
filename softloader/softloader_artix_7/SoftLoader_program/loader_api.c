#include "loader_api.h"

volatile uint32_t *dummy_core_ptr = (uint32_t *) BASE_ADDR;
volatile uint16_t *dummy_addr_core_ptr = (uint16_t *) (BASE_ADDR + 4*ADDR_REG);
volatile uint8_t *dummy_data_core_ptr = (uint8_t *) (BASE_ADDR + 4*DATA_REG);
volatile uint8_t *dummy_output_core_ptr = (uint8_t *) (BASE_ADDR + 4*OUTPUT_REG);

uint32_t read_gen_reg(int i) {
	return dummy_core_ptr[i];
}

// val: 1 or 0
void set_rst(uint8_t val) {
	if (val == 1)
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] | RST_MASK;
	else
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] & ~RST_MASK;
}

// val: 1 or 0
void set_start(uint8_t val) {
	if (val == 1)
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] | START_MASK;
	else
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] & ~START_MASK;
}

// val: 1 or 0
void set_extdataload(uint8_t val) {
	if (val == 1)
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] | EXT_DATA_LOAD_MASK;
	else
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] & ~EXT_DATA_LOAD_MASK;
}

// val: 1 or 0
void set_extprogload(uint8_t val) {
	if (val == 1)
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] | EXT_PROG_LOAD_MASK;
	else
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] & ~EXT_PROG_LOAD_MASK;
}

// val: 1 or 0
void set_extdaddrsel(uint8_t val) {
	if (val == 1)
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] | EXT_DADDR_SEL_MASK;
	else
		dummy_core_ptr[CTRL_REG] = dummy_core_ptr[CTRL_REG] & ~EXT_DADDR_SEL_MASK;
}

// val: 0x00-0xff
void set_extdin(uint8_t val) {
	dummy_data_core_ptr[EXT_DIN_MASK] = val;
}

// val: 0x00-0xffff
void set_daddr(uint16_t val) {
	dummy_addr_core_ptr[EXT_DADDR_MASK] = val & 0xffff;
}

// val: 0x00-0xff
void set_extprogin(uint8_t val) {
	dummy_data_core_ptr[EXT_PROG_IN_MASK] = val;
}

// val: 0x00-0xfff
void set_paddr(uint16_t val) {
	dummy_addr_core_ptr[EXT_PADDR_MASK] = val & 0x0fff;
}

uint8_t read_extdout() {
	return dummy_output_core_ptr[EXTDOUT_MASK];
}

uint8_t read_sbus() {
	return dummy_output_core_ptr[SBUS_MASK];
}

int check_hokster_conn() {
	if ((read_gen_reg(3) >> 16) == 0xBEEF)
		return 1;
	else
		return 0;
}

void reset_hokster(){
	set_rst(1);
	set_rst(0);
}

void start_hokster(){
	set_start(1);
	set_start(0);
}

void load_program(uint8_t *prog, uint8_t prog_size){
	uint8_t i;
	for(i = 0; i < prog_size; i++) {
		set_extprogin(prog[i]);
		set_paddr(i);
		set_extprogload(1);
		set_extprogload(0);
	}
}

void load_memory(uint8_t *mem, uint8_t mem_size){
	uint8_t i;

	set_extdaddrsel(1);
	for(i = 0; i < mem_size; i++) {
		set_extdin(mem[i]);
		set_daddr(i);

		set_extdataload(1);
		set_extdataload(0);
	}
	set_extdaddrsel(0);
}

void dump_memory(int depth) {
	int dump_width = 8; // number of bytes per row

	set_extdaddrsel(1);
	int i;
	for (i = 0; i < depth; i++) {
		set_daddr(i);
		if (i !=0 && i%dump_width == 0)
			xil_printf("\n\r");
		xil_printf("%02X ", read_extdout());
	}
	set_extdaddrsel(0);
	xil_printf("\n\r");
}

