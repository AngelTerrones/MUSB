//==================================================================================================
//  Filename      : gpio.v
//  Created On    : 2015-01-02 19:44:15
//  Last Modified : 2015-05-24 20:58:09
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
//                  - PTAD  @ 0x00      (offset = 0)
//                  - PTBD  @ 0x01
//                  - PTCD  @ 0x02
//                  - PTDD  @ 0x03
//
//                  - PTADD @ 0x04      (offset = 4)
//                  - PTBDD @ 0x05
//                  - PTCDD @ 0x06
//                  - PTDDD @ 0x07
//
//                  - PTAIE @ 0x08      (offset = 8)
//                  - PTBIE @ 0x09
//                  - PTCIE @ 0x0A
//                  - PTDIE @ 0x0B
//
//                  - PTAEP @ 0x0C      (offset = 12)
//                  - PTBEP @ 0x0D
//                  - PTCEP @ 0x0E
//                  - PTDEP @ 0x0F
//
//                  - PTAIC @ 0x10      (offset = 16)
//                  - PTBIC @ 0x11
//                  - PTCIC @ 0x12
//                  - PTDIC @ 0x13
//==================================================================================================

`define GPIO_PD_OFFSET  5'd0
`define GPIO_DD_OFFSET  5'd4
`define GPIO_IE_OFFSET  5'd8
`define GPIO_EP_OFFSET  5'd12
`define GPIO_IC_OFFSET  5'd16
`define GPIO_UA_OFFSET  5'd20       // unimplemented address

