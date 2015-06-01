//==================================================================================================
//  Filename      : ram.v
//  Created On    : 2015-01-07 21:29:23
//  Last Modified : 2015-05-24 23:32:18
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : A configurable memory.
//                  Synchronous read, synchronous write.
//                  Based on the SRAM module from XUM project
//                  Author: Grant Ayers (ayers@cs.utah.edu)
//==================================================================================================

module ram#(
    parameter DATA_WIDTH = 8,                   // 8-bits data (default)
    parameter ADDR_WIDTH = 8                    // 8-bits address (default)
    )(
    input                       clk,
    input                       we,
    input   [(ADDR_WIDTH-1):0]  read_address,
    input   [(ADDR_WIDTH-1):0]  write_address,
    input   [(DATA_WIDTH-1):0]  data_i,
    output  [(DATA_WIDTH-1):0]  data_o
    );

    localparam RAM_DEPTH = 1 << ADDR_WIDTH;       // 256 entries (default)

    //--------------------------------------------------------------------------
    // registers
    //--------------------------------------------------------------------------
    reg [(DATA_WIDTH-1):0] mem [0:(RAM_DEPTH-1)];
    reg [(DATA_WIDTH-1):0] data_o_reg;

    //--------------------------------------------------------------------------
    // read
    //--------------------------------------------------------------------------
    assign data_o = data_o_reg;

    //--------------------------------------------------------------------------
    // write
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        data_o_reg <= mem[read_address];
        if (we)
            mem[write_address] <= data_i;
    end

endmodule
