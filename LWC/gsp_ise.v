`timescale 1ns / 1ps

module gsp_ise(
    input clk,
    input rst,
    input start,
    input [7:0] a,
    input [7:0] b,
    input [7:0] sr,
    output [7:0] sr_out,
    output reg [7:0] result = 0,
    output reg wait_req
    );
    
    // does not use status registers
    assign sr_out = sr;
    
    localparam
        LOAD_0_1             = 5'd0,
        LOAD_2_3             = 5'd1,
        LOAD_4_5             = 5'd2,
        LOAD_6_7             = 5'd3,
        LOAD_8_9             = 5'd4,
        LOAD_10_11           = 5'd5,
        LOAD_12_13           = 5'd6,
        LOAD_14_15_UNLOAD_15 = 5'd7,
        UNLOAD_14            = 5'd8,
        UNLOAD_13            = 5'd9,
        UNLOAD_12            = 5'd10,
        UNLOAD_11            = 5'd11,
        UNLOAD_10            = 5'd12,
        UNLOAD_9             = 5'd13,
        UNLOAD_8             = 5'd14,
        UNLOAD_7             = 5'd15,
        UNLOAD_6             = 5'd16,
        UNLOAD_5             = 5'd17,
        UNLOAD_4             = 5'd18,
        UNLOAD_3             = 5'd19,
        UNLOAD_2             = 5'd20,
        UNLOAD_1             = 5'd21,
        UNLOAD_0             = 5'd22;
    reg [4:0] state = 0, state_next = 0;
    
    // GIFT 4-bit SBOX applied to input
    reg [7:0] sbox_ina = 0, sbox_inb = 0;
    wire [7:0] sbox_a, sbox_b;
    gift_sbox SBOX_1(a, sbox_a);       
    gift_sbox SBOX_2(b, sbox_b);  
    
    // GIFT 128-bit permutation
    reg [127:0] in = 0;
    wire [127:0] perm_out;
    gift_perm PERM(in, perm_out);
    
    reg wait_req_reg = 0;
    
    // combinational state logic
    always @(*) begin
        wait_req = wait_req_reg;
        case(state)
        LOAD_0_1: begin
            state_next = (start) ? LOAD_2_3 : LOAD_0_1;
        end
        LOAD_2_3: begin
            state_next = (start) ? LOAD_4_5 : LOAD_2_3;
        end
        LOAD_4_5: begin
            state_next = (start) ? LOAD_6_7 : LOAD_4_5;
        end
        LOAD_6_7: begin
            state_next = (start) ? LOAD_8_9 : LOAD_6_7;
        end
        LOAD_8_9: begin
            state_next = (start) ? LOAD_10_11 : LOAD_8_9;
        end
        LOAD_10_11: begin
            state_next = (start) ? LOAD_12_13 : LOAD_10_11;
        end
        LOAD_12_13: begin
            state_next = (start) ? LOAD_14_15_UNLOAD_15 : LOAD_12_13;
        end
        LOAD_14_15_UNLOAD_15: begin
            wait_req = (start) ? 1'b1 : wait_req_reg;
            state_next = (wait_req_reg) ? UNLOAD_14 : LOAD_14_15_UNLOAD_15;
        end
        UNLOAD_14: begin
            state_next = (start) ? UNLOAD_13 : UNLOAD_14;
        end
        UNLOAD_13: begin
            state_next = (start) ? UNLOAD_12 : UNLOAD_13;
        end
        UNLOAD_12: begin
            state_next = (start) ? UNLOAD_11 : UNLOAD_12;
        end
        UNLOAD_11: begin
            state_next = (start) ? UNLOAD_10 : UNLOAD_11;
        end
        UNLOAD_10: begin
            state_next = (start) ? UNLOAD_9 : UNLOAD_10;
        end
        UNLOAD_9: begin
            state_next = (start) ? UNLOAD_8 : UNLOAD_9;
        end
        UNLOAD_8: begin
            state_next = (start) ? UNLOAD_7 : UNLOAD_8;
        end
        UNLOAD_7: begin
            state_next = (start) ? UNLOAD_6 : UNLOAD_7;
        end
        UNLOAD_6: begin
            state_next = (start) ? UNLOAD_5 : UNLOAD_6;
        end
        UNLOAD_5: begin
            state_next = (start) ? UNLOAD_4 : UNLOAD_5;
        end
        UNLOAD_4: begin
            state_next = (start) ? UNLOAD_3 : UNLOAD_4;
        end
        UNLOAD_3: begin
            state_next = (start) ? UNLOAD_2 : UNLOAD_3;
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
        result <= result;
    
        case(state)
        LOAD_0_1: begin
            if (start) begin 
                result <= 8'd0;
                in[7:0] <= sbox_a;
                in[15:8] <= sbox_b;
            end
        end
        LOAD_2_3: begin
            result <= 8'd0;
            if (start) begin 
                in[23:16] <= sbox_a;
                in[31:24] <= sbox_b;
            end
        end
        LOAD_4_5: begin
            result <= 8'd0;
            if (start) begin 
                in[39:32] <= sbox_a;
                in[47:40] <= sbox_b;
            end
        end
        LOAD_6_7: begin
            result <= 8'd0;
            if (start) begin 
                in[55:48] <= sbox_a;
                in[63:56] <= sbox_b;
            end
        end
        LOAD_8_9: begin
            result <= 8'd0;
            if (start) begin 
                in[71:64] <= sbox_a;
                in[79:72] <= sbox_b;
            end
        end
        LOAD_10_11: begin
            result <= 8'd0;
            if (start) begin 
                in[87:80] <= sbox_a;
                in[95:88] <= sbox_b;
            end
        end
        LOAD_12_13: begin
            result <= 8'd0;
            if (start) begin 
                in[103:96] <= sbox_a;
                in[111:104] <= sbox_b;
            end
        end
        LOAD_14_15_UNLOAD_15: begin
            if (start) begin 
                in[119:112] <= sbox_a;
                in[127:120] <= sbox_b;
                wait_req_reg <= 1'b1;
            end else if (wait_req_reg == 1'b1) begin
                result <= perm_out[127:120];
                wait_req_reg <= 1'b0;
            end
        end
        UNLOAD_14: begin
            result <= perm_out[119:112];
        end
        UNLOAD_13: begin
            result <= perm_out[111:104];
        end
        UNLOAD_12: begin
            result <= perm_out[103:96];
        end
        UNLOAD_11: begin
            result <= perm_out[95:88];
        end
        UNLOAD_10: begin
            result <= perm_out[87:80];
        end
        UNLOAD_9: begin
            result <= perm_out[79:72];
        end
        UNLOAD_8: begin
            result <= perm_out[71:64];
        end
        UNLOAD_7: begin
            result <= perm_out[63:56];
        end
        UNLOAD_6: begin
            result <= perm_out[55:48];
        end
        UNLOAD_5: begin
            result <= perm_out[47:40];
        end
        UNLOAD_4: begin
            result <= perm_out[39:32];
        end
        UNLOAD_3: begin
            result <= perm_out[31:24];
        end
        UNLOAD_2: begin
            result <= perm_out[23:16];
        end
        UNLOAD_1: begin
            result <= perm_out[15:8];
        end
        UNLOAD_0: begin
            result <= perm_out[7:0];
        end
        endcase
    end
    
endmodule
