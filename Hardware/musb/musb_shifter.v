//==================================================================================================
//  Filename      : musb_shifter.v
//  Created On    : 2014-10-11 19:22:43
//  Last Modified : 2015-05-24 20:59:31
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Arithmetic/Logic shifter
//                  WARNING: shamnt range is 0 -> 31
//==================================================================================================

`include "musb_defines.v"

module musb_shifter(
    input   [31:0]  input_data,     // input data
    input   [4:0]   shamnt,         // shift amount
    input           direction,      // 0: right, 1: left
    input           sign_extend,    // signed operation
    output  [31:0]  shift_result    // result
    );

    ///-------------------------------------------------------------------------
    // Signal Declaration: reg
    //--------------------------------------------------------------------------
    reg [31:0]  input_inv;          // invert input for shift left
    reg [31:0]  result_shift_temp;       // shift result
    reg [31:0]  result_inv;         // invert output for shift left

    ///-------------------------------------------------------------------------
    // Signal Declaration: wire
    //--------------------------------------------------------------------------
    wire        sign;
    wire [31:0] operand;

    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign sign         = (sign_extend) ? input_data[31] : 1'b0;           // set if SRA
    assign operand      = (direction) ? input_inv : input_data;            // set if SLL
    assign shift_result = (direction) ? result_inv : result_shift_temp;    // set if SLL

    //--------------------------------------------------------------------------
    // invert data if operation is SLL
    //--------------------------------------------------------------------------
    integer index0;
    integer index1;
    // first inversion: input
    always @(*) begin
        for (index0 = 0; index0 < 32; index0 = index0 + 1)
            input_inv[31-index0] <= input_data[index0];
    end
    // second inversion : output
    always @(*) begin
        for (index1 = 0; index1 < 32; index1 = index1 + 1)
            result_inv[31-index1] <= result_shift_temp[index1];
    end

    //--------------------------------------------------------------------------
    // the BIG multiplexer
    // Perform SRA. Sign depends if operation is SRA or SRL (sign_extend)
    //--------------------------------------------------------------------------
    always @(*) begin
        case(shamnt)
            5'd0    : result_shift_temp <=               operand[31:0];
            5'd1    : result_shift_temp <= { {1 {sign}}, operand[31:1] };
            5'd2    : result_shift_temp <= { {2 {sign}}, operand[31:2] };
            5'd3    : result_shift_temp <= { {3 {sign}}, operand[31:3] };
            5'd4    : result_shift_temp <= { {4 {sign}}, operand[31:4] };
            5'd5    : result_shift_temp <= { {5 {sign}}, operand[31:5] };
            5'd6    : result_shift_temp <= { {6 {sign}}, operand[31:6] };
            5'd7    : result_shift_temp <= { {7 {sign}}, operand[31:7] };
            5'd8    : result_shift_temp <= { {8 {sign}}, operand[31:8] };
            5'd9    : result_shift_temp <= { {9 {sign}}, operand[31:9] };
            5'd10   : result_shift_temp <= { {10{sign}}, operand[31:10] };
            5'd11   : result_shift_temp <= { {11{sign}}, operand[31:11] };
            5'd12   : result_shift_temp <= { {12{sign}}, operand[31:12] };
            5'd13   : result_shift_temp <= { {13{sign}}, operand[31:13] };
            5'd14   : result_shift_temp <= { {14{sign}}, operand[31:14] };
            5'd15   : result_shift_temp <= { {15{sign}}, operand[31:15] };
            5'd16   : result_shift_temp <= { {16{sign}}, operand[31:16] };
            5'd17   : result_shift_temp <= { {17{sign}}, operand[31:17] };
            5'd18   : result_shift_temp <= { {18{sign}}, operand[31:18] };
            5'd19   : result_shift_temp <= { {19{sign}}, operand[31:19] };
            5'd20   : result_shift_temp <= { {20{sign}}, operand[31:20] };
            5'd21   : result_shift_temp <= { {21{sign}}, operand[31:21] };
            5'd22   : result_shift_temp <= { {22{sign}}, operand[31:22] };
            5'd23   : result_shift_temp <= { {23{sign}}, operand[31:23] };
            5'd24   : result_shift_temp <= { {24{sign}}, operand[31:24] };
            5'd25   : result_shift_temp <= { {25{sign}}, operand[31:25] };
            5'd26   : result_shift_temp <= { {26{sign}}, operand[31:26] };
            5'd27   : result_shift_temp <= { {27{sign}}, operand[31:27] };
            5'd28   : result_shift_temp <= { {28{sign}}, operand[31:28] };
            5'd29   : result_shift_temp <= { {29{sign}}, operand[31:29] };
            5'd30   : result_shift_temp <= { {30{sign}}, operand[31:30] };
            5'd31   : result_shift_temp <= { {31{sign}}, operand[31:31] };
            default : result_shift_temp <= 32'bx;                          // I don't BLOODY CARE.
        endcase
    end
endmodule
