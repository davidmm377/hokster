`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  SAL, Virginia Tech
// Engineer: Minh Vu
// 
// Create Date:     02/13/2020
// Design Name:     
// Module Name:     mux2to1
// Project Name:    
// Target Devices:  Digilent Nexys A7-100T
// Tool Versions: 
// Description:     General 2-to-1 multiplexer (can set width of input/output)
// 
// Dependencies:    
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mux2to1 #(parameter SIZE=1) (
    input      [(SIZE-1):0] in0,
    input      [(SIZE-1):0] in1,
    input                   select,
    output reg [(SIZE-1):0] out
    );
    
    always@(select or in0 or in1) begin
        case(select)
            1'b0: out = in0;
            1'b1: out = in1;
            default: out = 'bx;
        endcase
    end
    
endmodule
