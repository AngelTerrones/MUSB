//==================================================================================================
//  Filename      : musb_div.v
//  Created On    : 2014-10-27 21:59:02
//  Last Modified : 2015-05-24 21:00:17
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : The multi-cycle Divider unit.
//                  op_div and op_divu MUST BE dis-asserted after the setup
//                  cycle for normal operation, or the operation will be
//                  restarted
//                  WARNING: no exception if divisor == 0.
//==================================================================================================

module musb_div(
    input           clk,            // clock
    input           rst,            // reset
    input           op_divs,        // 1 for signed operation
    input           op_divu,        // 1 for unsigned operation
    input   [31:0]  dividend,       // Operand
    input   [31:0]  divisor,        // Operand
    output  [31:0]  quotient,       // Result
    output  [31:0]  remainder,      // Result
    output          stall           // 1 while calculating
    );

    //--------------------------------------------------------------------------
    // Signal Declaration: reg
    //--------------------------------------------------------------------------
    reg             active;             // 1 while running
    reg             neg_result;         // 1 if the result will be negative
    reg     [4:0]   cycle;              // number of cycles needed.
    reg     [31:0]  result;             // Store the result.
    reg     [31:0]  denominator;        // divisor
    reg     [31:0]  residual;           // current remainder

    //--------------------------------------------------------------------------
    // Signal Declaration: wire
    //--------------------------------------------------------------------------
    wire    [32:0]  partial_sub;        // temp

    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign quotient    = !neg_result ? result : -result;
    assign remainder   = residual;
    assign stall       = active;
    assign partial_sub = {residual[30:0], result[31]} - denominator;            // calculate partial result

    //--------------------------------------------------------------------------
    // State Machine. This needs 32 cycles to calculate the result.
    // The result is loaded after 34 cycles
    // The first cycle is setup.
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            active      <= 1'b0;
            neg_result  <= 1'b0;
            cycle       <= 5'b0;
            result      <= 32'b0;
            denominator <= 32'b0;
            residual    <= 32'b0;
        end
        else begin
            if(op_divs) begin
                // Signed division.
                cycle       <= 5'd31;
                result      <= (dividend[31] == 1'b0) ? dividend : -dividend;
                denominator <= (divisor[31] == 1'b0) ? divisor : -divisor;
                residual    <= 32'b0;
                neg_result  <= dividend[31] ^ divisor[31];
                active      <= 1'b1;
            end
            else if (op_divu) begin
                // Unsigned division.
                cycle       <= 5'd31;
                result      <= dividend;
                denominator <= divisor;
                residual    <= 32'b0;
                neg_result  <= 1'b0;
                active      <= 1'b1;
            end
            else if (active) begin
                // run a iteration
                if(partial_sub[32] == 1'b0) begin
                    residual <= partial_sub[31:0];
                    result   <= {result[30:0], 1'b1};
                end
                else begin
                    residual <= {residual[30:0], result[31]};
                    result   <= {result[30:0], 1'b0};
                end

                if (cycle == 5'b0) begin
                    active <= 1'b0;
                end

                cycle <= cycle - 5'd1;
            end
        end
    end
endmodule
