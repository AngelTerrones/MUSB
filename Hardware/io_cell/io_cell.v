//==================================================================================================
//  Filename      : io_cell.v
//  Created On    : 2015-06-07 21:51:13
//  Last Modified : 2015-06-07 22:39:02
//  Revision      : 1.0
//  Author        : Ángel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Tri-state buffer
//
//
//==================================================================================================

module io_cell #(
    parameter WIDTH = 1
    )(
    inout   [WIDTH - 1:0] io_pad,   // I/O pin
    input   [WIDTH - 1:0] data_o,   // Data from pin
    input   [WIDTH - 1:0] oe,       // Output enable
    output  [WIDTH - 1:0] data_i    // Data to pin
    );

    //--------------------------------------------------------------------------
    // Asignments
    //--------------------------------------------------------------------------
    assign data_i = io_pad;
    assign io_pad = (oe) ? data_o : {WIDTH{1'bz}};
endmodule
