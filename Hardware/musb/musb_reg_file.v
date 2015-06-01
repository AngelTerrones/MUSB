//==================================================================================================
//  Filename      : musb_reg_file.v
//  Created On    : 2014-09-23 20:37:30
//  Last Modified : 2015-05-24 20:59:39
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : 32 General Purpose Registers (GPR)
//                  WARNING: This reg file DO NOT HAVE A RESET, so the synthesis tool can
//                  create the component with BRAM
//==================================================================================================

`include "musb_defines.v"

module musb_reg_file(
    input           clk,        // clock
    input   [4:0]   gpr_ra_a,   // Address port A
    input   [4:0]   gpr_ra_b,   // Address port B
    input   [4:0]   gpr_wa,     // Write address
    input   [31:0]  gpr_wd,     // Data to write
    input           gpr_we,     // Write enable
    output [31:0]   gpr_rd_a,   // Data port A
    output [31:0]   gpr_rd_b    // Data port B
    );

    //--------------------------------------------------------------------------
    // Signal Declaration: reg
    //--------------------------------------------------------------------------
    reg [31:0] registers [1:31];                                                // Register file of 32 32-bit registers. Register 0 is hardwired to 32'b0

    //--------------------------------------------------------------------------
    // Sequential (clocked) write.
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (gpr_wa != 0)
            registers[gpr_wa] <= (gpr_we) ? gpr_wd : registers[gpr_wa];
    end

    //--------------------------------------------------------------------------
    // Combinatorial Read. Register 0 is read as 0 always
    //--------------------------------------------------------------------------
    assign gpr_rd_a = (gpr_ra_a == 5'b0) ? 32'h0000_0000 : registers[gpr_ra_a];
    assign gpr_rd_b = (gpr_ra_b == 5'b0) ? 32'h0000_0000 : registers[gpr_ra_b];
endmodule
