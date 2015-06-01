//==================================================================================================
//  Filename      : fifo.v
//  Created On    : 2015-01-07 21:57:26
//  Last Modified : 2015-05-24 23:32:44
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : A synchronous and configurable FIFO.
//                  Based on the FIFO module from XUM project
//                  Author: Grant Ayers (ayers@cs.utah.edu)
//
//                  From the original description:
//                  A FIFO of variable data width and depth. 'enqueue' is ignored when
//                  the FIFO is full and 'dequeue' is ignored when the FIFO is empty. If 'enqueue' and
//                  'dequeue' are asserted simultaneously, the FIFO is unchanged and the output data
//                  is the same as the input data.
//
//                  This FIFO is "First word fall-through" meaning data can be read without
//                  asserting 'dequeue' by merely supplying an address. However, when 'dequeue' is
//                  asserted, the data is "removed" from the FIFO and one location is freed.
//                  If the FIFO is empty and 'enqueue' and 'dequeue' are not asserted simultaneously,
//                  the output data will be 0s.
//==================================================================================================

module fifo#(
    parameter DATA_WIDTH = 8,                   // 8-bits data (default)
    parameter ADDR_WIDTH = 8                    // 8-bits address (default)
    )(
    input                           clk,
    input                           rst,
    input                           enqueue,          // Insert data
    input                           dequeue,          // Remove data
    input       [(DATA_WIDTH-1):0]  data_i,           // Input data
    output      [(DATA_WIDTH-1):0]  data_o,           // Output data
    output reg  [(ADDR_WIDTH):0]    count,            // How many elements are in the FIFO (0->256)
    output                          empty,            // Empty flag
    output                          full              // Full flag
    );

    //--------------------------------------------------------------------------
    // wires
    //--------------------------------------------------------------------------
    wire w_enqueue;
    wire w_dequeue;
    wire [(DATA_WIDTH-1):0] w_data_o;

    //--------------------------------------------------------------------------
    // registers
    //--------------------------------------------------------------------------
    reg [(ADDR_WIDTH-1):0] enqueue_ptr;     // Addresses for reading from and writing to internal memory
    reg [(ADDR_WIDTH-1):0] dequeue_ptr;     // Addresses for reading from and writing to internal memory

    //--------------------------------------------------------------------------
    // Assignments
    //--------------------------------------------------------------------------
    assign empty     = (count == 0);
    assign full      = (count == (1 << ADDR_WIDTH));
    assign w_enqueue = (full)  ? 1'b0                                                   : enqueue;   // Ignore if full
    assign w_dequeue = (empty) ? 1'b0                                                   : dequeue;   // Ignore if empty
    assign data_o    = (empty) ? ((enqueue & dequeue) ? data_i : { DATA_WIDTH {1'b0} }) : w_data_o;  // Read description

    always @(posedge clk) begin
        if (rst) begin
            enqueue_ptr <= 0;
            dequeue_ptr <= 0;
            count       <= 0;
        end
        else begin
            enqueue_ptr <= (w_enqueue)              ? enqueue_ptr + 1'b1 : enqueue_ptr;
            dequeue_ptr <= (w_dequeue)              ? dequeue_ptr + 1'b1 : dequeue_ptr;
            count       <= (w_enqueue ~^ w_dequeue) ? count              : ((w_enqueue) ? count + 1'b1 : count - 1'b1); // Read description
        end
    end

    ram #(DATA_WIDTH, ADDR_WIDTH) RAM(
            .clk           (clk),
            .we            (w_enqueue),
            .read_address  (dequeue_ptr),
            .write_address (enqueue_ptr),
            .data_i        (data_i),
            .data_o        (w_data_o)
            );
endmodule
