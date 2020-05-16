`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  SAL, Virginia Tech
// Engineer: Minh Vu
// 
// Create Date:     03/31/2020
// Design Name:     UART
// Module Name:     uart_tx
// Project Name:    HOKSTER
// Target Devices:  Artix-7 (xc7a100tftg256-3)
// Tool Versions: 
// Description:     TX Module for UART
// 
// Dependencies:    dff.v, counter.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx(
    input clk,
    input rst,
    input [15:0] addr,
    input [7:0]  txdata_in,
    input ack,
    output irq,
    output txout,
    // Debugging:
    output baudpulse,
    output reg  [1:0] state,
    output wire [7:0] txdata_out,
    output wire [7:0] txsr_out,
    output wire [3:0] txctr_out
    );
    
    // Regs and wires
//    reg   [1:0] state;
    
//    wire  [7:0] txdata_out;
    wire        en_txdata;
    wire  [7:0] txsr_in;//, txsr_out;
    wire        en_txsr;
    wire  [3:0] txctr_in;//, txctr_out;
    wire        init_txctr, en_txctr;
    wire        en_baud;//, baudbpulse;
    
    // Possible states
    localparam IDLE = 2'b00, RDY = 2'b01, SEND = 2'b10, DONE = 2'b11;
    
    // Memory-mapped addresses
    localparam START_SEND = 16'h0110, LOAD_DATA = 16'h0111;
    
    // Constants
    localparam TX_COUNT_MAX = 4'ha;
    
    // Module instances
    // TX data register
    d_ff #(8) txdata(
        .clk(clk),
        .rst(rst),
        .en(en_txdata),
        .d(txdata_in),
        .q(txdata_out)
    );
    
    // Shift register
    d_ff #(8) txsr(
        .clk(clk),
        .rst(rst),
        .en(en_txsr),
        .d(txsr_in),
        .q(txsr_out)
    );
    
    // Counter register
    d_ff #(4) txctr(
        .clk(clk),
        .rst(rst),
        .en(en_txctr),
        .d(txctr_in),
        .q(txctr_out)
    );

    // Counter/Pulse generator to transmit at desired baud rate
    counter txbaudctr(
        .clk(clk),
        .rst(rst),
        .en(en_baud),
        .out(baudpulse)
    );
    
    // State machine
    always@(posedge clk) begin
        if(rst) state <= IDLE;
        else begin
            case(state)
                IDLE: begin
                    if(addr == LOAD_DATA) state <= RDY;
                end
                
                RDY: begin
                    if(addr == START_SEND) state <= SEND;
                end
                
                SEND: begin
                    if(txctr_out >= TX_COUNT_MAX) state <= DONE;
                end
                
                DONE: begin
                    if(ack) state <= IDLE;
                end
                
                default: state <= 2'bx;
            endcase
        end
    end
    
    // Assignments
    assign en_txdata = (state == IDLE || state == RDY) && addr == LOAD_DATA;
    assign txsr_in = (state == RDY) ? txdata_out :
                     (txctr_out == 0 && state == SEND) ? txsr_out :
                     {1'b0, txsr_out[7:1]}; // Shifted right
    assign en_txsr = state == RDY || baudpulse;
    assign init_txctr = txctr_out >= TX_COUNT_MAX;
    assign txctr_in = (init_txctr) ? 4'b0000 : txctr_out + 4'b0001;
    assign en_txctr = init_txctr || baudpulse;
    assign en_baud = state == SEND && txctr_out < TX_COUNT_MAX;
    assign txout =  (txctr_out == 0 && state == SEND) ? 1'b0 : // Start bit
                    (txctr_out == TX_COUNT_MAX - 4'h1 && state == SEND) ? 1'b1 : // Stop bit
                    (txctr_out >= 1 && txctr_out <= TX_COUNT_MAX - 4'h2 && state == SEND) ? txsr_out[0] : // LSb of shift register
                    1'b1; // Idle line
    assign irq = state == DONE;
    
endmodule
