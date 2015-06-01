//==================================================================================================
//  Filename      : uart_min.v
//  Created On    : 2015-01-10 15:58:09
//  Last Modified : 2015-05-24 21:21:39
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : UART module. Configuration: 115200, 8N1. No flow control
//                  Minimal version (no slave port)
//                  Based on the Rx module from XUM project.
//                  Author: Grant Ayers (ayers@cs.utah.edu)
//==================================================================================================

module uart_min #(
    parameter FIFO_ADDR_WIDTH = 8,                      // 2^ADDR_WIDTH words of FIFO space
    parameter BUS_FREQ        = 100.0                   // Bus frequency
    )(
    input                       clk,
    input                       rst,
    input                       write,                  // Write data to fifo (Tx)
    input   [7:0]               data_i,                 // Input data
    input                       read,                   // Read data from fifo (Rx)
    output  [7:0]               data_o,                 // Output data
    output                      data_ready,             // Data available to read
    output  [FIFO_ADDR_WIDTH:0] rx_count,               // Number of bytes inside the Rx fifo
    output  [FIFO_ADDR_WIDTH:0] tx_count,               // Number of bytes inside the Tx fifo
    output                      tx_free,                // indicate tx ready
    // Interrupt: Data available in Rx fifo, or fifo full
    output                      uart_rx_ready_int,      //
    output                      uart_rx_full_int,       //
    // Off chip I/O
    input                       uart_rx,                // Rx pin
    output                      uart_tx                 // Tx pin
    );

    //--------------------------------------------------------------------------
    // Rx/Tx "clocks"
    //--------------------------------------------------------------------------
    wire uart_tick;
    wire uart_tick_16x;

    //--------------------------------------------------------------------------
    // Rx signals
    //--------------------------------------------------------------------------
    wire [7:0]  rx_data;            // Raw bytes coming in from uart
    wire        rx_data_ready;      // Synchronous pulse indicating data from Rx
    wire        rx_fifo_empty;

    //--------------------------------------------------------------------------
    // Tx signals
    //--------------------------------------------------------------------------
    reg         tx_fifo_deQ = 0;
    reg         tx_start    = 0;
    wire        tx_fifo_empty;
    wire [7:0]  tx_fifo_data_out;

    //--------------------------------------------------------------------------
    // Handle Tx FIFO
    //--------------------------------------------------------------------------
    assign uart_rx_ready_int = ~rx_fifo_empty;
    assign data_ready        = ~rx_fifo_empty;

    always @(posedge clk) begin
        if (rst) begin
            tx_fifo_deQ <= 0;
            tx_start    <= 0;
        end
        else begin
            if (~tx_fifo_empty & tx_free & uart_tick) begin
                tx_fifo_deQ <= 1;
                tx_start    <= 1;
            end
            else begin
                tx_fifo_deQ <= 0;
                tx_start    <= 0;
            end
        end
    end

    //--------------------------------------------------------------------------
    // Instantiate modules
    //--------------------------------------------------------------------------
    uart_clock #(
        .BUS_FREQ (BUS_FREQ))
    clks (
        .clk           ( clk           ),
        .uart_tick     ( uart_tick     ),
        .uart_tick_16x ( uart_tick_16x )
    );

    uart_tx tx (
        .clk       ( clk              ),
        .rst       ( rst              ),
        .uart_tick ( uart_tick        ),
        .TxD_data  ( tx_fifo_data_out ),
        .TxD_start ( tx_start         ),
        .ready     ( tx_free          ),
        .TxD       ( uart_tx          )
    );

    uart_rx rx (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .RxD           ( uart_rx       ),
        .uart_tick_16x ( uart_tick_16x ),
        .RxD_data      ( rx_data       ),
        .ready         ( rx_data_ready )
    );

    fifo #(
        .DATA_WIDTH (8),
        .ADDR_WIDTH (FIFO_ADDR_WIDTH))
    tx_buffer (
        .clk     ( clk              ),
        .rst     ( rst              ),
        .enqueue ( write            ),
        .dequeue ( tx_fifo_deQ      ),
        .data_i  ( data_i           ),
        .data_o  ( tx_fifo_data_out ),
        .count   ( tx_count         ),
        .empty   ( tx_fifo_empty    ),
        .full    (                  )
    );

    fifo #(
        .DATA_WIDTH (8),
        .ADDR_WIDTH (FIFO_ADDR_WIDTH))
    rx_buffer (
        .clk     ( clk              ),
        .rst     ( rst              ),
        .enqueue ( rx_data_ready    ),
        .dequeue ( read             ),
        .data_i  ( rx_data          ),
        .data_o  ( data_o           ),
        .count   ( rx_count         ),
        .empty   ( rx_fifo_empty    ),
        .full    ( uart_rx_full_int )
    );
endmodule
