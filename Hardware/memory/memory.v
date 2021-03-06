//==================================================================================================
//  Filename      : memory.v
//  Created On    : 2014-09-28 20:35:52
//  Last Modified : 2015-05-31 21:18:35
//  Revision      :
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Dual-port memory
//==================================================================================================

`include "musb_defines.v"

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
    // Signal Declaration: reg
    //--------------------------------------------------------------------------
    reg     [31:0]  a_data_out;
    reg     [31:0]  b_data_out;

    //--------------------------------------------------------------------------
    // Set the ready signal
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        a_ready <= (rst) ? 1'b0 : a_enable;
        b_ready <= (rst) ? 1'b0 : b_enable;
    end

    //--------------------------------------------------------------------------
    // assigment
    //--------------------------------------------------------------------------
    always @(*) begin
        a_dout <= (a_ready) ? a_data_out : 32'bz;
        b_dout <= (b_ready) ? b_data_out : 32'bz;
    end

    //--------------------------------------------------------------------------
    // inicializar memoria
    //--------------------------------------------------------------------------
    reg [31:0] mem [0:(2**addr_size)-1];
    initial begin
        $readmemh("mem.hex", mem);
    end

    //--------------------------------------------------------------------------
    // Port A
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        a_data_out <= mem[a_addr];
        if(a_wr) begin
            a_data_out         <= a_din;
            mem[a_addr][7:0]   <= (a_wr[0] & a_enable) ? a_din[7:0]   : mem[a_addr][7:0];
            mem[a_addr][15:8]  <= (a_wr[1] & a_enable) ? a_din[15:8]  : mem[a_addr][15:8];
            mem[a_addr][23:16] <= (a_wr[2] & a_enable) ? a_din[23:16] : mem[a_addr][23:16];
            mem[a_addr][31:24] <= (a_wr[3] & a_enable) ? a_din[31:24] : mem[a_addr][31:24];
        end
    end

    //--------------------------------------------------------------------------
    // Port B
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        b_data_out <= mem[b_addr];
        if(b_wr) begin
            b_data_out         <= b_din;
            mem[b_addr][7:0]   <= (b_wr[0] & b_enable) ? b_din[7:0]   : mem[b_addr][7:0];
            mem[b_addr][15:8]  <= (b_wr[1] & b_enable) ? b_din[15:8]  : mem[b_addr][15:8];
            mem[b_addr][23:16] <= (b_wr[2] & b_enable) ? b_din[23:16] : mem[b_addr][23:16];
            mem[b_addr][31:24] <= (b_wr[3] & b_enable) ? b_din[31:24] : mem[b_addr][31:24];
        end
    end
 endmodule
