//==================================================================================================
//  Filename      : arbite.v
//  Created On    : 2015-04-09 10:25:59
//  Last Modified : 2015-05-24 20:54:42
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Arbiter: N masters, 1 slaves.
//                  Priority: Master with the highest number.
//                  Non registered version.
//
//                  Based on the Wishbone arbiter module from the ORPSOC-CORE project.
//                  Author: Olof Kindgren, olof@opencores.org
//==================================================================================================

module arbiter #(
    parameter nmasters = 2
    )(
    input                           clk,
    input                           rst,
    // Master
    input       [32*nmasters-1:0]   master_address,     // Slave's address
    input       [32*nmasters-1:0]   master_data_i,      // Data from Master
    input       [4*nmasters-1:0]    master_wr,          // Byte selector
    input       [nmasters-1 : 0]    master_enable,      // Enable operation
    output      [31:0]              master_data_o,      // Data to Master
    output      [nmasters-1 : 0]    master_ready,       // Ready signal to Master
    output      [nmasters-1 : 0]    master_error,       // Error signal
    // slave
    input       [31:0]              slave_data_i,       // Data from slave
    input                           slave_ready,        // Ready signal from Slave
    input                           slave_error,        // Error signal
    output      [31:0]              slave_address,      // Address to Slave
    output      [31:0]              slave_data_o,       // Data to Slave
    output      [3:0]               slave_wr,           // Byte selector
    output                          slave_enable        // Enable operation
    );

    //--------------------------------------------------------------------------
    // Local parameters
    //--------------------------------------------------------------------------
    localparam integer clog_nm = (nmasters <= 1 << 1)  ? 1  :
                                 (nmasters <= 1 << 2)  ? 2  :
                                 (nmasters <= 1 << 3)  ? 3  :
                                 (nmasters <= 1 << 4)  ? 4  :
                                 (nmasters <= 1 << 5)  ? 5  :
                                 (nmasters <= 1 << 6)  ? 6  :
                                 (nmasters <= 1 << 7)  ? 7  :
                                 (nmasters <= 1 << 8)  ? 8  :
                                 (nmasters <= 1 << 9)  ? 9  :
                                 (nmasters <= 1 << 10) ? 10 :
                                 (nmasters <= 1 << 11) ? 11 :
                                 (nmasters <= 1 << 12) ? 12 :
                                 (nmasters <= 1 << 13) ? 13 :
                                 (nmasters <= 1 << 14) ? 14 :
                                 (nmasters <= 1 << 15) ? 15 :
                                 (nmasters <= 1 << 16) ? 16 :
                                 (nmasters <= 1 << 17) ? 17 :
                                 (nmasters <= 1 << 18) ? 18 :
                                 (nmasters <= 1 << 19) ? 19 : 20;
    localparam master_sel_bits = nmasters > 1 ? clog_nm : 1;

    //--------------------------------------------------------------------------
    // Registers & wires
    //--------------------------------------------------------------------------
    wire [master_sel_bits-1:0]  master_sel;         // Index of the master with priority: using the master enable signals
    wire [master_sel_bits-1:0]  master_sel2;        // Index of the selected master: using the grant signal.
    reg  [nmasters-1:0]         grant;
    reg  [nmasters-1:0]         selected;

    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign master_sel    = fl1(master_enable, nmasters);
    assign master_sel2   = fl1(grant, nmasters);
    assign slave_address = master_address[master_sel2*32+:32];
    assign slave_data_o  = master_data_i[master_sel2*32+:32];
    assign slave_wr      = master_wr[master_sel2*4+:4];
    assign slave_enable  = master_enable[master_sel2];

    assign master_data_o = slave_data_i;
    assign master_ready  = grant & {nmasters{slave_ready}};
    assign master_error  = grant & {nmasters{slave_error}};

    //--------------------------------------------------------------------------
    // Function:
    // Find Last 1 -  Start from LSB and count upwards, returns 0 when no bit set
    //--------------------------------------------------------------------------
    function integer fl1;
    input integer in;
    input integer width;
    integer i;
    begin
        fl1 = 0;
        for (i = 0; i < width; i=i+1) begin
            if (in[i])
                fl1 = i;
        end
    end
    endfunction

    //--------------------------------------------------------------------------
    // Select the master
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            selected <= 0;
        end
        else begin
            selected <= grant & master_enable;
        end
    end

    always @(*) begin
        if (selected == 0) begin
            grant <= (1'b1 << master_sel);
        end
        else begin
            grant <= selected;
        end
    end
endmodule
