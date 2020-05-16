`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 03/11/2020 11:07:57 PM
// Author: Luke Beckwith
// Module Name: aic_mul_acc
// Project Name: HOKSTER
// Description: Submodule for inverse mixcolumns. Calculates the poly multiplication/summation.
//////////////////////////////////////////////////////////////////////////////////


module aic_mul_acc(
    input clk,
    input rst,
    input start,
    input [7:0] s0,
    input [7:0] s1,
    input [7:0] s2,
    input [7:0] s3,
    input [1:0] sel,
    output reg [7:0] result,
    output reg done
    );
    
    // multiplier registers
    reg start_mul;
    reg [7:0] mul_in;
    reg [3:0] mul_coeff;
    wire [7:0] mul_result;
    wire mul_done;
    aic_multiplier multiplier (clk, rst, start_mul, mul_in, mul_coeff, mul_result, mul_done);
    
    localparam
        CALC_1 = 3'd0,
        CALC_2 = 3'd1,
        CALC_3 = 3'd2,
        CALC_4 = 3'd3,
        FINISH = 3'd4;
    reg [2:0] calc_state = CALC_1;
    
    always @(posedge clk) begin
        done <= 1'b0;
        start_mul <= 1'b0;
        if (rst == 1'b1) begin
            calc_state <= CALC_1;
            mul_in <= 0;
            mul_coeff <= 0;
        end else begin
            case (calc_state)
            CALC_1: begin
                if (start) begin
                    // setup multiplier
                    mul_in <= s0;
                    mul_coeff <= (sel == 2'd0) ? 4'he :
                                  (sel == 2'd1) ? 4'h9 :
                                  (sel == 2'd2) ? 4'hd : 4'hb;
                    
                    start_mul <= 1'b1;
                    calc_state <= CALC_2;
                end
            end
            CALC_2: begin
                if (mul_done) begin
                    result <= mul_result;
                    
                    // setup multiplier
                    mul_in <= s1;
                    mul_coeff <= (sel == 2'd0) ? 4'hb :
                                  (sel == 2'd1) ? 4'he :
                                  (sel == 2'd2) ? 4'h9 : 4'hd;
                    
                    start_mul <= 1'b1;
                    calc_state <= CALC_3;
                end else begin
                    calc_state <= CALC_2;
                end
            end
            CALC_3: begin
                if (mul_done) begin
                    result <= result ^ mul_result;
                    
                    // setup multiplier
                    mul_in <= s2;
                    mul_coeff <= (sel == 2'd0) ? 4'hd :
                                  (sel == 2'd1) ? 4'hb :
                                  (sel == 2'd2) ? 4'he : 4'h9;
                    
                    start_mul <= 1'b1;
                    calc_state <= CALC_4;
                end else begin
                    calc_state <= CALC_3;
                end
            end
            CALC_4: begin
                if (mul_done) begin
                    result <= result ^ mul_result;
                    
                    // setup multiplier
                    mul_in <= s3;
                    mul_coeff <= (sel == 2'd0) ? 4'h9 :
                                  (sel == 2'd1) ? 4'hd :
                                  (sel == 2'd2) ? 4'hb : 4'he;
                    
                    start_mul <= 1'b1;
                    calc_state <= FINISH;
                end else begin
                    calc_state <= CALC_4;
                end
            end
            FINISH: begin
                if (mul_done) begin
                    result <= result ^ mul_result;
                    
                    calc_state <= CALC_1;
                    done <= 1'b1;
                end else begin
                    calc_state <= FINISH;
                end
            end
            endcase
        end
    end
    
    
endmodule
