`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/30/2020 01:08:09 AM
// Design Name: 
// Module Name: tb_baud
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Test bench for baud rate counter
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_baud();

    // Inputs
    reg clk_en, clock;
    reg reset;
    reg ctr_en;
    
    // Outputs
    wire pulse;
    
    // DUT
    counter ctr(
        .clk(clock),
        .rst(reset),
        .en(ctr_en),
        .out(pulse)
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
        ctr_en = 1'b0;
        
        // Reset module
        reset = 1'b1;
        #20;
        reset = 1'b0;
        #10;
        
        // Do counting
        ctr_en = 1'b1;
        #90000;
        ctr_en = 1'b0;
        clk_en = 1'b0;        
    end

endmodule
