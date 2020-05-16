`timescale 1ns / 1ps
`define P 10
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2020 09:46:57 AM
// Design Name: 
// Module Name: gsp_tb
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


module gsp_tb;
    reg [7:0] a;
    reg [7:0] b;
    reg [7:0] sr;
    reg start, clk, rst;
    wire [7:0] sr_out;
    wire [7:0] result;
    wire wait_req;

//    gip_ise uut(clk, rst, start, a, b, sr, sr_out, result, wait_req);
    gsp_ise uut(clk, rst, start, a, b, sr, sr_out, result, wait_req);

    // test vector data
    reg [0:255] testvectors [40:0];
    reg [127:0] input_vec;
    reg [127:0] output_vec;
    integer test_num, correct, j, total_errors;
     
    initial begin
        // initial signals
        clk = 0;
        rst = 0;
        
        sr = 0;
        start = 0;
        
        total_errors = 0;
        correct = 0;
        #(`P/2); #(`P);
        $display("Test start."); 
//        $readmemh("D:/programming/GIFT128/gip.txt", testvectors);
        $readmemh("D:/programming/GIFT128/gsp.txt", testvectors);
       
        for (test_num = 0; test_num < 80; test_num = test_num + 1) begin
            input_vec = testvectors[test_num][0:127];
            output_vec = testvectors[test_num][128:255];
            
            // load in values
            for (j = 0; j < 16; j = j + 2) begin
                a = input_vec[j*8+:8];
                b = input_vec[(j+1)*8+:8];
                start = 1'b1; #(`P); start = 1'b0;  
                while (wait_req == 1'b1) #(`P); // run and wait for finish
            end
             
            // check first result
            if (result !== output_vec[127:120]) begin
                 $display("Err at 15: %h != %h", result, output_vec[127:120]);
                 total_errors = total_errors + 1;
            end else begin
//                $display("Correct: %h == %h", result, output_vec[127:120]);
                correct = correct + 1;
            end
            
            // check unload
            
            for (j = 14; j >= 0; j = j - 1) begin
                start = 1'b1; #(`P); start = 1'b0; #(`P); 
                while (wait_req == 1'b1) #(`P); // run and wait for finish
                // check result
                
                if (result !== output_vec[j*8+:8]) begin
                     $display("Err at %d: %h != %h", j, result, output_vec[j*8+:8]);
                     total_errors = total_errors + 1;
                end else begin
//                    $display("Correct: %h == %h", result, output_vec[j*8+:8]);
                    correct = correct + 1;
                end
                
            end
            $display("Test %d done. Correct values : %d", test_num, correct);
            correct = 0;
        end
        
        $display("Test done. Total Errors : %d", total_errors);
        $finish;
    end
    
    always #(`P/2) clk = ~clk;
    
endmodule
`undef P
