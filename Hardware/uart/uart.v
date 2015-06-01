//==================================================================================================
//  Filename      : uart.v
//  Created On    : 2015-01-09 07:45:55
//  Last Modified : 2015-05-24 21:07:29
//  Revision      :
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : UART module. Configuration: 115200, 8N1. No flow control
//                  With slave port.
//                  Based on the Rx module from XUM project.
//                  Author: Grant Ayers (ayers@cs.utah.edu)
//==================================================================================================

module uart(
    input             clk,
    input             rst,
    // Bus I/O
    input      [2:0]  uart_address,         // Address
    input      [7:0]  uart_data_i,          // Data from bus
    input             uart_wr,              // Byte select
    input             uart_enable,          // Enable operation
    output reg [7:0]  uart_data_o,          // Data to bus
    output reg        uart_ready,           // Ready operation
    // Interrupt: Data available in Rx fifo
    output            uart_rx_ready_int,    //
    output            uart_rx_full_int,     //
    // Off chip I/O
    input             uart_rx,              // Rx pin
    output            uart_tx               // Tx pin
    );

    //--------------------------------------------------------------------------
    // "local variables": FIFO size and address of registers
    //--------------------------------------------------------------------------
    localparam DATA_WIDTH = 8; // Bit-width of FIFO data (should be 8)
    localparam ADDR_WIDTH = 8; // 2^ADDR_WIDTH words of FIFO space

    localparam RX_TX_BUFFER = 0;    // base address: In/Out buffer
    localparam TX_COUNT_L   = 1;    // base address: Tx fifo count, low byte
    localparam TX_COUNT_H   = 2;    // base address: Tx fifo count, high byte
    localparam RX_COUNT_L   = 3;    // base address: Rx fifo count, low byte
    localparam RX_COUNT_H   = 4;    // base address: Rx fifo count, high byte

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
    wire [7:0]  rx_read_data;

    //--------------------------------------------------------------------------
    // Tx signals
    //--------------------------------------------------------------------------
    reg         tx_fifo_deQ = 0;
    reg         tx_start    = 0;
    wire        tx_free;
    wire        tx_fifo_empty;
    wire [7:0]  tx_fifo_data_out;
    reg  [7:0]  tx_input_data;


    //--------------------------------------------------------------------------
    // Handle Tx FIFO
    //--------------------------------------------------------------------------
    assign uart_rx_ready_int = ~rx_fifo_empty;

    always @(posedge clk) begin
        if (rst) begin
            tx_fifo_deQ <= 0;
            tx_start <= 0;
        end
        else begin
            if (~tx_fifo_empty & tx_free & uart_tick) begin
                tx_fifo_deQ <= 1;
                tx_start <= 1;
            end
            else begin
                tx_fifo_deQ <= 0;
                tx_start <= 0;
            end
        end
    end

    //--------------------------------------------------------------------------
    // Handle R to this module
    //--------------------------------------------------------------------------
    wire [ADDR_WIDTH : 0] tx_count;
    wire [ADDR_WIDTH : 0] rx_count;

    always @(posedge clk) begin
        if (~uart_wr & uart_enable) begin
            case (uart_address)
                RX_TX_BUFFER : begin uart_data_o <= rx_read_data;           uart_ready <= 1'b1; end
                TX_COUNT_L   : begin uart_data_o <= tx_count[7:0];          uart_ready <= 1'b1; end
                TX_COUNT_H   : begin uart_data_o <= tx_count[ADDR_WIDTH:8]; uart_ready <= 1'b1; end
                RX_COUNT_L   : begin uart_data_o <= rx_count[7:0];          uart_ready <= 1'b1; end
                RX_COUNT_H   : begin uart_data_o <= rx_count[ADDR_WIDTH:8]; uart_ready <= 1'b1; end
                default      : begin uart_data_o <= 8'hxx;                  uart_ready <= 1'b1; end
            endcase
        end
        else begin
            uart_data_o <= 8'hxx;
            uart_ready  <= 1'b0;
        end
    end

    //--------------------------------------------------------------------------
    // Handle W to this module
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (uart_wr & uart_enable) begin
            case (uart_address)
                RX_TX_BUFFER : begin tx_input_data <= uart_data_i; uart_ready <= 1'b1; end
                default      : begin tx_input_data <= 8'hxx;       uart_ready <= 1'b1; end
            endcase
        end
        else begin
            tx_input_data <= 8'hxx;
            uart_ready <= 1'b0;
        end
    end

    //--------------------------------------------------------------------------
    // Instantiate modules
    //--------------------------------------------------------------------------
    uart_clock clks (
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
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH))
    tx_buffer (
        .clk     ( clk                                 ),
        .rst     ( rst                                 ),
        .enqueue ( uart_wr & uart_enable & ~uart_ready ),
        .dequeue ( tx_fifo_deQ                         ),
        .data_i  ( tx_input_data                       ),
        .data_o  ( tx_fifo_data_out                    ),
        .count   ( tx_count                            ),
        .empty   ( tx_fifo_empty                       ),
        .full    (                                     )
    );

    fifo #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH))
    rx_buffer (
        .clk     ( clk                                  ),
        .rst     ( rst                                  ),
        .enqueue ( rx_data_ready                        ),
        .dequeue ( ~uart_wr & uart_enable & ~uart_ready ),
        .data_i  ( rx_data                              ),
        .data_o  ( rx_read_data                         ),
        .count   ( rx_count                             ),
        .empty   ( rx_fifo_empty                        ),
        .full    ( uart_rx_full_int                     )
    );
endmodule
