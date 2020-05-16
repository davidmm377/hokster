`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 02/26/2020 11:07:57 PM
// Author: Luke Beckwith
// Module Name: amc_ise
// Project Name: HOKSTER
// Description: Implementation of AES mixColumns, requires multiple cycles and calls
//////////////////////////////////////////////////////////////////////////////////


module amc_ise(
    input clk,
    input rst,
    input start,
    input [7:0] a,
    input [7:0] b,
    input [7:0] sr,
    output [7:0] sr_out,
    output reg [7:0] result,
    output reg wait_req
    );
    
    // does not use status registers
    assign sr_out = sr;

    localparam
        LOAD_0_1            = 3'd0,
        LOAD_2_3_UNLOAD_3   = 3'd1,
        CALC_1              = 3'd2,
        CALC_2              = 3'd3,
        UNLOAD_2            = 3'd4,
        UNLOAD_1            = 3'd5,
        UNLOAD_0            = 3'd6;
    reg [2:0] state = LOAD_0_1, state_next;

    reg [7:0] s0 = 0, s1 = 0, s2 = 0;
    reg [7:0] s_sum = 0, xtime_input = 0;
    reg wait_req_reg = 0;
    
    wire [7:0] xtime_result;
    assign xtime_result = (xtime_input[7] == 1'b1) ? {xtime_input[6:0], 1'b0} ^ 8'h1b : {xtime_input[6:0], 1'b0};

    always @(*) begin
        wait_req = wait_req_reg;
        case (state) 
        LOAD_0_1: begin
            state_next = (start) ? LOAD_2_3_UNLOAD_3 : LOAD_0_1;
        end
        LOAD_2_3_UNLOAD_3: begin
            state_next = (start) ? CALC_1 : LOAD_2_3_UNLOAD_3;
            wait_req = (start)? 1'b1 : wait_req_reg;
        end
        CALC_1: begin
            state_next = CALC_2;
        end
        CALC_2: begin
            state_next = UNLOAD_2;
        end
        UNLOAD_2: begin
            state_next = (start) ? UNLOAD_1 : UNLOAD_2;
        end
        UNLOAD_1: begin
            state_next = (start) ? UNLOAD_0 : UNLOAD_1;
        end
        UNLOAD_0: begin
            state_next = (start) ? LOAD_0_1 : UNLOAD_0;
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
        result <= 0;
        
        if (rst == 1'b1) begin
            s_sum <= 0;
            s0 <= 0;
            s1 <= 0;
            s2 <= 0;
        end else begin
            case (state) 
            LOAD_0_1: begin
                s0 <= 0;
                s1 <= 0;
                s2 <= 0;
                if (start) begin
                    s_sum <= a ^ b;
                    s0 <= a;
                    s1 <= b;
                end
            end
            LOAD_2_3_UNLOAD_3: begin
                if (start) begin
                    s_sum <= s_sum ^ a;
                    s2 <= a;
                                       
                    wait_req_reg <= 1'b1;
                end
            end
            CALC_1: begin
                s_sum <= s_sum ^ b;
                
                // prep for next calc
                xtime_input <= b ^ s0;
                
                wait_req_reg <= 1'b1;
            end
            CALC_2: begin
                result <= b ^ xtime_result ^ s_sum; // S_3' result
                
                // prep for next calc
                xtime_input <= s2 ^ b;
            end
            UNLOAD_2: begin
                result <= s2 ^ xtime_result ^ s_sum; // S_2' result
                    
                if (start) begin    
                    // prep for next calc
                    xtime_input <= s1 ^ s2;
                end
            end
            UNLOAD_1: begin
                result <= s1 ^ xtime_result ^ s_sum; // S_1' result
                
                if (start) begin    
                    // prep for next calc
                    xtime_input <= s0 ^ s1;
                end
            end
            UNLOAD_0: begin
                result <= s0 ^ xtime_result ^ s_sum; // S_0' result
            end
            endcase
        end   
    end
    
endmodule
