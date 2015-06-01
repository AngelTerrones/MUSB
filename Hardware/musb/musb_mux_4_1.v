//==================================================================================================
//  Filename      : musb_mux_4_1.v
//  Created On    : 2014-09-24 20:36:53
//  Last Modified : 2015-05-24 20:59:48
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : A 4-input Mux, with parameterizable width
//==================================================================================================

module musb_mux_4_1#(
    parameter DATA = 32
    )
    (
    input       [1:0]       select,
    input       [DATA-1:0]  in0,
    input       [DATA-1:0]  in1,
    input       [DATA-1:0]  in2,
    input       [DATA-1:0]  in3,
    output  reg [DATA-1:0]  out
    );

    always @(*) begin
        case (select)
            2'b00 : out <= in0;
            2'b01 : out <= in1;
            2'b10 : out <= in2;
            2'b11 : out <= in3;
        endcase
    end
endmodule
