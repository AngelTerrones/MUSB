//==================================================================================================
//  Filename      : clk_generator.v
//  Created On    : 2015-02-07 21:17:35
//  Last Modified : 2015-05-24 22:49:47
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Generate the two main clocks:
//                  - Bus and peripherals.
//                  - Core. This clock is equal to Bus clock divided by 2.
//==================================================================================================

module clk_generator(
    input       clk_i,      // input clock
    output  reg clk_core,   // core clock
    output      clk_bus     // bus clock
    );

    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign clk_bus = clk_i;

    //--------------------------------------------------------------------------
    // Initialization
    //--------------------------------------------------------------------------
    initial begin
        clk_core <= 1'b0;
    end

    //--------------------------------------------------------------------------
    // divide the clock
    //--------------------------------------------------------------------------
    always @(posedge clk_i ) begin
        clk_core <= !clk_core;
    end
endmodule
