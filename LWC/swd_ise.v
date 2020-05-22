`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2020 02:40:38 PM
// Design Name: 
// Module Name: swd_ise
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


module swd_ise(
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
        LOAD_0_1       = 3'd0,
        LOAD_2_3       = 3'd1,
        SHIFT_UNLOAD_3 = 3'd2,
        UNLOAD_2       = 3'd3,
        UNLOAD_1       = 3'd4,
        UNLOAD_0       = 3'd5;
    reg [2:0] state, state_next;
    
    // barrel shifter logic
    wire [31:0] shifter_out;
    reg [31:0] shifter_in = 0;
    reg [4:0] shift_amount = 0;
    reg wait_req_reg;
    assign shifter_out = (shifter_in << shift_amount) | (shifter_in >> 6'd32 -  shift_amount);
    
    // combinational state logic
    always @(*) begin
        wait_req = wait_req_reg;
        case (state) 
        LOAD_0_1: begin
            state_next = (start) ? LOAD_2_3 : LOAD_0_1;
        end
        LOAD_2_3: begin
            state_next = (start) ? SHIFT_UNLOAD_3 : LOAD_2_3;
        end
        SHIFT_UNLOAD_3: begin
            wait_req = (start) ? 1'b1 : wait_req;
            state_next = (wait_req_reg) ? UNLOAD_2 : SHIFT_UNLOAD_3;
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
        shift_amount <= shift_amount;
        shifter_in <= shifter_in;
    
        if (rst == 1'b1) begin
            result <= 8'd0;
            shift_amount <= 5'd0;
        end else begin
            case (state) 
            LOAD_0_1: begin
                if (start) begin
                    shifter_in[7:0] <= a;
                    shifter_in[15:8] <= b;
                end
            end
            LOAD_2_3: begin
                if (start) begin
                    shifter_in[23:16] <= a;
                    shifter_in[31:24] <= b;
                end
            end
            SHIFT_UNLOAD_3: begin
                result <= shifter_out[31:24];
                if (start) begin
                    shift_amount <= a[4:0];
                    wait_req_reg <= 1'b1;
                end
            end
            UNLOAD_2: begin
                    result <= shifter_out[23:16];
            end
            UNLOAD_1: begin
                    result <= shifter_out[15:8];
            end
            UNLOAD_0: begin
                    result <= shifter_out[7:0];
            end
            endcase
        end
    end
endmodule
