//==================================================================================================
//  Filename      : gpio.v
//  Created On    : 2015-01-02 19:44:15
//  Last Modified : 2015-06-03 12:16:37
//  Revision      :
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : 8-bit GPIO module x 4
//
//                  Register's name:
//                  - PD: Port Data
//                  - DD: Data Direction
//                  - IE: Interrupt Enable (pin)
//                  - EP: Edge polarity: 0 -> Falling. 1-> Rising
//                  - IC: Clear interrupt flag
//
//                  Using a 5-bits address:
//                  - PTxD   @ 0x00 + port number
//                  - PTxDD  @ 0x04 + port number
//                  - PTxIE  @ 0x08 + port number
//                  - PTxEP  @ 0x0C + port number
//                  - PTxIC  @ 0x10 + port number
//==================================================================================================

`define GPIO_PD         5'd0
`define gpio_oe         5'd1
`define GPIO_IE         5'd2
`define GPIO_EP         5'd3
`define GPIO_IC         5'd4
`define GPIO_UA         5'd5                // unimplemented address
`define GPIO_ADDR_RANGE 2:0

module gpio(
    input               clk,
    input               rst,
    input       [31:0]  gpio_i,         // Input port
    input       [31:0]  gpio_address,   // Address
    input       [31:0]  gpio_data_i,    // Data from bus
    input       [3:0]   gpio_wr,        // Byte select
    input               gpio_enable,    // Enable operation
    output  reg [31:0]  gpio_o,         // Output port
    output  reg [31:0]  gpio_oe,        // Output enable
    output  reg [31:0]  gpio_data_o,    // Data to bus
    output  reg         gpio_ready,     // Ready operation
    output  reg [3:0]   gpio_interrupt  // Active interrupt
    );

    //--------------------------------------------------------------------------
    // wire
    //--------------------------------------------------------------------------
    wire            enable_write;
    wire            enable_read;
    wire    [29:0]  address;
    wire    [31:0]  posedge_interrupt;
    wire    [31:0]  negedge_interrupt;
    wire            int_port_a;                                                     // the interrupt signals from port A
    wire            int_port_b;                                                     // the interrupt signals from port B
    wire            int_port_c;                                                     // the interrupt signals from port C
    wire            int_port_d;                                                     // the interrupt signals from port D

    //--------------------------------------------------------------------------
    // registers
    //--------------------------------------------------------------------------
    reg     [31:0]  gpio_data_reg_i;                                                // input data register
    reg     [31:0]  gpio_data_reg_sync_i;                                           // sync register
    reg     [31:0]  gpio_ie;                                                        // interrupt enable
    reg     [31:0]  gpio_ep;                                                        // edge polarity

    //--------------------------------------------------------------------------
    // Assignments
    //--------------------------------------------------------------------------
    assign enable_write      = gpio_enable & ~gpio_ready & (gpio_wr != 4'b0000);    // Enable if Valid operation, and write at least one byte
    assign enable_read       = gpio_enable & ~gpio_ready & (gpio_wr == 4'b0000);
    assign address           = gpio_address[31:2];
    assign posedge_interrupt = (gpio_data_reg_sync_i & ~gpio_data_reg_i) & gpio_ep  & gpio_ie & ~gpio_oe;  // detect and enable
    assign negedge_interrupt = (~gpio_data_reg_sync_i & gpio_data_reg_i) & ~gpio_ep & gpio_ie & ~gpio_oe; // detect and enable

    // or all the signals, and combine posedge and negedge interrupts
    assign int_port_a = (|posedge_interrupt[7:0])   | (|negedge_interrupt[7:0])  ;
    assign int_port_b = (|posedge_interrupt[15:8])  | (|negedge_interrupt[15:8]) ;
    assign int_port_c = (|posedge_interrupt[23:16]) | (|negedge_interrupt[23:16]);
    assign int_port_d = (|posedge_interrupt[31:24]) | (|negedge_interrupt[31:24]);

    //--------------------------------------------------------------------------
    // Set data input
    // Just sample/register the input data
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_data_reg_i      <= 32'b0;
            gpio_data_reg_sync_i <= 32'b0;
        end
        else begin
            gpio_data_reg_sync_i <= gpio_i;
            gpio_data_reg_i      <= gpio_data_reg_sync_i;
        end
    end

    //--------------------------------------------------------------------------
    // ACK generation
    // Assert the ready port each cycle, depending on the enable signal.
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_ready <= 1'b0;
        end
        else begin
            gpio_ready <= gpio_enable & (address[`GPIO_ADDR_RANGE] < `GPIO_UA);
        end
    end

    //--------------------------------------------------------------------------
    // write registers
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_o          <= 32'b0;
            gpio_oe         <= 32'b0;
            gpio_ie         <= 32'b0;
            gpio_ep         <= 32'b0;
            gpio_interrupt  <= 4'b0;
        end
        else if (enable_write) begin
            case(address[`GPIO_ADDR_RANGE])
                `GPIO_PD:   begin
                                gpio_o[7:0]   <= (gpio_wr[0]) ? gpio_data_i[7:0]   : gpio_o[7:0];
                                gpio_o[15:8]  <= (gpio_wr[1]) ? gpio_data_i[15:8]  : gpio_o[15:8];
                                gpio_o[23:16] <= (gpio_wr[2]) ? gpio_data_i[23:16] : gpio_o[23:16];
                                gpio_o[31:24] <= (gpio_wr[3]) ? gpio_data_i[31:24] : gpio_o[31:24];
                            end
                `gpio_oe:   begin
                                gpio_oe[7:0]   <= (gpio_wr[0]) ? gpio_data_i[7:0]   : gpio_oe[7:0];
                                gpio_oe[15:8]  <= (gpio_wr[1]) ? gpio_data_i[15:8]  : gpio_oe[15:8];
                                gpio_oe[23:16] <= (gpio_wr[2]) ? gpio_data_i[23:16] : gpio_oe[23:16];
                                gpio_oe[31:24] <= (gpio_wr[3]) ? gpio_data_i[31:24] : gpio_oe[31:24];
                            end
                `GPIO_IE:   begin
                                gpio_ie[7:0]   <= (gpio_wr[0]) ? gpio_data_i[7:0]   : gpio_ie[7:0];
                                gpio_ie[15:8]  <= (gpio_wr[1]) ? gpio_data_i[15:8]  : gpio_ie[15:8];
                                gpio_ie[23:16] <= (gpio_wr[2]) ? gpio_data_i[23:16] : gpio_ie[23:16];
                                gpio_ie[31:24] <= (gpio_wr[3]) ? gpio_data_i[31:24] : gpio_ie[31:24];
                            end
                `GPIO_EP:   begin
                                gpio_ep[7:0]   <= (gpio_wr[0]) ? gpio_data_i[7:0]   : gpio_ep[7:0];
                                gpio_ep[15:8]  <= (gpio_wr[1]) ? gpio_data_i[15:8]  : gpio_ep[15:8];
                                gpio_ep[23:16] <= (gpio_wr[2]) ? gpio_data_i[23:16] : gpio_ep[23:16];
                                gpio_ep[31:24] <= (gpio_wr[3]) ? gpio_data_i[31:24] : gpio_ep[31:24];
                            end
                `GPIO_IC:   begin
                                gpio_interrupt[0] <= (gpio_wr[0]) ? 1'b0 : int_port_a | gpio_interrupt[0];
                                gpio_interrupt[1] <= (gpio_wr[1]) ? 1'b0 : int_port_b | gpio_interrupt[1];
                                gpio_interrupt[2] <= (gpio_wr[2]) ? 1'b0 : int_port_c | gpio_interrupt[2];
                                gpio_interrupt[3] <= (gpio_wr[3]) ? 1'b0 : int_port_d | gpio_interrupt[3];
                            end
            endcase
        end
        else begin
            gpio_o            <= gpio_o;
            gpio_oe           <= gpio_oe;
            gpio_ie           <= gpio_ie;
            gpio_ep           <= gpio_ep;
            gpio_interrupt[0] <= int_port_a | gpio_interrupt[0];
            gpio_interrupt[1] <= int_port_b | gpio_interrupt[1];
            gpio_interrupt[2] <= int_port_c | gpio_interrupt[2];
            gpio_interrupt[3] <= int_port_d | gpio_interrupt[3];
        end
    end

    //--------------------------------------------------------------------------
    // read registers
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_data_o <= 32'b0;
        end
        else if (enable_read) begin
            case(address[`GPIO_ADDR_RANGE])
                `GPIO_PD : gpio_data_o <= gpio_data_reg_i;
                `gpio_oe : gpio_data_o <= gpio_oe;
                `GPIO_IE : gpio_data_o <= gpio_ie;
                `GPIO_EP : gpio_data_o <= gpio_ep;
                `GPIO_IC : gpio_data_o <= 32'h0;
                default  : gpio_data_o <= 32'hx;
            endcase
        end
    end
endmodule
