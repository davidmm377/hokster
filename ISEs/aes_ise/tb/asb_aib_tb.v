`timescale 1ns / 1ps
`timescale 1ns / 1ps
`define P 10


module asb_aib_tb;
    // simple test db 13 53 45 -> 8e 4d a1 bc
    reg [7:0] a, a_inv;
    reg [7:0] b, b_inv;
    reg [7:0] sr;
    reg start, start_inv, clk, rst;
    wire [7:0] sr_out;
    wire [7:0] result, result_inv;
    wire wait_req, wait_req_inv;

    amc_ise uut1(clk, rst, start, a, b, sr, sr_out, result, wait_req);
    aic_ise uut2(clk, rst, start_inv, a_inv, b_inv, sr, sr_out, result_inv, wait_req_inv);
    
    integer correct;
    reg [8:0] test_num;
    reg [7:0] out0, out1, out2, out3;
    
    initial begin
        // initial signals
        clk = 0;
        
        
        sr = 0;
        start = 0;
        
        correct = 0;
        rst = 1'b1; #(`P); rst = 1'b0; #(`P);
        $display("Simple test start.");
        for (test_num = 0; test_num < 253; test_num = test_num + 1) begin
            $display("Run %d", test_num);
            
            a = test_num;
            b = test_num + 1;
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            
            a = test_num + 2;
            b = test_num + 3;
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            out3 = result;
            
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            out2 = result;
            
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            out1 = result;
            
            start = 1'b1; #(`P); start = 1'b0; #(`P); while (wait_req == 1'b1) #(`P); // run and wait for finish
            out0 = result;

            a_inv = out0;
            b_inv = out1;
            start_inv = 1'b1; #(`P); start_inv = 1'b0; #(`P); while (wait_req_inv == 1'b1) #(`P); // run and wait for finish

            a_inv = out2;
            b_inv = out3;
            start_inv = 1'b1; #(`P); start_inv = 1'b0; #(`P); while (wait_req_inv == 1'b1) #(`P); // run and wait for finish
            if (result_inv !== test_num + 3) begin
                 $display("Err: %h != %h", result_inv, test_num + 3);
            end else begin
                correct = correct + 1;
            end
            
            start_inv = 1'b1; #(`P); start_inv = 1'b0; #(`P); while (wait_req_inv == 1'b1) #(`P); // run and wait for finish
            if (result_inv !== test_num + 2) begin
                 $display("Err: %h != %h", result_inv, test_num + 2);
            end else begin
                correct = correct + 1;
            end
            
            start_inv = 1'b1; #(`P); start_inv = 1'b0; #(`P); while (wait_req_inv == 1'b1) #(`P); // run and wait for finish
            if (result_inv !== test_num + 1) begin
                 $display("Err: %h != %h", result_inv, test_num + 1);
            end else begin
                correct = correct + 1;
            end
            
            start_inv = 1'b1; #(`P); start_inv = 1'b0; #(`P); while (wait_req_inv == 1'b1) #(`P); // run and wait for finish
            if (result_inv !== test_num) begin
                 $display("Err: %h != %h", result_inv, test_num);
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
