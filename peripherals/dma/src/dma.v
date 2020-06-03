`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  SAL, Virginia Tech
// Engineer: Minh Vu
// 
// Create Date:     01/30/2020
// Design Name:     DMA (Direct Memory Access)
// Module Name:     dma
// Project Name:    HOKSTER
// Target Devices:  Digilent Nexys A7-100T
// Tool Versions: 
// Description:     Top-level module for DMA
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dma(
    input clk,
    input rst,
    input [15:0] auxdaddr,
    input [7:0] auxdin,
    input [7:0] extdout,
    input ack,
    output irq,
    output auxdoutsel,
    //output extdataload, // Not worrying about this signal for now
    output [7:0] extdin,
    output [15:0] extdaddr,
    output extwe,
    output active
    // For debugging:
    //output reg [2:0] state,
    //output reg [15:0] counter,
    //output reg [15:0] numbytes
    );
    
    // Registers
    reg[15:0] srccounter;
    reg[15:0] dstcounter;
    reg[15:0]  numbytes;
    reg[15:0]  counter;
    reg[2:0]  state;
    reg[7:0]  datatotransfer;
    reg       endflag;
    
    // Possible states
    localparam IDLE = 3'b000, READ = 3'b001, SAVE = 3'b010, WRITE = 3'b011, DONE = 3'b100;
    
    // Memory-mapped addresses
    localparam START = 16'h0100;
    localparam SRC_START_L = 16'h0101, SRC_START_M = 16'h0102;
    localparam DST_START_L = 16'h0103, DST_START_M = 16'h0104;
    localparam NUM_TRANSFER = 16'h0105;//, G_VAL = 16'h0106;
    parameter G = 3'b010; // Default value of G is 2
    
    // State machine
    always@(posedge clk) begin
        if(rst) begin
            // Reset
            state <= IDLE;
            srccounter <= 0;
            dstcounter <= 0;
            numbytes <= 0;
            counter <= 0;
            datatotransfer <= 0;
            endflag <= 0;
        end else begin
            case(state)
            
                IDLE:   begin
                    // Set parameters or start transfer
                    case(auxdaddr)
                        SRC_START_L:    srccounter[7:0]  <= auxdin;
                        SRC_START_M:    srccounter[15:8] <= auxdin;
                        DST_START_L:    dstcounter[7:0]  <= auxdin;
                        DST_START_M:    dstcounter[15:8] <= auxdin;
                        NUM_TRANSFER:   numbytes <= (auxdin + 1) << G;
                        START:          if(auxdin == 8'hff) state <= READ;
                    endcase
                end
                
                READ:   begin
                    // Read from source address to store
                    state <= SAVE;
                    datatotransfer <= extdout;
                end
                
                SAVE:   begin
                    // Ensure data read from source address is stored in datatotransfer
                    // Increment srccounter except when about counter is about to equal numbytes,
                    //  in which case set endflag
                    state <= WRITE;
                    if(counter >= numbytes - 1) endflag <= 1;
                    else srccounter <= srccounter + 1;
               end
                
                WRITE:  begin
                    // Write to destination address
                    // Increment dstcounter except when about endflag is set
                    counter <= counter + 1;
                    if(endflag) begin
                        state <= DONE;
                    end else begin
                        dstcounter <= dstcounter + 1;
                        state <= READ;
                    end
                end
                
                DONE:   begin
                    // Wait for processor ack
                    endflag <= 0;
                    if(ack) begin
                        state <= IDLE;
                        counter <= 0;
                    end
                end
                
                default: state <= 4'bx;
                
            endcase
        end // if-else
    end // state machine
    
    // Output
    assign extdaddr = (state == WRITE) ? dstcounter : srccounter;
    assign extdin = datatotransfer;
    assign extwe = (state == WRITE);
    assign irq = (state == DONE);
    assign auxdoutsel = 1'b0; // Also not worrying about this signal for now
    assign active = (state == READ) || (state == SAVE) || (state == WRITE);
        
endmodule