`define ADDR_CHECK      5'b11100

module gpio(
    input               clk,
    input               rst,
    inout       [31:0]  gpio_inout,     // input/output port
    input       [4:0]   gpio_address,   // Address
    input       [31:0]  gpio_data_i,    // Data from bus
    input       [3:0]   gpio_wr,        // Byte select
    input               gpio_enable,    // Enable operation
    output  reg [31:0]  gpio_data_o,    // Data to bus
    output  reg         gpio_ready,     // Ready operation
    output  reg [3:0]   gpio_interrupt  // Active interrupt. One for each port.
    );

    //--------------------------------------------------------------------------
    // wire
    //--------------------------------------------------------------------------
    wire    [31:0]  gpio_data_wire_i;
    wire            enable_write;
    wire            enable_read;
    wire    [31:0]  interrupt_signal;                                               // Input "edges"
    wire            int_port_a;                                                     // the interrupt signals from port A
    wire            int_port_b;                                                     // the interrupt signals from port B
    wire            int_port_c;                                                     // the interrupt signals from port C
    wire            int_port_d;                                                     // the interrupt signals from port D

    //--------------------------------------------------------------------------
    // registers
    //--------------------------------------------------------------------------
    reg     [31:0]  gpio_data_reg_i;
    reg     [31:0]  gpio_data_reg_o;
    reg     [31:0]  gpio_dd;
    reg     [31:0]  gpio_ie;
    reg     [31:0]  gpio_ep;

    //--------------------------------------------------------------------------
    // Assignment
    //--------------------------------------------------------------------------
    assign enable_write = gpio_enable & gpio_wr != 4'b0000;                         // Enable if Valid operation, and write at least one byte
    assign enable_read  = (gpio_enable | gpio_ready) & gpio_wr == 4'b0000;

    assign int_port_a = |interrupt_signal[7:0];                                     // OR the signals
    assign int_port_b = |interrupt_signal[15:8];                                    // OR the signals
    assign int_port_c = |interrupt_signal[23:16];                                   // OR the signals
    assign int_port_d = |interrupt_signal[31:24];                                   // OR the signals

    //--------------------------------------------------------------------------
    // ACK generation
    // Assert the ready port each cycle, depending on the enable signal.
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_ready <= 1'b0;
        end
        else begin
            gpio_ready <= gpio_enable & (gpio_address < `GPIO_UA_OFFSET); // only if valid region
        end
    end

    //--------------------------------------------------------------------------
    // Get interrupt "edge"
    // The interrupt flag will raise only if, at least one pin is interrupt
    // enabled, and is configured as input.
    //--------------------------------------------------------------------------
    genvar i;
    generate
        for(i = 0; i < 32; i = i + 1) begin: gpio_interrupt_signal
            assign interrupt_signal[i] = ( (gpio_ep[i]) ? gpio_data_reg_i[i] : ~gpio_data_reg_i[i] ) & gpio_ie[i] & ~gpio_dd[i];
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Tri-state buffer
    //--------------------------------------------------------------------------
    generate
        for(i = 0; i < 32; i = i + 1) begin: gpio_tristate
            assign gpio_inout[i]       = (gpio_dd[i]) ? gpio_data_reg_o[i] : 1'bZ;            // If output: put data. Else, High-Z
            assign gpio_data_wire_i[i] = (gpio_dd[i]) ? gpio_data_reg_o[i] : gpio_inout[i];   // If output: read output register. Else, read pin
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Set data direction
    // After reset: all ports to input state (avoid "accidents")
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_dd <= 32'b0;
        end
        else if(enable_write & (gpio_address & `ADDR_CHECK) == `GPIO_DD_OFFSET) begin
            gpio_dd[7:0]   <= (gpio_wr[0]) ? gpio_data_i[7:0]   : gpio_dd[7:0];
            gpio_dd[15:8]  <= (gpio_wr[1]) ? gpio_data_i[15:8]  : gpio_dd[15:8];
            gpio_dd[23:16] <= (gpio_wr[2]) ? gpio_data_i[23:16] : gpio_dd[23:16];
            gpio_dd[31:24] <= (gpio_wr[3]) ? gpio_data_i[31:24] : gpio_dd[31:24];
        end
        else begin
            gpio_dd <= gpio_dd;
        end
    end

    //--------------------------------------------------------------------------
    // Set data output
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_data_reg_o <= 32'b0;
        end
        else if(enable_write & (gpio_address & `ADDR_CHECK) == `GPIO_PD_OFFSET) begin
            gpio_data_reg_o[7:0]   <= (gpio_wr[0]) ? gpio_data_i[7:0]   : gpio_data_reg_o[7:0];
            gpio_data_reg_o[15:8]  <= (gpio_wr[1]) ? gpio_data_i[15:8]  : gpio_data_reg_o[15:8];
            gpio_data_reg_o[23:16] <= (gpio_wr[2]) ? gpio_data_i[23:16] : gpio_data_reg_o[23:16];
            gpio_data_reg_o[31:24] <= (gpio_wr[3]) ? gpio_data_i[31:24] : gpio_data_reg_o[31:24];
        end
        else begin
            gpio_data_reg_o <= gpio_data_reg_o;
        end
    end

    //--------------------------------------------------------------------------
    // Set interrupt enable
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_ie <= 32'b0;
        end
        else if(enable_write & (gpio_address & `ADDR_CHECK) == `GPIO_IE_OFFSET) begin
            gpio_ie[7:0]   <= (gpio_wr[0]) ? gpio_data_i[7:0]   : gpio_ie[7:0];
            gpio_ie[15:8]  <= (gpio_wr[1]) ? gpio_data_i[15:8]  : gpio_ie[15:8];
            gpio_ie[23:16] <= (gpio_wr[2]) ? gpio_data_i[23:16] : gpio_ie[23:16];
            gpio_ie[31:24] <= (gpio_wr[3]) ? gpio_data_i[31:24] : gpio_ie[31:24];
        end
        else begin
            gpio_ie <= gpio_ie;
        end
    end

    //--------------------------------------------------------------------------
    // Set edge mode
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_ep <= 32'b0;
        end
        else if(enable_write & (gpio_address & `ADDR_CHECK) == `GPIO_IE_OFFSET) begin
            gpio_ep[7:0]   <= (gpio_wr[0]) ? gpio_data_i[7:0]   : gpio_ep[7:0];
            gpio_ep[15:8]  <= (gpio_wr[1]) ? gpio_data_i[15:8]  : gpio_ep[15:8];
            gpio_ep[23:16] <= (gpio_wr[2]) ? gpio_data_i[23:16] : gpio_ep[23:16];
            gpio_ep[31:24] <= (gpio_wr[3]) ? gpio_data_i[31:24] : gpio_ep[31:24];
        end
        else begin
            gpio_ep <= gpio_ep;
        end
    end

    //--------------------------------------------------------------------------
    // Set interrupt signal
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            gpio_interrupt <= 4'b0;
        end
        else if (enable_write & (gpio_address & `ADDR_CHECK) == `GPIO_IC_OFFSET) begin
            gpio_interrupt[0] <= (gpio_wr[0]) ? 1'b0 : gpio_interrupt[0];
            gpio_interrupt[1] <= (gpio_wr[1]) ? 1'b0 : gpio_interrupt[1];
            gpio_interrupt[2] <= (gpio_wr[2]) ? 1'b0 : gpio_interrupt[2];
            gpio_interrupt[3] <= (gpio_wr[3]) ? 1'b0 : gpio_interrupt[3];
        end
        else begin
            gpio_interrupt[0] <= (int_port_a) ? 1'b1 : gpio_interrupt[0];
            gpio_interrupt[1] <= (int_port_b) ? 1'b1 : gpio_interrupt[1];
            gpio_interrupt[2] <= (int_port_c) ? 1'b1 : gpio_interrupt[2];
            gpio_interrupt[3] <= (int_port_d) ? 1'b1 : gpio_interrupt[3];
        end
    end

    //--------------------------------------------------------------------------
    // Set data input
    // Just sample/register the input data
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            gpio_data_reg_i <= 32'b0;
        end
        else begin
            gpio_data_reg_i <= gpio_data_wire_i;
        end
    end

    //--------------------------------------------------------------------------
    // Read
    //--------------------------------------------------------------------------
    always @(*) begin
        if (enable_read) begin
            case (gpio_address & `ADDR_CHECK)
                `GPIO_PD_OFFSET : gpio_data_o <= gpio_data_reg_i;
                `GPIO_DD_OFFSET : gpio_data_o <= gpio_dd;
                `GPIO_IE_OFFSET : gpio_data_o <= gpio_ie;
                `GPIO_EP_OFFSET : gpio_data_o <= gpio_ep;
                `GPIO_IC_OFFSET : gpio_data_o <= 32'h0000_0000;
                default         : gpio_data_o <= 32'hDEAD_F00D;
            endcase
        end
        else begin
            gpio_data_o <= 32'hDEAD_B00B;
        end
    end
endmodule
