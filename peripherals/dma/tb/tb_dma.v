`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  SAL, Virginia Tech
// Engineer: Minh Vu
// 
// Create Date:     02/10/2020
// Design Name:     DMA (Direct Memory Access)
// Module Name:     tb_dma
// Project Name:    HOKSTER
// Target Devices:  Digilent Nexys A7-100T
// Tool Versions: 
// Description:     Test bench for DMA module
// 
// Dependencies:    dma.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_dma();
    // Inputs:
    reg        clk_en, clock;
    reg        reset;
    reg [15:0] auxdaddr;
    reg  [7:0] auxdin;
    reg  [7:0] extdout;
    reg        ack;
    
    // Outputs:
    wire        irq;
    wire        auxdoutsel;
    wire  [7:0] extdin;
    wire [15:0] extdaddr;
    wire        extwe;
    
    // Debugging:
    wire  [2:0] state;
    wire  [15:0] counter;
    wire  [15:0] numbytes;
        
    // DMA Device Under Test (DUT)
    dma dut(
        .clk(clock),
        .rst(reset),
        .auxdaddr(auxdaddr),
        .auxdin(auxdin),
        .extdout(extdout),
        .ack(ack),
        .irq(irq),
        .auxdoutsel(auxdoutsel),
        .extdin(extdin),
        .extdaddr(extdaddr),
        .extwe(extwe),
        .state(state),
        .counter(counter),
        .numbytes(numbytes)
    );
    
    // Set up clock
    initial begin
        clock = 1'b1;
        clk_en = 1'b1;
    end
    
    initial begin
        clock = 1'b1;
        while(clk_en) begin
            #5;
            clock = ~clock;
        end
    end
    
    // Test
    initial begin
        // Initialize inputs
        reset = 4'b0;
        auxdaddr = 16'h0000;
        auxdin  = 8'h00;
        extdout = 8'h00;
        ack = 1'b0;
        
        // Reset device
        #10;
        reset = 4'b1;
        #10;
        reset = 4'b0;
        
        // Write to parameter registers
        #10;
        // Source address
        auxdaddr = 16'h0101;
        auxdin  = 8'h20;
//        extdout = 8'h96; // Emulate some data
        #20;
        auxdaddr = 16'h0102;
        auxdin  = 8'h00;
        #20;
        // Destination address
        auxdaddr = 16'h0103;
        auxdin  = 8'h30;
        #20;
        auxdaddr = 16'h0104;
        auxdin  = 8'h00;
        #20;
        // Number of bytes to transfer
        // User sets n, in which (n+1) << 2 is number of bytes
        auxdaddr = 16'h0105;
        auxdin  = 8'h03;
        #20;
        // Start
        auxdaddr = 16'h0100;
        auxdin  = 8'hff;
        #20;
        auxdaddr = 16'h0000;
        auxdin  = 8'h00;
//        extdout = 8'h00;
        
        // Do transfer
        #490;
        
        // Acknowledge irq after transfer is done
        ack = 1'b1;
        #10;
        ack = 1'b0;
        #20;
        
        // Disable clock
        clk_en = 1'b0;
        $finish;
    end

endmodule
