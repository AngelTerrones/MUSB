//==================================================================================================
//  Filename      : tb_soc.v
//  Created On    : 2015-05-31 20:25:47
//  Last Modified : 2015-06-09 16:12:52
//  Revision      : 0.1
//  Author        : Ángel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : SoC testbench (ISIM)
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
    wire            halted;
    wire    [7:0]   LED;
    wire            uart_tx;
    wire            uart_rx;
    //--------------------------------------------------------------------------
    // Registers
    //--------------------------------------------------------------------------
    reg             rst;
    reg             clk_bus;

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
            .LED          ( LED                ),
            .SW           (  ),
            .BTN          (  ),
            .ROTCTR       (  ),
            .LCDE         (  ),
            .LCDRS        (  ),
            .LCDRW        (  ),
            .LCDDAT       (  ),
            .PPORTA       (  ),
            .PPORTB       (  ),
            .uart_rx      ( uart_rx            ),
            .uart_tx      ( uart_tx            )
            );

    initial begin
        rst <= 1'b1;
        clk_bus <= 1'b0;
        #(2000)
        rst <= 1'b0;
    end

    always  begin
        #(`cycle/1) clk_bus <= !clk_bus;        // Bus clock = 2*Core clock
    end
endmodule
