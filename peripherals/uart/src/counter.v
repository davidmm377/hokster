`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  SAL, Virginia Tech
// Engineer: Minh Vu
// 
// Create Date:     04/29/2020
// Design Name:     UART
// Module Name:     counter
// Project Name:    HOKSTER
// Target Devices:  Artix-7 (xc7a100tftg256-3)
// Tool Versions: 
// Description:     Counter with output pulse
// 
// Dependencies:    
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//      Reference: https://learn.digilentinc.com/Documents/262
// 
//////////////////////////////////////////////////////////////////////////////////


module counter(
    input clk,
    input rst,
    input en,
    output out
    );
    
    reg [15:0] count;
        
    // For UART, assuming clk is 100 MHz:
    // For 9600 baud rate, use 10416 as the max count
    // For 115200 baud rate, use 868 as the max count
    parameter MAX_COUNT = 16'd868; // 115200 baud rate
    
    always@(posedge clk) begin
        if(rst || count == MAX_COUNT - 1 || ~en) count <= 16'b0;
        else count <= count + 16'b1;
    end
    
    // Output pulse
    assign out = (count == MAX_COUNT - 1);
    
endmodule
