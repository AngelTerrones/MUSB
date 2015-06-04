//==================================================================================================
//  Filename      : musoc.v
//  Created On    : 2015-01-10 21:18:59
//  Last Modified : 2015-06-04 13:47:42
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Implementation of the SoC:
//                      - Core
//                      - XBAR
//                      - RAM
//                      - GPIO
//                      - UART/Bootloader
//==================================================================================================

module musoc#(
    parameter SIM_MODE          = "NONE",       // Simulation Mode. "SIM" = simulation. "NONE": synthesis mode.
    // Core configuration
    parameter ENABLE_HW_MULT    = 0,            // Implement the multiplier
    parameter ENABLE_HW_DIV     = 0,            // Implement the divider
    parameter ENABLE_HW_CLO_Z   = 0,            // Enable CLO/CLZ instructions
    // UARTboot
    parameter BUS_FREQ          = 50,           // Bus frequency
    // Memory
    parameter MEM_ADDR_WIDTH    = 12            // 16 KB/4 KW of internal memory
    )(
    input           clk,
    input           rst,
    output          halted,
    // GPIO
    input   [31:0]  gpio_i,
    output  [31:0]  gpio_o,
    output  [31:0]  gpio_oe,
    // UART
    input           uart_rx,
    output          uart_tx
    );

    //--------------------------------------------------------------------------
    // wires
    //--------------------------------------------------------------------------
    // master
    wire    [31:0]  master0_address;
    wire    [3:0]   master0_wr;
    wire            master0_enable;
    wire            master0_ready;
    wire            master0_error;

    wire    [31:0]  master1_address;
    wire    [31:0]  master1_data_i;
    wire    [3:0]   master1_wr;
    wire            master1_enable;
    wire            master1_ready;
    wire            master1_error;

    wire    [31:0]  master2_address;
    wire    [31:0]  master2_data_i;
    wire    [3:0]   master2_wr;
    wire            master2_enable;
    wire            master2_ready;
    wire            master2_error;          // unused (Bootloader)

    wire    [31:0]  master_data_o;

    // slaves
    wire    [31:0]  slave0_data_i;
    wire    [31:0]  slave1_data_i;
    wire    [31:0]  slave2_data_i;

    wire            slave0_enable;
    wire            slave1_enable;
    wire            slave2_enable;
    wire            slave0_ready;
    wire            slave1_ready;
    wire            slave2_ready;

    wire    [31:0]  slave_address;
    wire    [31:0]  slave_data_o;
    wire    [3:0]   slave_wr;

    wire    [31:0]  ms_address;
    wire    [31:0]  ms_data_oi;
    wire    [31:0]  ms_data_io;
    wire    [3:0]   ms_wr;
    wire            ms_enable;
    wire            ms_ready;
    wire            ms_error;

    wire    [3:0]   gpio_interrupt;
    wire            uart_rx_ready_int;
    wire            bootloader_reset_core;
    wire            rst_module;

    wire            clk_core;
    wire            clk_bus;

    //--------------------------------------------------------------------------
    // Clock frequency generator.
    //--------------------------------------------------------------------------
    clk_generator clock_manager(
        .clk_i    ( clk        ),
        .clk_core ( clk_core   ),
        .clk_bus  ( clk_bus    )
    );

    //--------------------------------------------------------------------------
    // Reset Manager
    // Hold reset for 8 cycles
    //--------------------------------------------------------------------------
    rst_generator  reset_manager(
        .clk    ( clk_core   ),
        .rst_i  ( rst        ),
        .rst_o  ( rst_module )
    );

    //--------------------------------------------------------------------------
    // MIPS CORE
    //--------------------------------------------------------------------------
    musb_core #(
        .ENABLE_HW_MULT  ( ENABLE_HW_MULT  ),
        .ENABLE_HW_DIV   ( ENABLE_HW_DIV   ),
        .ENABLE_HW_CLO_Z ( ENABLE_HW_CLO_Z )
        )
        musb_core0(/*AUTOINST*/
            .halted         ( halted                                   ),
            .iport_address  ( master0_address[31:0]                    ),
            .iport_wr       ( master0_wr[3:0]                          ),
            .iport_enable   ( master0_enable                           ),
            .dport_address  ( master1_address[31:0]                    ),
            .dport_data_o   ( master1_data_i[31:0]                     ),
            .dport_wr       ( master1_wr[3:0]                          ),
            .dport_enable   ( master1_enable                           ),
            .clk            ( clk_core                                 ),
            .rst_i          ( rst_module | bootloader_reset_core       ),
            .interrupts     ( {uart_rx_ready_int, gpio_interrupt[3:0]} ),
            .nmi            ( 1'b0                                     ),
            .iport_data_i   ( master_data_o[31:0]                      ),
            .iport_ready    ( master0_ready                            ),
            .iport_error    ( master0_error                            ),
            .dport_data_i   ( master_data_o[31:0]                      ),
            .dport_ready    ( master1_ready                            ),
            .dport_error    ( master1_error                            )
        );

    //--------------------------------------------------------------------------
    // XBAR
    //--------------------------------------------------------------------------
    arbiter #(
        .nmasters(3)
        )
        arbiter0(/*autoinst*/
            .clk                ( clk_bus                                                               ),
            .rst                ( rst_module                                                            ),
            .master_address     ( {master2_address[31:0], master1_address[31:0], master0_address[31:0]} ),
            .master_data_i      ( {master2_data_i[31:0], master1_data_i[31:0], 32'hDEAD_C0DE}           ),
            .master_wr          ( {master2_wr[3:0], master1_wr[3:0], master0_wr[3:0]}                   ),
            .master_enable      ( {master2_enable, master1_enable ,master0_enable}                      ),
            .master_data_o      ( master_data_o[31:0]                                                   ),
            .master_ready       ( {master2_ready, master1_ready, master0_ready}                         ),
            .master_error       ( {master2_error, master1_error, master0_error}                         ),
            .slave_data_i       ( ms_data_io[31:0]                                                      ),
            .slave_ready        ( ms_ready                                                              ),
            .slave_error        ( ms_error                                                              ),
            .slave_address      ( ms_address[31:0]                                                      ),
            .slave_data_o       ( ms_data_oi[31:0]                                                      ),
            .slave_wr           ( ms_wr[3:0]                                                            ),
            .slave_enable       ( ms_enable                                                             )
        );

    mux_switch #(
        .nslaves    (3),
        // Slaves
        // To generate the mask (easy way): (32'hFFFF_FFFF << N-bits).
        // TODO: find a way to get "N-bits" (non-magical way).
        //                UART           GPIO           Internal Memory
        //                3-bits         5-bits         (MEM_ADDR_WIDTH)-bits
        .MATCH_ADDR ({32'h1100_0000, 32'h1000_0000, 32'h0000_0000}),    // Adjust the mask to avoid address aliasing.
        .MATCH_MASK ({32'hFFFF_FFF8, 32'hFFFF_FFE0, 32'hFFFF_0000})     // Adjust the mask to avoid address aliasing.
        )
        mux_switch0(
            .clk                ( clk_bus                                                         ),
            .master_address     ( ms_address[31:0]                                                ),
            .master_data_i      ( ms_data_oi[31:0]                                                ),
            .master_wr          ( ms_wr[3:0]                                                      ),
            .master_enable      ( ms_enable                                                       ),
            .master_data_o      ( ms_data_io[31:0]                                                ),
            .master_ready       ( ms_ready                                                        ),
            .master_error       ( ms_error                                                        ),
            .slave_data_i       ( {slave2_data_i[31:0], slave1_data_i[31:0], slave0_data_i[31:0]} ),
            .slave_ready        ( {slave2_ready, slave1_ready, slave0_ready}                      ),
            .slave_address      ( slave_address[31:0]                                             ),
            .slave_data_o       ( slave_data_o[31:0]                                              ),
            .slave_wr           ( slave_wr[3:0]                                                   ),
            .slave_enable       ( {slave2_enable, slave1_enable, slave0_enable}                   )
        );

    //--------------------------------------------------------------------------
    // Internal memory
    //--------------------------------------------------------------------------
    memory #(
        .addr_size( MEM_ADDR_WIDTH )    // Memory size
        )
        memory0(
            .clk        ( clk_bus                            ),
            .rst        ( rst_module                         ),
            .a_addr     ( slave_address[2 +: MEM_ADDR_WIDTH] ),     // MEM_ADDR_WIDTH bits address.
            .a_din      ( slave_data_o[31:0]                 ),
            .a_wr       ( slave_wr[3:0]                      ),
            .a_enable   ( slave0_enable                      ),
            .a_dout     ( slave0_data_i[31:0]                ),
            .a_ready    ( slave0_ready                       ),
            .b_addr     (  ),   // DO NOT CONNECT
            .b_din      (  ),   // DO NOT CONNECT
            .b_wr       (  ),   // DO NOT CONNECT
            .b_enable   (  ),   // DO NOT CONNECT
            .b_dout     (  ),   // DO NOT CONNECT
            .b_ready    (  )    // DO NOT CONNECT
        );

    //--------------------------------------------------------------------------
    // I/O
    //--------------------------------------------------------------------------
    gpio gpio0(/*autoinst*/
        .gpio_o         ( gpio_o              ),
        .gpio_oe        ( gpio_oe             ),
        .gpio_data_o    ( slave1_data_i[31:0] ),
        .gpio_ready     ( slave1_ready        ),
        .gpio_interrupt ( gpio_interrupt[3:0] ),
        .clk            ( clk_bus             ),
        .rst            ( rst_module          ),
        .gpio_i         ( gpio_i              ),
        .gpio_address   ( slave_address[31:0] ),
        .gpio_data_i    ( slave_data_o[31:0]  ),
        .gpio_wr        ( slave_wr[3:0]       ),
        .gpio_enable    ( slave1_enable       )
    );

    uart_bootloader #(
        .SIM_MODE        ( SIM_MODE        ),   // Simulation Mode
        .BUS_FREQ        ( BUS_FREQ        )    // Bus frequency
        )
        uart_bootloader0(
            .clk                   ( clk_bus               ),
            .rst                   ( rst_module            ),
            .uart_address          ( slave_address[2:0]    ),
            .uart_data_i           ( slave_data_o[7:0]     ),
            .uart_wr               ( slave_wr[0]           ),
            .uart_enable           ( slave2_enable         ),
            .uart_data_o           ( slave2_data_i[31:0]   ),
            .uart_ready            ( slave2_ready          ),
            .boot_master_data_i    ( master_data_o[31:0]   ),
            .boot_master_ready     ( master2_ready         ),
            .boot_master_address   ( master2_address[31:0] ),
            .boot_master_data_o    ( master2_data_i[31:0]  ),
            .boot_master_wr        ( master2_wr[3:0]       ),
            .boot_master_enable    ( master2_enable        ),
            .uart_rx_ready_int     ( uart_rx_ready_int     ),   // unused.
            .uart_rx_full_int      (                       ),   // unused.
            .bootloader_reset_core ( bootloader_reset_core ),
            .uart_rx               ( uart_rx               ),
            .uart_tx               ( uart_tx               )
        );
endmodule
