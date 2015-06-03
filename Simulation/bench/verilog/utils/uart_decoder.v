//==================================================================================================
//  Filename      : uart_decoder.v
//  Created On    : 2015-05-27 10:23:26
//  Last Modified : 2015-06-02 16:13:51
//  Revision      : 1.0
//  Author        : Ángel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : angelterrones@gmail.com
//
//  Description   : Testbench UART output decoder
//==================================================================================================

`timescale 1ns/100ps

module uart_decoder #(
    parameter BAUD_RATE = 115200
    )(
    input             clk,
    input             uart_rx,
    output  reg [7:0] rx_data,
    output  reg       uart_rx_idle
    );

    //----------------------------------------------------------------------------
    // localparams
    //----------------------------------------------------------------------------
    localparam UART_PERIOD = 1000000000/BAUD_RATE;   // nS

    // each clock, trigger the task
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        task_uart_rx;
    end

    //----------------------------------------------------------------------------
    // task
    //----------------------------------------------------------------------------
    task task_uart_rx;
        reg [7:0] rx_buffer;    // input buffer
        integer rx_cnt;         // counter
        // task
        begin
            #(1);                   // delay FTW
            uart_rx_idle = 1'b1;
            @(negedge uart_rx);     // wait start bit
            rx_buffer = 0;          //
            #(3*UART_PERIOD/2);     // ignore start bit
            // get frame
            for (rx_cnt = 0; rx_cnt < 8; rx_cnt = rx_cnt + 1) begin
                rx_buffer = {uart_rx, rx_buffer[7:1]};      // shifter
                #(UART_PERIOD);                     // wait for next bit
            end
            rx_data = rx_buffer;                // return data
            uart_rx_idle = 1'b0;
        end
    endtask
endmodule
