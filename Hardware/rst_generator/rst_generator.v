//==================================================================================================
//  Filename      : rst_generator.v
//  Created On    : 2015-01-07 21:29:23
//  Last Modified : 2015-06-09 21:13:35
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Debounce and synchronize the reset input signal.
//                  The module use a 7-bit counter.
//==================================================================================================

module rst_generator(
    input       clk,            // input clock
    input       rst_i,          // external reset
    output  reg rst_o           // internal reset
    );

    //--------------------------------------------------------------------------
    // registers
    //--------------------------------------------------------------------------
    reg [11:0] counter_r;
    reg       rst_i_sync_0;
    reg       rst_i_sync_1;

  //--------------------------------------------------------------------------
    // Initialization
    //--------------------------------------------------------------------------
    initial begin
        rst_o        <= 1'b1;
        counter_r    <= 12'hFFF;
        rst_i_sync_0 <= 1'b1;
        rst_i_sync_1 <= 1'b1;
    end

    //--------------------------------------------------------------------------
    // state machine
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        // sync the input
        rst_i_sync_0 <= rst_i;
        rst_i_sync_1 <= rst_i_sync_0;

        // Wait until stable input.
        if (rst_o != rst_i_sync_1) begin
            counter_r <= counter_r - 1'b1;
        end
        else begin
            counter_r <= 12'hFFF;
        end

        // Timeout: input signal is stable. Change output.
        if (counter_r == 12'h0) begin
            rst_o <= ~rst_o;
        end
        else begin
            rst_o <= rst_o;
        end
    end
endmodule
