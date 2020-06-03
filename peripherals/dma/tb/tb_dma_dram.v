`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  SAL, Virginia Tech
// Engineer: Minh Vu
// 
// Create Date:     02/10/2020
// Design Name:     DMA (Direct Memory Access)
// Module Name:     tb_dma_dram
// Project Name:    HOKSTER
// Target Devices:  Digilent Nexys A7-100T
// Tool Versions: 
// Description:     Test bench for DMA module (testing with DRAM)
// 
// Dependencies:    dma.v, dram.vhd
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_dma_dram();

    // Inputs:
    reg        clk_en, clock;
    reg        reset;
    
    // Mock core signals
    reg        sbus;        // To acknowledge interrupt signal
    reg [15:0] abus;        // Address bus (goes to DMA auxaddr)
    reg  [7:0] dbus;        // Data bus (goes to DMA auxdin)
    
    // Helper signals to pre-load DRAM
    reg [15:0] addrload;    // Address      
    reg  [7:0] dataload;    // Data
    reg        weload;      // Write-enable
    reg        enload;      // Enables pre-loading of DRAM
    reg [15:0] count;       // Loop counter
    
    // Wires:
    wire  [7:0] dramout;        // DRAM data output
    wire        ibus;           // For interrupt
    wire        auxdoutsel;     // Not worrying about this signal now
    wire  [7:0] transferdata;   // DRAM input, DMA output (data)
    wire [15:0] transferaddr;   // DRAM input, DMA output (address)
    wire        we;             // Write-enable signal from DMA
    
    // DRAM direct inputs
    wire  [7:0] dramin;        // DRAM data input
    wire [15:0] dramaddr;       // DRAM address
    wire        dramwe;         // DRAM write-enable
    
    // Debugging:
    wire  [2:0] state;
    wire  [15:0] counter;
    wire  [15:0] numbytes;
    
    // DRAM instance
    DRAM dram(
        .clk(clock),
		.we(dramwe),
		.di(dramin),
		.do(dramout),
		.addr(dramaddr)
    );
    
    // DMA DUT
    dma #(2) dut(
        .clk(clock),
        .rst(reset),
        .auxdaddr(abus),
        .auxdin(dbus),
        .extdout(dramout),
        .ack(sbus),
        .irq(ibus),
        .auxdoutsel(auxdoutsel),
        .extdin(transferdata),
        .extdaddr(transferaddr),
        .extwe(we),
        .state(state),
        .counter(counter),
        .numbytes(numbytes)
    );
    
    // Muxes to help load DRAM
    mux2to1 #(8)  data_mux(
        .in0(transferdata),
        .in1(dataload),
        .select(enload),
        .out(dramin)
    );
    
    mux2to1 #(16) addr_mux(
        .in0(transferaddr),
        .in1(addrload),
        .select(enload),
        .out(dramaddr)
    );
    
    mux2to1       we_mux(
        .in0(we),
        .in1(weload),
        .select(enload),
        .out(dramwe)
    );
    
    // Timing blocks
    // Set up clock
    initial begin
        clock = 1'b1;
        clk_en = 1'b1;
    end
    
    initial begin
        clock = 1'b1;
        while(clk_en) begin
            #5;
            clock = ~clock;
        end
    end
    
    // Test
    initial begin
        // Initialize inputs
        reset = 4'b0;
        abus = 16'h0000;
        dbus  = 8'h00;
        sbus = 1'b0;
        
        dataload = 8'h00;
        addrload = 16'h00;
        weload = 1'b0;
        enload = 1'b0;
        count = 16'h00;
        
        // Reset DMA
        #10;
        reset = 4'b1;
        #10;
        reset = 4'b0;
        #10;
        
        // Initial load of DRAM
        weload = 1'b1;
        enload = 1'b1;
        
        for(count = 16'h00; count < 16'h10; count = count + 16'h01) begin
            dataload = 8'h10 - count[7:0];
            addrload = 16'h0020 + count[15:0];
            #20;
        end
        weload = 1'b0;
        dataload = 8'h00;
        
        // Read DRAM to confirm data was loaded
        // Comment out if not needed
//        for(count = 16'h00; count < 16'h10; count = count + 16'h01) begin
//            addrload = 16'h0020 + count[15:0];
//            #10;
//        end
        
        addrload = 16'h0000;
        enload = 1'b0;
        
        // Load parameters in DMA
        #10;
        
        #10;
        // Source address
        abus = 16'h0101;
        dbus  = 8'h20;
        #20;
        abus = 16'h0102;
        dbus  = 8'h00;
        #20;
        // Destination address
        abus = 16'h0103;
        dbus  = 8'h30;
        #20;
        abus = 16'h0104;
        dbus  = 8'h00;
        #20;
        // Number of bytes to transfer
        // User sets n, in which (n+1) << 2 is number of bytes
        abus = 16'h0105;
        dbus  = 8'h03;
        #20;
        // Start
        abus = 16'h0100;
        dbus  = 8'hff;
        #20;
        abus = 16'h0000;
        dbus  = 8'h00;
        
        // Do transfer
        #490;
        
        // Acknowledge irq after transfer is done
        sbus = 1'b1;
        #10;
        sbus = 1'b0;
        #20;
        
        // Read DRAM addresses just written to
        enload = 1'b1;
        for(count = 16'h00; count < 16'h10; count = count + 16'h01) begin
            addrload = 16'h0030 + count[15:0];
            #10;
        end
        addrload = 16'h0000;
        enload = 1'b0;
        #10;
        
        // Disable clock
        clk_en = 1'b0;
        $finish;
     end
         
endmodule
