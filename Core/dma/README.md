# Direct Memory Access (DMA)
### Minh Vu, Spring 2020, HOKSTER Custom Softcore Microprocessor


## Description

The direct memory access peripheral allows the user to copy a region of data from one memory location to another.
It is meant to interface with the DRAM module (found at https://gitlab.com/hokster/core/-/blob/master/DRAM.vhd).

Example code for reference is found in the "test_prog" directory.

## Usage

1. Set up the interrupt that corresponds with which `ibus` signal in the core is connected to the `irq` signal in the DMA. For example, if `irq` of the DMA is connected to bit 1 of the core's `ibus`, set up interrupt 1.
    * Refer to the HOKSTER manual for more information on interrupts.

2. Set desired source and destination start addresses by loading values (via `auxdin`) to appropriate addresses (via `auxdaddr`) using the `stb (sth/stw)` instruction.
    * _It is the user's responsibility to ensure that all parameters are correctly set._

3. Write any value to address 0x0100 using the `stb (sth/stw)` instruction to begin the transfer operation.

4. Use the `hlt` instruction to halt the processor until the DMA completes its operation and asserts an interrupt (`irq` signal).

5. In the corresponding ISR, acknowledge the appropriate interrupt using the `sys` instruction (to assert the `ack` signal). This sets the DMA back to its idle state.
    * Currently, DMA parameters do not reset themselves after the DMA has run (except for n, which stays constant).
    * The user should set all parameters again before starting another memory transfer.


Memory-mapped addresses:

| Address | Description                                               |
| ------- |-----------------------------------------------------------|
| 0x0100  | Control address (start transfer)                          |
| 0x0101  | Least-significant 8 bits of **source** start address      |
| 0x0102  | Most-significant 8 bits of **source** start address       |
| 0x0103  | Least-significant 8 bits of **destination** start address |
| 0x0104  | Most-significant 8 bits of **destination** start address  |
| 0x0105  | n, where (n+1) << G is number of bytes to transfer        |

G can range between 0 and 4, default is 2. The user can change this parameter at synthesis time.

