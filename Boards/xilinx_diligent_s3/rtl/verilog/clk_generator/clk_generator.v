//==================================================================================================
//  Filename      : clk_generator.v
//  Created On    : 2015-02-07 21:17:35
//  Last Modified : 2015-05-28 09:59:41
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Generate the two main clocks:
//                  - Bus and peripherals.
//                  - Core. This clock is equal to Bus clock divided by 2.
//
//                  Target: Spartan XC3S200
//==================================================================================================

module clk_generator(
    input   clk_i,      // input clock
    output  clk_core,   // core clock
    output  clk_bus     // bus clock
    );

    //--------------------------------------------------------------------------
    // localparams
    //--------------------------------------------------------------------------
    localparam real    BASE_FREQ = 50.0;    // Input frequency in MHz
    localparam integer CLK_MULT  = 4;       // Frequency multiplier (FX)
    localparam integer CLK_DIV   = 2;       // Frequency divider (FX)
    localparam integer CLK_DV    = 2;       // Frequency divider (DV)

    //--------------------------------------------------------------------------
    // feedback only from CLK0 or CLK2X
    //--------------------------------------------------------------------------
    wire clk;
    wire dcm0_clk0_prebuf;
    wire dcm0_clk0;
    wire dcm0_clkfx_prebuf;
    wire dcm0_clkfx;
    wire dcm0_clkdv_prebuf;
    wire dcm0_clkdv;

    //--------------------------------------------------------------------------
    // Buffers
    //--------------------------------------------------------------------------
    // input clock
    IBUFG ibufg0(
        .I ( clk_i ),
        .O ( clk   )
        );

    // feedback
    BUFG dcm_clk0(
        .I ( dcm0_clk0_prebuf ),
        .O ( dcm0_clk0        )
        );

    // Bus clock
    BUFG dcm_clkfx(
        .I ( dcm0_clkfx_prebuf  ),
        .O ( dcm0_clkfx         )
        );

    // Core clock
    BUFG dcm_clkdv(
        .I ( dcm0_clkdv_prebuf  ),
        .O ( dcm0_clkdv         )
        );

    //--------------------------------------------------------------------------
    // assign
    //--------------------------------------------------------------------------+
    assign clk_core = dcm0_clkdv;
    assign clk_bus  = dcm0_clkfx;

    //--------------------------------------------------------------------------
    // Instantiate the DCM
    //--------------------------------------------------------------------------
    DCM #(
        .SIM_MODE              ( "SAFE"),                   // Simulation: "SAFE" vs. "FAST", see "Synthesis and Simulation Design Guide" for details
        .CLKDV_DIVIDE          ( CLK_DV),                   // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
        .CLKFX_DIVIDE          ( CLK_DIV),                  // Can be any integer from 1 to 32
        .CLKFX_MULTIPLY        ( CLK_MULT),                 // Can be any integer from 2 to 32
        .CLKIN_DIVIDE_BY_2     ( "FALSE"),                  // TRUE/FALSE to enable CLKIN divide by two feature
        .CLKIN_PERIOD          ( 1000.0/BASE_FREQ),         // Specify period of input clock
        .CLKOUT_PHASE_SHIFT    ( "NONE"),                   // Specify phase shift of NONE, FIXED or VARIABLE
        .CLK_FEEDBACK          ( "1X"),                     // Specify clock feedback of NONE, 1X or 2X
        .DESKEW_ADJUST         ( "SYSTEM_SYNCHRONOUS"),     // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
        .DFS_FREQUENCY_MODE    ( "LOW"),                    // HIGH or LOW frequency mode for frequency synthesis
        .DLL_FREQUENCY_MODE    ( "LOW"),                    // HIGH or LOW frequency mode for DLL
        .DUTY_CYCLE_CORRECTION ( "TRUE"),                   // Duty cycle correction, TRUE or FALSE
        .FACTORY_JF            ( 16'hC080),                 // FACTORY JF values
        .PHASE_SHIFT           ( 0),                        // Amount of fixed phase shift from -255 to 255
        .STARTUP_WAIT          ( "FALSE")                   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
    )
    DCM_CLKGEN_inst1(
        .CLK0       ( dcm0_clk0_prebuf  ),    // 0 degree DCM CLK output
        .CLK180     (                   ),    // 180 degree DCM CLK output
        .CLK270     (                   ),    // 270 degree DCM CLK output
        .CLK2X      (                   ),    // 2X DCM CLK output
        .CLK2X180   (                   ),    // 2X, 180 degree DCM CLK out
        .CLK90      (                   ),    // 90 degree DCM CLK output
        .CLKDV      ( dcm0_clkdv_prebuf ),    // Divided DCM CLK out (CLKDV_DIVIDE)
        .CLKFX      ( dcm0_clkfx_prebuf ),    // DCM CLK synthesis out (M/D)
        .CLKFX180   (                   ),    // 180 degree CLK synthesis out
        .LOCKED     (                   ),    // DCM LOCK status output
        .PSDONE     (                   ),    // Dynamic phase adjust done output
        .STATUS     (                   ),    // 8-bit DCM status bits output
        .CLKFB      ( dcm0_clk0         ),    // DCM clock feedback
        .CLKIN      ( clk               ),    // Clock input (from IBUFG, BUFG or DCM)
        .PSCLK      (                   ),    // Dynamic phase adjust clock input
        .PSEN       (                   ),    // Dynamic phase adjust enable input
        .PSINCDEC   (                   ),    // Dynamic phase adjust increment/decrement
        .RST        ( 1'b0              )     // DCM asynchronous reset input
    );
endmodule
