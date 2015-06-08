//==================================================================================================
//  Filename      : musb_hazard_unit.v
//  Created On    : 2014-09-26 20:26:08
//  Last Modified : 2015-06-08 12:02:56
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Hazard detection and pipeline control unit
//                  No MEM exception stall: using LSU signal to avoid loops
//==================================================================================================

`include "musb_defines.v"

module musb_hazard_unit(
    input   [4:0]   id_rs,                  // Rs @ ID stage
    input   [4:0]   id_rt,                  // Rt @ ID stage
    input   [4:0]   ex_rs,                  // Rs @ EX stage
    input   [4:0]   ex_rt,                  // Rt @ EX stage
    input           id_mtc0,                // mtc0 instruction
    input   [4:0]   ex_gpr_wa,              // Write Address @ EX stage
    input   [4:0]   mem_gpr_wa,             // Write Address @ MEM stage
    input   [4:0]   wb_gpr_wa,              // Write Address @ WB stage
    input           id_branch,              // Branch signal
    input           id_jump,                // Branch signal
    input           ex_mem_to_gpr,          // Selector: MEM -> GPR @ EX
    input           mem_mem_to_gpr,         // Selector: MEM -> GPR @ MEM
    input           ex_gpr_we,              // GPR write enable @ EX
    input           mem_gpr_we,             // GPR write enable @ MEM
    input           wb_gpr_we,              // GPR write enable @ WB
    input           ex_request_stall,       // Ex unit request a stall
    input           dmem_request_stall,     // LSU: stall for Data access
    input           imem_request_stall,     // LSU: stall for Instruction Fetch
    input           if_exception_stall,     // Stall waiting for possible exception
    input           id_exception_stall,     // Stall waiting for possible exception
    input           ex_exception_stall,     // Stall waiting for possible exception
    input           mem_exception_stall,    //
    output  [1:0]   forward_id_rs,          // Forwarding Rs multiplexer: Selector @ ID
    output  [1:0]   forward_id_rt,          // Forwarding Rt multiplexer: Selector @ ID
    output  [1:0]   forward_ex_rs,          // Forwarding Rs multiplexer: Selector @ EX
    output  [1:0]   forward_ex_rt,          // Forwarding Rt multiplexer: Selector @ EX
    output          if_stall,               // Stall pipeline register
    output          id_stall,               // Stall pipeline register
    output          ex_stall,               // Stall pipeline register
    output          ex_stall_unit,          // Stall the EX unit.
    output          mem_stall,              // Stall pipeline register
    output          wb_stall                // Stall pipeline register
    );

    //--------------------------------------------------------------------------
    // Signal Declaration: wire
    //--------------------------------------------------------------------------
    // no forwarding if reading register zero
    wire id_rs_is_zero;
    wire id_rt_is_zero;
    wire ex_rs_is_zero;
    wire ex_rt_is_zero;
    // verify match: register address and write address (EX, MEM & WB)
    wire id_ex_rt_match_mtc0;
    wire id_ex_rt_match;
    wire id_ex_rs_match;
    wire id_mem_rs_match;
    wire id_mem_rt_match;
    wire id_wb_rs_match;
    wire id_wb_rt_match;
    wire ex_mem_rs_match;
    wire ex_mem_rt_match;
    wire ex_wb_rs_match;
    wire ex_wb_rt_match;
    // stall signals
    wire stall_id_rs_mtc0;
    wire stall_id_rs_rt_load_ex;
    wire stall_id_rs_rt_branch;
    wire stall_id_rs_rt_load_mem;
    wire stall_ex_rs_rt_load_mem;

    // forward signals
    wire forward_mem_id_rs;
    wire forward_mem_id_rt;
    wire forward_wb_id_rs;
    wire forward_wb_id_rt;
    wire forward_mem_ex_rs;
    wire forward_mem_ex_rt;
    wire forward_wb_ex_rs;
    wire forward_wb_ex_rt;

    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign id_rs_is_zero        = ~(|id_rs); // check if zero
    assign id_rt_is_zero        = ~(|id_rt); // check if zero
    assign ex_rs_is_zero        = ~(|ex_rs); // check if zero
    assign ex_rt_is_zero        = ~(|ex_rt); // check if zero

    assign id_ex_rt_match_mtc0  = (~id_rt_is_zero) & (id_rt == ex_gpr_wa)  & id_mtc0;           // Match register
    assign id_ex_rs_match       = (~id_rs_is_zero) & (id_rs == ex_gpr_wa)  & ex_gpr_we;         // Match registers
    assign id_ex_rt_match       = (~id_rt_is_zero) & (id_rt == ex_gpr_wa)  & ex_gpr_we;         // Match registers
    assign id_mem_rs_match      = (~id_rs_is_zero) & (id_rs == mem_gpr_wa) & mem_gpr_we;        // Match registers
    assign id_mem_rt_match      = (~id_rt_is_zero) & (id_rt == mem_gpr_wa) & mem_gpr_we;        // Match registers
    assign id_wb_rs_match       = (~id_rs_is_zero) & (id_rs == wb_gpr_wa)  & wb_gpr_we;         // Match registers
    assign id_wb_rt_match       = (~id_rt_is_zero) & (id_rt == wb_gpr_wa)  & wb_gpr_we;         // Match registers
    assign ex_mem_rs_match      = (~ex_rs_is_zero) & (ex_rs == mem_gpr_wa) & mem_gpr_we;        // Match registers
    assign ex_mem_rt_match      = (~ex_rt_is_zero) & (ex_rt == mem_gpr_wa) & mem_gpr_we;        // Match registers
    assign ex_wb_rs_match       = (~ex_rs_is_zero) & (ex_rs == wb_gpr_wa)  & wb_gpr_we;         // Match registers
    assign ex_wb_rt_match       = (~ex_rt_is_zero) & (ex_rt == wb_gpr_wa)  & wb_gpr_we;         // Match registers

    assign stall_id_rs_mtc0        = id_ex_rt_match_mtc0;
    assign stall_id_rs_rt_load_ex  = (id_ex_rs_match  | id_ex_rt_match)  & ex_mem_to_gpr  & id_branch;
    assign stall_id_rs_rt_branch   = (id_ex_rs_match  | id_ex_rt_match)  & id_branch;
    assign stall_id_rs_rt_load_mem = (id_mem_rs_match | id_mem_rt_match) & mem_mem_to_gpr;
    assign stall_ex_rs_rt_load_mem = (ex_mem_rs_match | ex_mem_rt_match) & mem_mem_to_gpr;

    assign forward_mem_id_rs    = id_mem_rs_match & (~mem_mem_to_gpr);                          // No forward if instruction at MEM stage is a Load instruction
    assign forward_mem_id_rt    = id_mem_rt_match & (~mem_mem_to_gpr);                          // No forward if instruction at MEM stage is a Load instruction
    assign forward_wb_id_rs     = id_wb_rs_match;
    assign forward_wb_id_rt     = id_wb_rt_match;
    assign forward_mem_ex_rs    = ex_mem_rs_match & (~mem_mem_to_gpr);                          // No forward if instruction at MEM stage is a Load instruction
    assign forward_mem_ex_rt    = ex_mem_rt_match & (~mem_mem_to_gpr);                          // No forward if instruction at MEM stage is a Load instruction
    assign forward_wb_ex_rs     = ex_wb_rs_match;
    assign forward_wb_ex_rt     = ex_wb_rt_match;

    //--------------------------------------------------------------------------
    // Assign stall signals
    //--------------------------------------------------------------------------
    assign wb_stall         = mem_stall;
    assign mem_stall        = dmem_request_stall | mem_exception_stall;
    assign ex_stall_unit    = mem_stall | stall_ex_rs_rt_load_mem | ex_exception_stall;
    assign ex_stall         = ex_stall_unit | ex_request_stall;
    assign id_stall         = ex_stall  | stall_id_rs_mtc0 | stall_id_rs_rt_load_ex | stall_id_rs_rt_branch | stall_id_rs_rt_load_mem |
                              id_exception_stall | (if_stall & (id_branch | id_jump));
    assign if_stall         = imem_request_stall | if_exception_stall;                 // No id_stall to avoid loops

    //--------------------------------------------------------------------------
    // forwarding control signals
    //--------------------------------------------------------------------------
    // sel | ID stage           | EX stage
    //--------------------------------------------------------------------------
    // 00 -> ID (no forwarding) | EX (no forwarding)
    // 01 -> MEM                | MEM
    // 10 -> WB                 | WB
    // 11 -> don't care         | don't care
    //--------------------------------------------------------------------------
    assign forward_id_rs = (forward_mem_id_rs) ? 2'b01 : ((forward_wb_id_rs) ? 2'b10 : 2'b00);
    assign forward_id_rt = (forward_mem_id_rt) ? 2'b01 : ((forward_wb_id_rt) ? 2'b10 : 2'b00);
    assign forward_ex_rs = (forward_mem_ex_rs) ? 2'b01 : ((forward_wb_ex_rs) ? 2'b10 : 2'b00);
    assign forward_ex_rt = (forward_mem_ex_rt) ? 2'b01 : ((forward_wb_ex_rt) ? 2'b10 : 2'b00);
endmodule
