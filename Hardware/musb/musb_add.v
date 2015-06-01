//==================================================================================================
//  Filename      : musb_add.v
//  Created On    : 2014-09-24 20:06:42
//  Last Modified : 2015-05-24 21:00:33
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : A simple 32 bits adder
//==================================================================================================

module musb_add(
    input  [31:0] add_port_a,
    input  [31:0] add_port_b,
    output [31:0] add_result
    );

    assign add_result = (add_port_a + add_port_b); // 32-bits adder
endmodule
