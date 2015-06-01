//==================================================================================================
//  Filename      : uart_tx.v
//  Created On    : 2015-01-08 19:21:16
//  Last Modified : 2015-05-24 21:04:24
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Transmitter module for UART
//                  Based on the Tx module from XUM project
//                  Author: Grant Ayers (ayers@cs.utah.edu)
//==================================================================================================

module uart_tx(
    input            clk,
    input            rst,
    input            uart_tick,     // module "tick". More like an enable.
    input      [7:0] TxD_data,      // Input data
    input            TxD_start,     // Enable transmission
    output           ready,         // Tx buffer is empty, and ready for a new transmission
    output reg       TxD            // Tx output pin
    );

    //--------------------------------------------------------------------------
    // "local variables": the FMS states.
    //--------------------------------------------------------------------------
    localparam [3:0] IDLE=0;        // FSM states
    localparam [3:0] START=1;       // FSM states
    localparam [3:0] BIT_0=2;       // FSM states
    localparam [3:0] BIT_1=3;       // FSM states
    localparam [3:0] BIT_2=4;       // FSM states
    localparam [3:0] BIT_3=5;       // FSM states
    localparam [3:0] BIT_4=6;       // FSM states
    localparam [3:0] BIT_5=7;       // FSM states
    localparam [3:0] BIT_6=8;       // FSM states
    localparam [3:0] BIT_7=9;       // FSM states
    localparam [3:0] STOP=10;       // FSM states

    //--------------------------------------------------------------------------
    // registers
    //--------------------------------------------------------------------------
    reg [3:0] tx_state   = IDLE;
    reg [7:0] TxD_data_r = 8'h00;    // Registered input data so it doesn't need to be held

    //--------------------------------------------------------------------------
    // assignment output signals
    //--------------------------------------------------------------------------
    assign ready = (tx_state == IDLE) || (tx_state == STOP);

    always @(posedge clk) begin
        TxD_data_r <= (ready & TxD_start) ? TxD_data : TxD_data_r;
    end

    //--------------------------------------------------------------------------
    // Get the new state
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst)
            tx_state <= IDLE;
        else begin
            case (tx_state)
                IDLE:   if (TxD_start) tx_state <= START;
                START:  if (uart_tick) tx_state <= BIT_0;
                BIT_0:  if (uart_tick) tx_state <= BIT_1;
                BIT_1:  if (uart_tick) tx_state <= BIT_2;
                BIT_2:  if (uart_tick) tx_state <= BIT_3;
                BIT_3:  if (uart_tick) tx_state <= BIT_4;
                BIT_4:  if (uart_tick) tx_state <= BIT_5;
                BIT_5:  if (uart_tick) tx_state <= BIT_6;
                BIT_6:  if (uart_tick) tx_state <= BIT_7;
                BIT_7:  if (uart_tick) tx_state <= STOP;
                STOP:   if (uart_tick) tx_state <= (TxD_start) ? START : IDLE;
                default:               tx_state <= 4'bxxxx;
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // Set Tx pin
    //--------------------------------------------------------------------------
    always @(tx_state, TxD_data_r) begin
        case (tx_state)
            IDLE:    TxD <= 1;
            START:   TxD <= 0;
            BIT_0:   TxD <= TxD_data_r[0];
            BIT_1:   TxD <= TxD_data_r[1];
            BIT_2:   TxD <= TxD_data_r[2];
            BIT_3:   TxD <= TxD_data_r[3];
            BIT_4:   TxD <= TxD_data_r[4];
            BIT_5:   TxD <= TxD_data_r[5];
            BIT_6:   TxD <= TxD_data_r[6];
            BIT_7:   TxD <= TxD_data_r[7];
            STOP:    TxD <= 1;
            default: TxD <= 1'bx;
        endcase
    end
endmodule
