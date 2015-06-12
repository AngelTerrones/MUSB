//==================================================================================================
//  Filename      : memory_bram_dp.v
//  Created On    : 2014-09-24 20:12:03
//  Last Modified : 2015-06-12 13:28:04
//  Revision      :
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Block RAM used for the Internal Memory
//                  WARNING: registered input address. Latency: 1 cycle.
//==================================================================================================

module memory_bram_dp #(
    parameter data_size = 8,                // Default: 8 bits
    parameter addr_size = 8                 // Default: 256 lines
    )(
    // Port A
    input                       a_clk,      // Port A clock
    input                       a_wr,       // 1 = write. 0 = Read
    input       [addr_size-1:0] a_addr,     // Address
    input       [data_size-1:0] a_din,      // Input data
    output  reg [data_size-1:0] a_dout,     // Output data
    // Port B
    input                       b_clk,      // Port A clock
    input                       b_wr,       // 1 = write. 0 = Read
    input       [addr_size-1:0] b_addr,     // Address
    input       [data_size-1:0] b_din,      // Input data
    output  reg [data_size-1:0] b_dout      // Output data
    );

    //--------------------------------------------------------------------------
    // Memory
    //--------------------------------------------------------------------------
    reg [data_size-1:0] mem [0:(2**addr_size)-1];

    //--------------------------------------------------------------------------
    // Initialize to zero
    //--------------------------------------------------------------------------
    integer i;
    initial begin
        for (i = 0; i < 2**addr_size; i = i + 1) begin
            mem[i] = 0;
        end
    end

    //--------------------------------------------------------------------------
    // Port A
    //--------------------------------------------------------------------------
    always @(posedge a_clk) begin
        a_dout <= mem[a_addr];
        if(a_wr) begin
            a_dout      <= a_din;
            mem[a_addr] <= a_din;
        end
    end

    //--------------------------------------------------------------------------
    // Port B
    //--------------------------------------------------------------------------
    always @(posedge b_clk) begin
        b_dout <= mem[b_addr];
        if(b_wr) begin
            b_dout      <= b_din;
            mem[b_addr] <= b_din;
        end
    end
endmodule
