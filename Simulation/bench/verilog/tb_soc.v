//==================================================================================================
//  Filename      : tb_soc.v
//  Created On    : 2015-05-31 20:25:47
//  Last Modified : 2015-06-02 14:27:25
//  Revision      : 0.1
//  Author        : Ángel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : SoC testbench
//
//
//==================================================================================================

`include "musb_defines.v"

`timescale 1ns / 100ps

`define cycle           20
`define MEM_ADDR_WIDTH  12

module tb_soc;
    //--------------------------------------------------------------------------
    // wires
    //--------------------------------------------------------------------------
    wire            clk_core;
    wire            clk_bus;
    wire            rst;
    wire            halted;
    wire    [31:0]  gpio_a_inout;
    wire            uart_tx;
    wire            uart_rx;

    //--------------------------------------------------------------------------
    // Assigns
    //--------------------------------------------------------------------------
    assign iport_error = 1'b0;          // No errors
    assign dport_error = 1'b0;          // No errors

    //--------------------------------------------------------------------------
    // SoC
    //--------------------------------------------------------------------------
    musoc #(
        .SIM_MODE        ( "SIM"     ),
        .ENABLE_HW_MULT  ( 1         ),
        .ENABLE_HW_DIV   ( 1         ),
        .ENABLE_HW_CLO_Z ( 1         ),
        .BUS_FREQ        ( 100       ),
        .MEM_ADDR_WIDTH  ( 12        )
        )
        soc(
            .clk          ( clk_bus            ),
            .rst          ( rst                ),
            .halted       ( halted             ),
            .gpio_a_inout ( gpio_a_inout[31:0] ),
            .uart_rx      ( uart_rx            ),
            .uart_tx      ( uart_tx            )
            );

    //--------------------------------------------------------------------------
    // Monitor
    //--------------------------------------------------------------------------
    musb_monitor_soc monitor0(
        .halt                ( halted                                          ),
        .if_stall            ( soc.musb_core0.if_stall                         ),
        .if_flush            ( soc.musb_core0.if_exception_flush               ),
        .id_stall            ( soc.musb_core0.id_stall                         ),
        .id_flush            ( soc.musb_core0.id_exception_flush               ),
        .ex_stall            ( soc.musb_core0.ex_stall                         ),
        .ex_flush            ( soc.musb_core0.ex_exception_flush               ),
        .mem_stall           ( soc.musb_core0.mem_stall                        ),
        .mem_flush           ( soc.musb_core0.mem_exception_flush              ),
        .wb_stall            ( soc.musb_core0.wb_stall                         ),
        .mem_exception_pc    ( soc.musb_core0.mem_exception_pc                 ),
        .id_instruction      ( soc.musb_core0.id_instruction                   ),
        .wb_gpr_wa           ( soc.musb_core0.wb_gpr_wa                        ),
        .wb_gpr_wd           ( soc.musb_core0.wb_gpr_wd                        ),
        .wb_gpr_we           ( soc.musb_core0.wb_gpr_we                        ),
        .mem_address         ( soc.musb_core0.mem_alu_result                   ),
        .mem_data            ( soc.musb_core0.mem_mem_store_data               ),
        .if_exception_ready  ( soc.musb_core0.musb_cpzero0.if_exception_ready  ),
        .id_exception_ready  ( soc.musb_core0.musb_cpzero0.id_exception_ready  ),
        .ex_exception_ready  ( soc.musb_core0.musb_cpzero0.ex_exception_ready  ),
        .mem_exception_ready ( soc.musb_core0.musb_cpzero0.mem_exception_ready ),
        .bootloader_rst      ( soc.bootloader_reset_core                       ),
        .monitor_rx          ( uart_tx                                         ),
        .monitor_tx          ( uart_rx                                         ),
        .clk_core            ( clk_core                                        ),
        .clk_bus             ( clk_bus                                         ),
        .rst                 ( rst                                             )
    );
endmodule
