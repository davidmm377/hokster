`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 03/11/2020 11:07:57 PM
// Author: Luke Beckwith
// Module Name: aic_ise
// Project Name: HOKSTER
// Description: Implementation of inverse AES mixColumns, requires multiple cycles and calls
//////////////////////////////////////////////////////////////////////////////////



module aic_ise(
    input clk,
    input rst,
    input start,
    input [7:0] a,
    input [7:0] b,
    input [7:0] sr,
    output [7:0] sr_out,
    output [7:0] result,
    output reg wait_req
    );
    
    // does not use status registers
    assign sr_out = sr;

    localparam
        LOAD_0_1          = 3'd0,
        LOAD_2_3_UNLOAD_3 = 3'd1,
        UNLOAD_2          = 3'd2,
        UNLOAD_1          = 3'd3,
        UNLOAD_0          = 3'd4;
    reg [2:0] state = LOAD_0_1, state_next;
    
    // calculation registers
    reg [7:0] s0 = 0, s1 = 0, s2 = 0, s3 = 0;
    reg wait_req_reg = 0;
       
    // FSM that performs mutliplication and addition for calculation of S' values
    reg start_ma;
    reg [1:0] sel_ma;
    wire done_ma;
    aic_mul_acc multiplier_accumulator(clk, rst, start_ma, s0, s1, s2, s3, sel_ma, result, done_ma );
    
    always @(*) begin
        wait_req = wait_req_reg;
        case (state) 
        LOAD_0_1: begin
            state_next = (start) ? LOAD_2_3_UNLOAD_3 : LOAD_0_1;
        end
        LOAD_2_3_UNLOAD_3: begin
            state_next = (done_ma) ? UNLOAD_2 : LOAD_2_3_UNLOAD_3;
            wait_req = (start) ? 1'b1 : wait_req_reg;
        end
        UNLOAD_2: begin
            state_next = (done_ma) ? UNLOAD_1 : UNLOAD_2;
            wait_req = (start)? 1'b1 : wait_req_reg;
        end
        UNLOAD_1: begin
            state_next = (done_ma) ? UNLOAD_0 : UNLOAD_1;
            wait_req = (start)? 1'b1 : wait_req_reg;
        end
        UNLOAD_0: begin
            state_next = (done_ma) ? LOAD_0_1 : UNLOAD_0;
            wait_req = (start)? 1'b1 : wait_req_reg;
        end
        default: begin
            state_next = LOAD_0_1;
        end
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        state <= (rst) ? LOAD_0_1 : state_next;
    end
    
    // sequential output logic
    always @(posedge clk) begin
        wait_req_reg <= 1'b0;
        start_ma <= 1'b0;
        
        case (state) 
        LOAD_0_1: begin
            sel_ma <= 0;
            
            s0 <= a;
            s1 <= b;
        end
        LOAD_2_3_UNLOAD_3: begin
            if (start) begin
                s2 <= a;
                s3 <= b;
                
                sel_ma <= 3;
                start_ma <= 1'b1;
                wait_req_reg <= 1'b1;
            end else begin
                wait_req_reg <= (done_ma == 1'b1) ? 1'b0 : wait_req_reg;
            end
        end
        UNLOAD_2: begin
            if (start) begin
                sel_ma <= 2;
                start_ma <= 1'b1;
                wait_req_reg <= 1'b1;
            end else begin
                wait_req_reg <= (done_ma == 1'b1) ? 1'b0 : wait_req_reg;
            end
        end
        UNLOAD_1: begin
            if (start) begin
                sel_ma <= 1;
                start_ma <= 1'b1;
                wait_req_reg <= 1'b1;
            end else begin
                wait_req_reg <= (done_ma == 1'b1) ? 1'b0 : wait_req_reg;
            end
        end
        UNLOAD_0: begin
            if (start) begin
                sel_ma <= 0;
                start_ma <= 1'b1;
                wait_req_reg <= 1'b1;
            end else begin
                wait_req_reg <= (done_ma == 1'b1) ? 1'b0 : wait_req_reg;
            end
        end
        endcase
    end
    
endmodule
