//==================================================================================================
//  Filename      : musb_mux_2_1.v
//  Created On    : 2014-09-24 20:36:33
//  Last Modified : 2015-05-24 20:59:53
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : A 2-input Mux, with parameterizable width
//==================================================================================================

module musb_mux_2_1 #(
    parameter DATA = 32
    )
    (
    input                   select,
    input       [DATA-1:0]  in0,
    input       [DATA-1:0]  in1,
    output  reg [DATA-1:0]  out
    );

    always @(*) begin
        case (select)
            1'b0 : out <= in0;
            1'b1 : out <= in1;
        endcase
    end
endmodule
