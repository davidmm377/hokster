`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 03/11/2020 11:07:57 PM
// Author: Luke Beckwith
// Module Name: aic_mul_acc
// Project Name: HOKSTER
// Description: Submodule for inverse mixcolumns. Calculates polynomial times constants 0x9, 0xb, 0xd, and 0xe in constant time.
//////////////////////////////////////////////////////////////////////////////////

module aic_multiplier(
    input clk,
    input rst,
    input start,
    input [7:0] in,
    input [3:0] coeff, // acceptable values are 9, 11, 13, 14 (for AES inverse mix columns)
    output reg [7:0] result,
    output reg done    
    );
    
    
    // shifter-multiplier FSM -> calculates 2x, 4x, 8x, for combining into other results
    localparam
        MUL_2   = 4'd0,
        MUL_4   = 4'd1,
        MUL_8   = 4'd2;
    reg [1:0] shifer_state = MUL_2;
    reg [7:0] in_2, in_4, in_8;
    
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            shifer_state <= MUL_2;
            in_2 <= 0;
            in_4 <= 0;
            in_8 <= 0;
        end else begin
            case (shifer_state)
            MUL_2: begin
                if (start) begin
                    in_2 <= (in[7] == 1'b1) ? {in[6:0], 1'b0} ^ 8'h1b : {in[6:0], 1'b0};
                    shifer_state <= MUL_4;
                end else begin
                    shifer_state <= MUL_2;
                end
            end
            MUL_4: begin
                in_4 <= (in_2[7] == 1'b1) ? {in_2[6:0], 1'b0} ^ 8'h1b : {in_2[6:0], 1'b0};
                shifer_state <= MUL_8;
            end
            MUL_8: begin
                in_8 <= (in_4[7] == 1'b1) ? {in_4[6:0], 1'b0} ^ 8'h1b : {in_4[6:0], 1'b0};
                shifer_state <= MUL_2;
            end     
            default: begin
                shifer_state <= MUL_2;
                in_2 <= 0;
                in_4 <= 0;
                in_8 <= 0;
            end
            endcase
        end
    end
    
    // main FSM
    localparam
        HOLD      = 4'd0,
        MUL_IN    = 4'd1,
        MUL_2IN   = 4'd2,
        MUL_4IN   = 4'd3,
        MUL_8IN   = 4'd4;
    reg [2:0] mult_state = HOLD;
    
    always @(posedge clk) begin
        done <= 0;
        
        if (rst == 1'b1) begin
            mult_state <= HOLD;
            result <= 0;
        end else begin
            case(mult_state)
            HOLD: begin
                result <= 0;
                if (start) begin
                    result <= (coeff[0] == 1) ? in : 8'b0;
                    mult_state <= MUL_2IN;
                end else begin
                    mult_state <= HOLD;
                end
            end
            MUL_2IN: begin
                result <= (coeff[1] == 1) ? result ^ in_2 : result;
                mult_state <= MUL_4IN;
            end
            MUL_4IN: begin
                result <= (coeff[2] == 1) ? result ^ in_4 : result;
                mult_state <= MUL_8IN;
            end
            MUL_8IN: begin
                result <= (coeff[3] == 1) ? result ^ in_8 : result;
                mult_state <= HOLD;
                done <= 1'b1;
            end
            default: begin
                mult_state <= HOLD;
                result <= 0;
            end
            endcase
        end
    end
    
endmodule
