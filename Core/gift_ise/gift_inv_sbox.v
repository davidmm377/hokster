`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2020 12:47:37 PM
// Design Name: 
// Module Name: gift_inv_sbox
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module gift_inv_sbox(
    input [7:0] in,
    output [7:0] out
    );
    assign out[3:0] = (in[3:0] == 4'h0) ? 4'd13 :
                            (in[3:0] == 4'h1) ? 4'd0 :
                            (in[3:0] == 4'h2) ? 4'd8 :
                            (in[3:0] == 4'h3) ? 4'd6 :
                            (in[3:0] == 4'h4) ? 4'd2 :
                            (in[3:0] == 4'h5) ? 4'd12 :
                            (in[3:0] == 4'h6) ? 4'd4 :
                            (in[3:0] == 4'h7) ? 4'd11 :
                            (in[3:0] == 4'h8) ? 4'd14 :
                            (in[3:0] == 4'h9) ? 4'd7 :
                            (in[3:0] == 4'ha) ? 4'd1 :
                            (in[3:0] == 4'hb) ? 4'd10 :
                            (in[3:0] == 4'hc) ? 4'd3 :
                            (in[3:0] == 4'hd) ? 4'd9 :
                            (in[3:0] == 4'he) ? 4'd15 : 4'd5;
    assign out[7:4] = (in[7:4] == 4'h0) ? 4'd13 :
                            (in[7:4] == 4'h1) ? 4'd0 :
                            (in[7:4] == 4'h2) ? 4'd8 :
                            (in[7:4] == 4'h3) ? 4'd6 :
                            (in[7:4] == 4'h4) ? 4'd2 :
                            (in[7:4] == 4'h5) ? 4'd12 :
                            (in[7:4] == 4'h6) ? 4'd4 :
                            (in[7:4] == 4'h7) ? 4'd11 :
                            (in[7:4] == 4'h8) ? 4'd14 :
                            (in[7:4] == 4'h9) ? 4'd7 :
                            (in[7:4] == 4'ha) ? 4'd1 :
                            (in[7:4] == 4'hb) ? 4'd10 :
                            (in[7:4] == 4'hc) ? 4'd3 :
                            (in[7:4] == 4'hd) ? 4'd9 :
                            (in[7:4] == 4'he) ? 4'd15 : 4'd5;
endmodule

