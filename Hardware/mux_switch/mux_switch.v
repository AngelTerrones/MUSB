//==================================================================================================
//  Filename      : mux_switch.v
//  Created On    : 2015-04-09 16:38:08
//  Last Modified : 2015-05-24 21:01:14
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Multiplexer: 1 Master, N Slaves
//                  DO NOT OVERLAP REGIONS
//
//                  Based on the Wishbone multiplexer module from the ORPSOC-CORE project.
//                  Author: Olof Kindgren, olof@opencores.org
//==================================================================================================

module mux_switch #(
    parameter                   nslaves     = 2,
    parameter [nslaves*32-1:0]  MATCH_ADDR  = 0,
    parameter [nslaves*32-1:0]  MATCH_MASK  = 0
    )(
    input                           clk,
    // Master
    input   [31:0]              master_address,     // Slave's address
    input   [31:0]              master_data_i,      // Data from Master
    input   [3:0]               master_wr,          // Byte selector
    input                       master_enable,      // Enable operation
    output  [31:0]              master_data_o,      // Data to Master
    output                      master_ready,       // Ready signal to Master
    output  reg                 master_error,       // No valid address
    // slave
    input   [nslaves*32-1:0]    slave_data_i,       // Data from slave
    input   [nslaves-1:0]       slave_ready,        // Ready signal from Slave
    //input   [nslaves-1:0]       slave_err,        // Slave error signal
    output  [31:0]              slave_address,      // Address to Slave
    output  [31:0]              slave_data_o,       // Data to Slave
    output  [3:0]               slave_wr,           // Byte selector
    output  [nslaves-1:0]       slave_enable        // Enable operation
    );
    //--------------------------------------------------------------------------
    // Local parameters
    //--------------------------------------------------------------------------
    localparam integer clog_ns = (nslaves <= 1 << 1)  ? 1  :
                                 (nslaves <= 1 << 2)  ? 2  :
                                 (nslaves <= 1 << 3)  ? 3  :
                                 (nslaves <= 1 << 4)  ? 4  :
                                 (nslaves <= 1 << 5)  ? 5  :
                                 (nslaves <= 1 << 6)  ? 6  :
                                 (nslaves <= 1 << 7)  ? 7  :
                                 (nslaves <= 1 << 8)  ? 8  :
                                 (nslaves <= 1 << 9)  ? 9  :
                                 (nslaves <= 1 << 10) ? 10 :
                                 (nslaves <= 1 << 11) ? 11 :
                                 (nslaves <= 1 << 12) ? 12 :
                                 (nslaves <= 1 << 13) ? 13 :
                                 (nslaves <= 1 << 14) ? 14 :
                                 (nslaves <= 1 << 15) ? 15 :
                                 (nslaves <= 1 << 16) ? 16 :
                                 (nslaves <= 1 << 17) ? 17 :
                                 (nslaves <= 1 << 18) ? 18 :
                                 (nslaves <= 1 << 19) ? 19 : 20;
    localparam slave_sel_bits = nslaves > 1 ? clog_ns : 1;

    //--------------------------------------------------------------------------
    // Registers & wires
    //--------------------------------------------------------------------------
    wire [slave_sel_bits-1:0] slave_sel;
    wire [nslaves-1:0]        match;
    reg  [8:0]                watchdog_counter;

    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign slave_sel        = ff1(match, nslaves);

    assign slave_address    = master_address;
    assign slave_data_o     = master_data_i;
    assign slave_wr         = master_wr;
    assign slave_enable     = match & {nslaves{master_enable}};

    assign master_data_o    = slave_data_i[slave_sel*32+:32];
    assign master_ready     = slave_ready[slave_sel];

    //--------------------------------------------------------------------------
    // Get the slave
    //--------------------------------------------------------------------------
    generate
        genvar i;
        for (i = 0; i < nslaves; i = i + 1)
        begin:addr_match
            assign match[i] = (master_address & MATCH_MASK[i*32+:32]) == MATCH_ADDR[i*32+:32];
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Watchdog
    // Increment the counter only if master_enable == 1 (free-running counter)
    // Generates a one-clock pulse to generate the exception and enter
    // Reset otherwise
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        master_error <= (watchdog_counter[8] & (|match)) | (master_enable & ~(|match));    // timeout with match, or no march at all

        if (master_enable) begin
            watchdog_counter <= watchdog_counter[7:0] + 8'b1;
        end
        else begin
            watchdog_counter <= 9'b0;
        end
    end

    //--------------------------------------------------------------------------
    // Function:
    // Find First 1 - Start from MSB and count downwards, returns 0 when no bit set
    //--------------------------------------------------------------------------
    function integer ff1;
    input integer in;
    input integer width;
    integer i;
    begin
        ff1 = 0;
        for (i = width-1; i >= 0; i=i-1) begin
            if (in[i])
                ff1 = i;
        end
    end
    endfunction
endmodule
