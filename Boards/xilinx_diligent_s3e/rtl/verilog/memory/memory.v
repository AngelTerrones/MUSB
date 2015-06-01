//==================================================================================================
//  Filename      : memory.v
//  Created On    : 2014-09-28 20:35:52
//  Last Modified : 2015-05-28 10:00:31
//  Revision      :
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Dual-port memory
//                  This memory use 4 lanes because of FPGA limitations (Spartan 3 XC3S500E)
//==================================================================================================

module memory#(
    parameter addr_size = 8                 // Default: 256 words/1 KB
    )(
    input                       clk,
    input                       rst,
    //port A
    input       [addr_size-1:0] a_addr,     // Address
    input       [31:0]          a_din,      // Data input
    input       [3:0]           a_wr,       // Write/Read
    input                       a_enable,   // Valid operation
    output  reg [31:0]          a_dout,     // Data output
    output  reg                 a_ready,    // Data output ready (valid)
    // port B
    input       [addr_size-1:0] b_addr,     // Address
    input       [31:0]          b_din,      // Data input
    input       [3:0]           b_wr,       // Write/Read
    input                       b_enable,   // Valid operation
    output  reg [31:0]          b_dout,     // Data output
    output  reg                 b_ready     // Data output ready (valid)
    );

    //--------------------------------------------------------------------------
    // Signal Declaration: wire
    //--------------------------------------------------------------------------
    wire    [31:0]  a_data_out;
    wire    [31:0]  b_data_out;

    //--------------------------------------------------------------------------
    // Set the ready signal
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        a_ready <= (rst) ? 1'b0 : a_enable;
        b_ready <= (rst) ? 1'b0 : b_enable;
    end

    //--------------------------------------------------------------------------
    // assignment
    //--------------------------------------------------------------------------
    always @(*) begin
        a_dout <= (a_ready) ? a_data_out : 32'bx;
        b_dout <= (b_ready) ? b_data_out : 32'bx;
    end

    //--------------------------------------------------------------------------
    // instantiate 4 memory banks
    //--------------------------------------------------------------------------
    memory_bram_dp #(8, addr_size) bank0(
    // instruction
    .a_clk  ( clk                ),
    .a_wr   ( a_wr[0] & a_enable ),
    .a_addr ( a_addr             ),
    .a_din  ( a_din[7:0]         ),
    .a_dout ( a_data_out[7:0]    ),
    // data
    .b_clk  ( clk                ),
    .b_wr   ( b_wr[0] & b_enable ),
    .b_addr ( b_addr             ),
    .b_din  ( b_din[7:0]         ),
    .b_dout ( b_data_out[7:0]    )
    );

    memory_bram_dp #(8, addr_size) bank1(
    // instruction
    .a_clk  ( clk                ),
    .a_wr   ( a_wr[1] & a_enable ),
    .a_addr ( a_addr             ),
    .a_din  ( a_din[15:8]        ),
    .a_dout ( a_data_out[15:8]   ),
    // data
    .b_clk  ( clk                ),
    .b_wr   ( b_wr[1] & b_enable ),
    .b_addr ( b_addr             ),
    .b_din  ( b_din[15:8]        ),
    .b_dout ( b_data_out[15:8]   )
    );

    memory_bram_dp #(8, addr_size) bank2(
    // instruction
    .a_clk  ( clk                ),
    .a_wr   ( a_wr[2] & a_enable ),
    .a_addr ( a_addr             ),
    .a_din  ( a_din[23:16]       ),
    .a_dout ( a_data_out[23:16]  ),
    // data
    .b_clk  ( clk                ),
    .b_wr   ( b_wr[2] & b_enable ),
    .b_addr ( b_addr             ),
    .b_din  ( b_din[23:16]       ),
    .b_dout ( b_data_out[23:16]  )
    );

    memory_bram_dp #(8, addr_size) bank3(
    // instruction
    .a_clk  ( clk                ),
    .a_wr   ( a_wr[3] & a_enable ),
    .a_addr ( a_addr             ),
    .a_din  ( a_din[31:24]       ),
    .a_dout ( a_data_out[31:24]  ),
    // data
    .b_clk  ( clk                ),
    .b_wr   ( b_wr[3] & b_enable ),
    .b_addr ( b_addr             ),
    .b_din  ( b_din[31:24]       ),
    .b_dout ( b_data_out[31:24]  )
    );
 endmodule
