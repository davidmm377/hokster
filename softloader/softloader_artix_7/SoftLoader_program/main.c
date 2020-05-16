/*
 * main.c
 *
 *  Created on: Feb 29, 2020
 *      Author: lukeb
 */

// System includes
#include "platform.h"
#include "xil_printf.h"

// Soft loader includes
#include "loader_api.h"
#include "prog_data.h"
#include "mem_data.h"

int main()
{
	init_platform();

	print("\n\r======== New test beginning ======== \n\r");

	if (check_hokster_conn() == 1){
		print("Connection to HOKSTER IP was found.\n\r");
	} else {
		print("ERR: did not find expected value in HOKSTER IP reg3.\n\r");

		cleanup_platform();
		return 0;
	}

	// RESET SYSTEM
	reset_hokster();
	xil_printf("Processor reset.\n\r");

	// LOAD PROGRAM
	load_program(HOKSTER_INSTRUCTIONS, PROG_LEN);
	xil_printf("Program loaded.\n\r");

	// LOAD MEMORY
	load_memory(HOKSTER_MEMORY, MEM_LEN);
	xil_printf("Data loaded, input data:\n\r");

	// DISPLAY INITIAL MEMORY
	dump_memory(32);

	// START HOKSTER
	start_hokster();
	xil_printf("Processor started.\n\r");

	// BURN TIME TO WAIT FOR PROCESSOR->HOTFIX
	volatile int ctr;
	xil_printf("Waiting");
	for (ctr = 0; ctr < 25; ctr++) {
		xil_printf(".");
	}
	xil_printf("\n\r");

	// DISPLAY FINAL MEMORY
	dump_memory(32);

	print("============ End of test ===========\n\r");

	cleanup_platform();
	return 0;

}

