`timescale 1ns / 1ps
`define P 10


module swd_tb;
reg [7:0] a;
    reg [7:0] b;
    reg [7:0] sr;
    reg start, clk, rst;
    wire [7:0] sr_out;
    wire [7:0] result;
    wire wait_req;

    swd_ise uut(clk, rst, start, a, b, sr, sr_out, result, wait_req);

    // test vector data
    reg [0:71] testvectors [63:0];
    reg [31:0] input_vec;
    reg [7:0] shift_amount;
    reg [31:0] output_vec;
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

        $readmemh("D:/programming/instruction_set_extensions/instruction_set_extensions.srcs/sim_1/new/swd.txt", testvectors);
       
        for (test_num = 0; test_num < 64; test_num = test_num + 1) begin
            input_vec = testvectors[test_num][0:31];
            shift_amount = testvectors[test_num][32:39];
            output_vec = testvectors[test_num][40:71];
            
            // load in values
            for (j = 0; j < 4; j = j + 2) begin
                a = input_vec[j*8+:8];
                b = input_vec[(j+1)*8+:8];
                start = 1'b1; #(`P); start = 1'b0;  
                while (wait_req == 1'b1) #(`P); // run and wait for finish
            end
        
            // enter shift amount and unload first value
            a = shift_amount;
            start = 1'b1; #(`P); start = 1'b0;  
            while (wait_req == 1'b1) #(`P); // run and wait for finish
            // get first result
            if (result !== output_vec[31:24]) begin
                 $display("Err at 3: %h != %h", result, output_vec[31:24]);
                 total_errors = total_errors + 1;
            end else begin
//                $display("Correct: %h == %h", result, output_vec[127:120]);
                correct = correct + 1;
            end
            
            // unload last values
            for (j = 2; j >= 0; j = j - 1) begin
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