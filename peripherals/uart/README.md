# Universal Asynchronous Receiver-Transmitter (UART)
### Minh Vu, Spring 2020, HOKSTER Custom Softcore Microprocessor

## Description

The UART module allows for a user to transmit and receive bytes of data serially. This is intended, for example, to allow the softcore to communicate with a computer via USB serial port.

## Usage
*(Subject to change)*

### TX:
1. Set up the interrupt that corresponds with which `ibus` signal in the core is connected to the `irq` signal in the UART module. For example, if `irq` is connected to bit 1 of the core's `ibus`, set up interrupt 1.
    * Refer to the HOKSTER manual for more information on interrupts.

2. Load byte to transmit (via `auxdin`) to address **0x0111** (via `auxdaddr`) using the `stb (sth/stw)` instruction.

3. Write any value to address **0x0110** using the `stb (sth/stw)` instruction to begin transmitting the previously loaded byte.

4. The module will raise an interrupt once it is done transmitting. In the corresponding ISR, acknowledge the appropriate interrupt using the `sys` instruction (to assert the `ack` signal).

5. To transmit another byte, repeat steps 2-4 again.

Memory-mapped addresses:

| Address | Description                                               |
| ------- |-----------------------------------------------------------|
| 0x0110  | Control address (start transmit)                          |
| 0x0111  | Byte to transmit                                          |
