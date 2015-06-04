//==================================================================================================
//  Filename      : musb_branch_unit.v
//  Created On    : 2014-09-27 20:14:58
//  Last Modified : 2015-06-04 11:25:07
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Branch detection.
//==================================================================================================

`include "musb_defines.v"

module musb_branch_unit(
    input       [5:0]   opcode,             // Instruction opcode
    input       [31:0]  id_pc_add4,         // Instruction address + 4
    input       [31:0]  id_data_rs,         // Data from R0
    input       [31:0]  id_data_rt,         // Data from R1
    input       [25:0]  op_imm26,           // imm21/Imm16
    output  reg [31:0]  pc_branch_address,  // Destination address
    output  reg         take_branch         // Valid branch
    );

    //--------------------------------------------------------------------------
    // Signal Declaration: wire
    //--------------------------------------------------------------------------
    wire            beq;
    wire            bne;
    wire            bgez;
    wire            bgtz;
    wire            blez;
    wire            bltz;
    wire    [31:0]  long_jump;
    wire    [31:0]  short_jump;
    wire    [5:0]   inst_function;
    wire    [4:0]   op_rt;

    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign beq           = id_data_rs == id_data_rt;
    assign bne           = ~beq;
    assign bgez          = ~bltz;
    assign bgtz          = ~bgez;
    assign blez          = bltz | ~(|id_data_rs);
    assign bltz          = id_data_rs[31];
    assign long_jump     = {id_pc_add4[31:28], op_imm26, 2'b00 };
    assign short_jump    = $signed(id_pc_add4) + $signed( { op_imm26[`MUSB_INSTR_IMM16], 2'b00 } );
    assign inst_function = op_imm26[`MUSB_INSTR_FUNCT];
    assign op_rt         = op_imm26[`MUSB_INSTR_RT];

    //--------------------------------------------------------------------------
    // Get branch address
    //--------------------------------------------------------------------------
    always @(*) begin
        case (opcode)
            `OP_BEQ         :   begin pc_branch_address <= short_jump; take_branch <= beq;  end
            `OP_BGTZ        :   begin pc_branch_address <= short_jump; take_branch <= bgtz; end
            `OP_BLEZ        :   begin pc_branch_address <= short_jump; take_branch <= blez; end
            `OP_BNE         :   begin pc_branch_address <= short_jump; take_branch <= bne;  end
            `OP_J           :   begin pc_branch_address <= long_jump;  take_branch <= 1'b1; end
            `OP_JAL         :   begin pc_branch_address <= long_jump;  take_branch <= 1'b1; end
            `OP_TYPE_REGIMM :   begin
                                    case (op_rt)
                                        `RT_OP_BGEZ             : begin pc_branch_address <= short_jump; take_branch <= bgez; end
                                        `RT_OP_BGEZAL           : begin pc_branch_address <= short_jump; take_branch <= bgez; end
                                        `RT_OP_BLTZ             : begin pc_branch_address <= short_jump; take_branch <= bltz; end
                                        `RT_OP_BLTZAL           : begin pc_branch_address <= short_jump; take_branch <= bltz; end
                                        default                 : begin pc_branch_address <= 32'bx;    take_branch <= 1'b0; end
                                    endcase
                                end
            `OP_TYPE_R      :   begin
                                    case(inst_function)
                                        `FUNCTION_OP_JALR : begin pc_branch_address <= id_data_rs; take_branch <= 1'b1; end
                                        `FUNCTION_OP_JR   : begin pc_branch_address <= id_data_rs; take_branch <= 1'b1; end
                                        default           : begin pc_branch_address <= 32'bx; take_branch <= 1'b0; end
                                    endcase
                                end
            default         :   begin pc_branch_address <= 32'bx; take_branch <= 1'b0;    end
        endcase
    end
endmodule
