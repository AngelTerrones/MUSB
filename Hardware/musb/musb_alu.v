//==================================================================================================
//  Filename      : musb_alu.v
//  Created On    : 2014-09-23 20:09:00
//  Last Modified : 2015-05-24 21:00:31
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : The Execution unit.
//                  Performs the following operations:
//                  - Arithmetic
//                  - Logical
//                  - Shift
//                  - Comparison
//==================================================================================================

`include "musb_defines.v"

module musb_alu#(
    parameter ENABLE_HW_MULT  = 1,          // Implement the multiplier
    parameter ENABLE_HW_DIV   = 1,          // Implement the divider
    parameter ENABLE_HW_CLO_Z = 1           // Implement the CLO/CLZ
    )(
    input               clk,                // clock
    input               rst,                // reset
    input       [31:0]  ex_alu_port_a,      // Operand
    input       [31:0]  ex_alu_port_b,      // Operand
    input       [4:0]   ex_alu_operation,   // ALU operation
    input               ex_stall,           // stall the execution stage
    input               ex_flush,           // flush the execution stage
    output              ex_request_stall,   // Executing a Div/Mult instruction
    output reg  [31:0]  ex_alu_result,      // Result
    output              ex_b_is_zero,       // for MOVN and MOVZ
    output reg          exc_overflow        // Overflow
    );

    //--------------------------------------------------------------------------
    // Signal Declaration: reg
    //--------------------------------------------------------------------------
    reg         [63:0]  hilo;               // hold the result from MULT instruction
    reg                 div_active;         // 1 if the divider is currently active.
    reg                 hilo_access;        // check access
    reg         [5:0]   clo_result;
    reg         [5:0]   clz_result;

    ///-------------------------------------------------------------------------
    // Signal Declaration: wire
    //--------------------------------------------------------------------------
    wire        [31:0]  A;                  // Port A (unsigned)
    wire        [31:0]  B;                  // Port B (unsigned)
    wire signed [31:0]  As;                 // Port A (signed)
    wire signed [61:0]  Bs;                 // Port B (signed)
    wire signed [31:0]  add_sub_result;     // A+B or A - B
    wire        [4:0]   operation;          // Operation
    wire        [63:0]  multx_result;       // Multiplication result
    wire        [31:0]  hi;                 // HILO[63:32]
    wire        [31:0]  lo;                 // HILO[31:0]
    wire        [31:0]  shift_result;       // Shift result
    wire        [31:0]  quotient;           // Division
    wire        [31:0]  remainder;          // Division
    wire                op_divs;            // Signed division
    wire                op_divu;            // Unsigned division
    wire                div_stall;          // Stall
    wire                enable_ex;          // Enable operations

    wire                op_mults;           // Signed multiplication
    wire                op_multu;           // Unsigned multiplication
    wire                mult_active;        // Mult operation active inside the pipeline
    wire                mult_ready;         // Mult result ready
    wire                mult_stall;


    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign A                 = ex_alu_port_a;                                                                           // unsigned
    assign B                 = ex_alu_port_b;                                                                           // unsigned
    assign As                = $signed(ex_alu_port_a);                                                                  // signed
    assign Bs                = $signed(ex_alu_port_b);                                                                  // signed
    assign operation         = ex_alu_operation;                                                                        // only to avoid renaming (e_e)
    assign ex_b_is_zero      = (B == 32'b0);
    assign add_sub_result    = ((operation == `ALU_OP_ADD) | (operation == `ALU_OP_ADDU)) ? (A + B) : (A - B);
    assign hi                = hilo[63:32];
    assign lo                = hilo[31:0];
    // enable mult/div if no stall or flush.
    assign enable_ex         = ~(ex_stall | ex_flush);
    // Do nothing if B == 0. A single pulse. Ignore if EX is stalled (MEM, exception or data dependency)
    assign op_divs           = (B != 32'd0) & (div_active == 1'b0) & (operation == `ALU_OP_DIV) & enable_ex;
    assign op_divu           = (B != 32'd0) & (div_active == 1'b0) & (operation == `ALU_OP_DIVU) & enable_ex;
    // A single pulse. Ignore if EX is stalled (MEM, exception or data dependency)
    assign op_mults          = (mult_active == 1'b0) & (operation == `ALU_OP_MULS) & enable_ex;
    assign op_multu          = (mult_active == 1'b0) & (operation == `ALU_OP_MULU) & enable_ex;
    // request stall if (divx or div active) or (multx | mult active)
    assign ex_request_stall  = ((op_divu | op_divs) | div_stall) | ((op_multu | op_mults) | (mult_active ^ mult_ready));

    assign mult_stall        = ex_stall;

    //--------------------------------------------------------------------------
    // the BIG multiplexer
    //--------------------------------------------------------------------------
    always @(*) begin
        case(operation)
            `ALU_OP_ADD     : ex_alu_result <= add_sub_result;
            `ALU_OP_ADDU    : ex_alu_result <= add_sub_result;
            `ALU_OP_SUB     : ex_alu_result <= add_sub_result;
            `ALU_OP_SUBU    : ex_alu_result <= add_sub_result;
            `ALU_OP_AND     : ex_alu_result <= A & B;
            `ALU_OP_CLO     : ex_alu_result <= {26'b0, clo_result};
            `ALU_OP_CLZ     : ex_alu_result <= {26'b0, clz_result};
            `ALU_OP_NOR     : ex_alu_result <= ~(A | B);
            `ALU_OP_OR      : ex_alu_result <= A | B;
            `ALU_OP_SLL     : ex_alu_result <= shift_result;
            `ALU_OP_SRA     : ex_alu_result <= shift_result;
            `ALU_OP_SRL     : ex_alu_result <= shift_result;
            `ALU_OP_XOR     : ex_alu_result <= A ^ B;
            `ALU_OP_MFHI    : ex_alu_result <= hi;
            `ALU_OP_MFLO    : ex_alu_result <= lo;
            `ALU_OP_SLT     : ex_alu_result <= As < Bs;
            `ALU_OP_SLTU    : ex_alu_result <= A < B;
            `ALU_OP_A       : ex_alu_result <= A;
            `ALU_OP_B       : ex_alu_result <= B;
            default         : ex_alu_result <= 32'bx;                                                                   // I don't BLOODY CARE.
        endcase
    end

    //--------------------------------------------------------------------------
    // Detect Overflow
    //--------------------------------------------------------------------------
    always @(*) begin
        case (operation)
            `ALU_OP_ADD : exc_overflow <= ((A[31] ~^ B[31]) & (A[31] ^ add_sub_result[31]));
            `ALU_OP_SUB : exc_overflow <= ((A[31]  ^ B[31]) & (A[31] ^ add_sub_result[31]));
            default     : exc_overflow <= 1'b0;
        endcase
    end

    //--------------------------------------------------------------------------
    // Write to HILO register
    // Div has priority over mult
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            hilo <= 64'h00000000_00000000;
        end
        else if ((div_stall == 1'b0) & (div_active == 1'b1)) begin
            hilo <= {remainder, quotient};
        end
        else if(enable_ex) begin
            case (operation)
                `ALU_OP_MULS    : hilo <= multx_result;
                `ALU_OP_MULU    : hilo <= multx_result;
                `ALU_OP_MADD    : hilo <= hilo + multx_result;
                `ALU_OP_MADDU   : hilo <= hilo + multx_result;
                `ALU_OP_MSUB    : hilo <= hilo - multx_result;
                `ALU_OP_MSUBU   : hilo <= hilo - multx_result;
                `ALU_OP_MTHI    : hilo <= {A, lo};
                `ALU_OP_MTLO    : hilo <= {hi, A};
                default         : hilo <= hilo;
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // determinate if the div unit is currently active
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            div_active <= 1'b0;
        end
        else begin
            case(div_active)
                1'd0 : div_active <= (op_divs || op_divu) ? 1'b1 : 1'b0;
                1'd1 : div_active <= (~div_stall) ? 1'b0 : 1'b1;
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // Detect access to HILO register
    //--------------------------------------------------------------------------
    always @(*) begin
        case (operation)
            `ALU_OP_DIV   : hilo_access <= 1'b1;
            `ALU_OP_DIVU  : hilo_access <= 1'b1;
            `ALU_OP_MULS  : hilo_access <= 1'b1;
            `ALU_OP_MULU  : hilo_access <= 1'b1;
            `ALU_OP_MADD  : hilo_access <= 1'b1;
            `ALU_OP_MADDU : hilo_access <= 1'b1;
            `ALU_OP_MSUB  : hilo_access <= 1'b1;
            `ALU_OP_MSUBU : hilo_access <= 1'b1;
            `ALU_OP_MTHI  : hilo_access <= 1'b1;
            `ALU_OP_MTLO  : hilo_access <= 1'b1;
            `ALU_OP_MFHI  : hilo_access <= 1'b1;
            `ALU_OP_MFLO  : hilo_access <= 1'b1;
            default       : hilo_access <= 1'b0;
        endcase
    end

    //--------------------------------------------------------------------------
    // Count Leading Ones/Zeros
    //--------------------------------------------------------------------------
    generate
        // Hardware CLO_CLZ
        if (ENABLE_HW_CLO_Z) begin
            //--------------------------------------------------------------------------
            // Count Leading Ones
            //--------------------------------------------------------------------------
            always @(A) begin
                casex (A)
                    32'b0xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd0;
                    32'b10xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd1;
                    32'b110x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd2;
                    32'b1110_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd3;
                    32'b1111_0xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd4;
                    32'b1111_10xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd5;
                    32'b1111_110x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd6;
                    32'b1111_1110_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd7;
                    32'b1111_1111_0xxx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd8;
                    32'b1111_1111_10xx_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd9;
                    32'b1111_1111_110x_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd10;
                    32'b1111_1111_1110_xxxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd11;
                    32'b1111_1111_1111_0xxx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd12;
                    32'b1111_1111_1111_10xx_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd13;
                    32'b1111_1111_1111_110x_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd14;
                    32'b1111_1111_1111_1110_xxxx_xxxx_xxxx_xxxx : clo_result <= 6'd15;
                    32'b1111_1111_1111_1111_0xxx_xxxx_xxxx_xxxx : clo_result <= 6'd16;
                    32'b1111_1111_1111_1111_10xx_xxxx_xxxx_xxxx : clo_result <= 6'd17;
                    32'b1111_1111_1111_1111_110x_xxxx_xxxx_xxxx : clo_result <= 6'd18;
                    32'b1111_1111_1111_1111_1110_xxxx_xxxx_xxxx : clo_result <= 6'd19;
                    32'b1111_1111_1111_1111_1111_0xxx_xxxx_xxxx : clo_result <= 6'd20;
                    32'b1111_1111_1111_1111_1111_10xx_xxxx_xxxx : clo_result <= 6'd21;
                    32'b1111_1111_1111_1111_1111_110x_xxxx_xxxx : clo_result <= 6'd22;
                    32'b1111_1111_1111_1111_1111_1110_xxxx_xxxx : clo_result <= 6'd23;
                    32'b1111_1111_1111_1111_1111_1111_0xxx_xxxx : clo_result <= 6'd24;
                    32'b1111_1111_1111_1111_1111_1111_10xx_xxxx : clo_result <= 6'd25;
                    32'b1111_1111_1111_1111_1111_1111_110x_xxxx : clo_result <= 6'd26;
                    32'b1111_1111_1111_1111_1111_1111_1110_xxxx : clo_result <= 6'd27;
                    32'b1111_1111_1111_1111_1111_1111_1111_0xxx : clo_result <= 6'd28;
                    32'b1111_1111_1111_1111_1111_1111_1111_10xx : clo_result <= 6'd29;
                    32'b1111_1111_1111_1111_1111_1111_1111_110x : clo_result <= 6'd30;
                    32'b1111_1111_1111_1111_1111_1111_1111_1110 : clo_result <= 6'd31;
                    32'b1111_1111_1111_1111_1111_1111_1111_1111 : clo_result <= 6'd32;
                    default : clo_result <= 6'd0;
                endcase
            end

            //--------------------------------------------------------------------------
            // Count Leading Zeros
            //--------------------------------------------------------------------------
            always @(A) begin
                casex (A)
                    32'b1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd0;
                    32'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd1;
                    32'b001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd2;
                    32'b0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd3;
                    32'b0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd4;
                    32'b0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd5;
                    32'b0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd6;
                    32'b0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd7;
                    32'b0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd8;
                    32'b0000_0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd9;
                    32'b0000_0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd10;
                    32'b0000_0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd11;
                    32'b0000_0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd12;
                    32'b0000_0000_0000_01xx_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd13;
                    32'b0000_0000_0000_001x_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd14;
                    32'b0000_0000_0000_0001_xxxx_xxxx_xxxx_xxxx : clz_result <= 6'd15;
                    32'b0000_0000_0000_0000_1xxx_xxxx_xxxx_xxxx : clz_result <= 6'd16;
                    32'b0000_0000_0000_0000_01xx_xxxx_xxxx_xxxx : clz_result <= 6'd17;
                    32'b0000_0000_0000_0000_001x_xxxx_xxxx_xxxx : clz_result <= 6'd18;
                    32'b0000_0000_0000_0000_0001_xxxx_xxxx_xxxx : clz_result <= 6'd19;
                    32'b0000_0000_0000_0000_0000_1xxx_xxxx_xxxx : clz_result <= 6'd20;
                    32'b0000_0000_0000_0000_0000_01xx_xxxx_xxxx : clz_result <= 6'd21;
                    32'b0000_0000_0000_0000_0000_001x_xxxx_xxxx : clz_result <= 6'd22;
                    32'b0000_0000_0000_0000_0000_0001_xxxx_xxxx : clz_result <= 6'd23;
                    32'b0000_0000_0000_0000_0000_0000_1xxx_xxxx : clz_result <= 6'd24;
                    32'b0000_0000_0000_0000_0000_0000_01xx_xxxx : clz_result <= 6'd25;
                    32'b0000_0000_0000_0000_0000_0000_001x_xxxx : clz_result <= 6'd26;
                    32'b0000_0000_0000_0000_0000_0000_0001_xxxx : clz_result <= 6'd27;
                    32'b0000_0000_0000_0000_0000_0000_0000_1xxx : clz_result <= 6'd28;
                    32'b0000_0000_0000_0000_0000_0000_0000_01xx : clz_result <= 6'd29;
                    32'b0000_0000_0000_0000_0000_0000_0000_001x : clz_result <= 6'd30;
                    32'b0000_0000_0000_0000_0000_0000_0000_0001 : clz_result <= 6'd31;
                    32'b0000_0000_0000_0000_0000_0000_0000_0000 : clz_result <= 6'd32;
                    default : clz_result <= 6'd0;
                endcase
            end
        end
        // Disable
        else begin
            always @(A) begin
                clo_result <= 6'd0;
                clz_result <= 6'b0;
            end
        end
    endgenerate


    //--------------------------------------------------------------------------
    // Shifter: instantiation
    //--------------------------------------------------------------------------
    musb_shifter shifter(
        .input_data     ( B                        ),
        .shamnt         ( A[4:0]                   ),
        .direction      ( operation == `ALU_OP_SLL ),
        .sign_extend    ( operation == `ALU_OP_SRA ),
        .shift_result   ( shift_result[31:0]       )
        );

    //--------------------------------------------------------------------------
    // 32 x 32 bits multiplier: instantiation
    //--------------------------------------------------------------------------
    generate
        // Hardware multiplier
        if (ENABLE_HW_MULT) begin
            musb_multiplier mult(
                .clk              ( clk                       ),
                .rst              ( rst                       ),
                .input_a          ( A[31:0]                   ),
                .input_b          ( B[31:0]                   ),
                .signed_operation ( operation == `ALU_OP_MULS ),
                .enable_op        ( op_mults  | op_multu      ),
                .stall            ( mult_stall                ),
                .flush            ( ex_flush                  ),
                .mult_result      ( multx_result[63:0]        ),
                .active           ( mult_active               ),
                .ready            ( mult_ready                )
                );
        end
        //  No hardware multiplier
        else begin
            assign multx_result = 64'b0;    // disabled
            assign mult_active  = 1'b0;     // disabled
            assign mult_ready   = 1'b0;     // disabled
        end
    endgenerate

    //--------------------------------------------------------------------------
    // instantiate the divider unit
    //--------------------------------------------------------------------------
    generate
        // Hardware divider
        if (ENABLE_HW_DIV) begin
            musb_div Divider(
                .clk       ( clk             ),
                .rst       ( rst             ),
                .op_divs   ( op_divs         ),
                .op_divu   ( op_divu         ),
                .dividend  ( A[31:0]         ),
                .divisor   ( B[31:0]         ),
                .quotient  ( quotient[31:0]  ),
                .remainder ( remainder[31:0] ),
                .stall     ( div_stall       )
                );
        end
        // No hardware divider
        else begin
            assign quotient  = 32'b0;   // disabled
            assign remainder = 32'b0;   // disabled
            assign div_stall = 1'b0;    // disabled
        end
    endgenerate
endmodule
