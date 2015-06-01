//==================================================================================================
//  Filename      : musb_ifid_register.v
//  Created On    : 2014-09-27 20:34:54
//  Last Modified : 2015-05-31 13:04:30
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Pipeline register: IF -> ID
//==================================================================================================

module musb_ifid_register(
    input               clk,                // main clock
    input               rst,                // main reset
    input       [31:0]  if_instruction,     // Instruction from IF
    input       [31:0]  if_pc_add4,         // PC + 1 from IF
    input       [31:0]  if_pc,              // PC     from IF
    input               if_is_bds,          // This instruction is a BDS.
    input               if_flush,           // clean
    input               if_stall,           // Stall IF
    input               id_stall,           // Stall ID
    output  reg [31:0]  id_instruction,     // ID instruction
    output  reg [31:0]  id_pc_add4,         // PC + 1 to ID
    output  reg [31:0]  id_exception_pc,    // PC to ID
    output  reg         id_is_bds,          // Instruction is a BDS
    output  reg         id_is_flushed       // This instruction must be ignored
    );

    always @(posedge clk) begin
        id_instruction  <= (rst) ? 32'b0 : ((id_stall) ? id_instruction  : ((if_stall | if_flush) ? 32'b0 : if_instruction));
        id_pc_add4      <= (rst) ? 32'b0 : ((id_stall) ? id_pc_add4                                       : if_pc_add4);     // check this for if_stall
        id_exception_pc <= (rst) ? 32'b0 : ((id_stall) ? id_exception_pc                                  : if_pc);          // check this for if_stall
        id_is_bds       <= (rst) ? 1'b0  : ((id_stall) ? id_is_bds                                        : if_is_bds);
        id_is_flushed   <= (rst) ? 1'b0  : ((id_stall) ? id_is_flushed                                    : if_flush);
    end
endmodule
