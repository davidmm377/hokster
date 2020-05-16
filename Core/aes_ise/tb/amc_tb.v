`timescale 1ns / 1ps
`define P 10
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/11/2020 02:44:17 PM
// Design Name: 
// Module Name: amc_tb
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


module amc_tb;
    // simple test db 13 53 45 -> 8e 4d a1 bc
    reg [7:0] a;
    reg [7:0] b;
    reg [7:0] sr;
    reg start, clk, rst;
    wire [7:0] sr_out;
    wire [7:0] result;
    wire wait_req;

    amc_ise uut(clk, rst, start, a, b, sr, sr_out, result, wait_req);
    
    // test vector data
    reg [0:63] testvectors [105:0];
    reg [0:31] input_vec;
    reg [0:31] output_vec;
    integer test_num, correct;
    
    initial begin
        // initial signals
        clk = 0;
        rst = 0;
        
        sr = 0;
        start = 0;
        
        correct = 0;
        #(`P); #(`P);
        $display("Simple test start.");
        $readmemh("D:/programming/instruction_set_extensions/instruction_set_extensions.srcs/sim_1/new/amc.txt", testvectors);
        for (test_num = 0; test_num < 106; test_num = test_num + 1) begin
            input_vec = testvectors[test_num][0:31];
            output_vec = testvectors[test_num][32:63];
            
            a = input_vec[0:7];
            b = input_vec[8:15];
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            
            a = input_vec[16:23];
            b = input_vec[24:31];
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            if (result !== output_vec[24:31]) begin
                 $display("Err: %h != %h", result, output_vec[24:31]);
            end else begin
                correct = correct + 1;
            end
            
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            if (result !== output_vec[16:23]) begin
                 $display("Err: %h != %h", result, output_vec[16:23]);
            end else begin
                correct = correct + 1;
            end
            
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            if (result !== output_vec[8:15]) begin
                 $display("Err: %h != %h", result, output_vec[8:15]);
            end else begin
                correct = correct + 1;
            end
            
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            if (result !== output_vec[0:7]) begin
                 $display("Err: %h != %h", result, output_vec[0:7]);
            end else begin
                correct = correct + 1;
            end
        end

        $display("Simple test done. Correct values : %d", correct);
        $finish;
    end
    
    always #(`P/2) clk = ~clk;
    
endmodule
`undef P
