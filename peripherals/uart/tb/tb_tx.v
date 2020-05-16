`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  SAL, Virginia Tech
// Engineer: Minh Vu
// 
// Create Date:     03/31/2020
// Design Name:     UART
// Module Name:     tb_tx
// Project Name:    HOKSTER
// Target Devices:  Artix-7 (xc7a100tftg256-3)
// Tool Versions: 
// Description:     Test Bench for UART TX Module
// 
// Dependencies:    uart_tx.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_tx();

    // Inputs
    reg         clk_en, clock;
    reg         reset;
    reg [15:0]  auxaddr;
    reg  [7:0]  auxdin;
    reg         sbus_ack;
    
    // Outputs
    wire        ibus_line;
    wire        txout;
    
    // Debugging
    wire        baudrate_pulse;
    wire  [1:0] state;
    wire  [7:0] txdata;
    wire  [7:0] txsr;
    wire  [3:0] count;
    
    // UART TX Device Under Test (DUT)
    uart_tx dut(
        .clk(clock),
        .rst(reset),
        .addr(auxaddr),
        .txdata_in(auxdin),
        .ack(sbus_ack),
        .irq(ibus_line),
        .txout(txout),
        .baudpulse(baudrate_pulse),
        // Debugging:
        .state(state),
        .txdata_out(txdata),
        .txsr_out(txsr),
        .txctr_out(count)
    );
    
    // Set up clock
    initial begin
        clock = 1'b1;
        clk_en = 1'b1;
    end
    
    // 100MHz clock
    initial begin
        clock = 1'b1;
        while(clk_en) begin
            #5;
            clock = ~clock;
        end
    end
    
    // Test Procedure
    initial begin
        // Initialize inputs
        reset = 1'b0;
        auxaddr = 16'h0000;
        auxdin  = 8'h00;
        sbus_ack = 1'b0;
        
        // Reset module
        reset = 1'b1;
        #20;
        reset = 1'b0;
        #10;
        
        // Transmit byte
        auxaddr = 16'h0111;
        auxdin  = 8'hA9;
        #20;
        auxaddr = 16'h0110;
        auxdin  = 8'h00;
        #20;
        auxaddr = 16'h0000;
        
        // Wait to finish transmitting
        #86810;
        
        // Acknowledge interrupt
        sbus_ack = 1'b1;
        #10;
        sbus_ack = 1'b0;
        #10;
        
        // Transmit another byte
        auxaddr = 16'h0111;
        auxdin  = 8'h27;
        #20;
        // Try writing another byte to replace the last one
        auxaddr = 16'h0111;
        auxdin  = 8'h53;
        #20;
        auxaddr = 16'h0110;
        auxdin  = 8'h00;
        #20;
        auxaddr = 16'h0000;
        
        // Wait to finish transmitting
        #86810;
        
        // Acknowledge interrupt
        sbus_ack = 1'b1;
        #10;
        sbus_ack = 1'b0;
        #10;
        
        clk_en = 1'b0;
        $finish;
    end

endmodule
