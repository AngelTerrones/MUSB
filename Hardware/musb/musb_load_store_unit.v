//==================================================================================================
//  Filename      : musb_load_store_unit.v
//  Created On    : 2014-09-29 20:35:18
//  Last Modified : 2015-06-04 10:12:55
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : Handle memory access, using a 4-way handshaking protocol:
//                  1.- Assert enable signal.
//                  2.- Ready goes high when data is available.
//                  3.- If Ready is high, enable signal goes low.
//                  4.- Next cycle, if enable is low, clear Ready signal.
//
//                  Time diagram:
//
//                  Clock Tick:   |  |  |  |  |  |  |  |  |  |  |
//                                 ______         ___
//                  Enable:     __|      |_______|   |______
//                                       __          __
//                  Ready:         _____|  |________|  |____
//==================================================================================================

`include "musb_defines.v"

 module musb_load_store_unit(
    input               clk,                    // Clock
    input               rst,                    // Reset
    // Instruction interface: LSU <-> CPU
    input       [31:0]  imem_address,           // Instruction address
    output  reg [31:0]  imem_data,              // Instruction data
    // MEM interface: LSU <-> CPU
    input       [31:0]  dmem_address,           // Data address
    input       [31:0]  dmem_data_i,            // Data to memory
    input               dmem_halfword,          // halfword access
    input               dmem_byte,              // byte access
    input               dmem_read,              // read data memory
    input               dmem_write,             // write data memory
    input               dmem_sign_extend,       // read data (byte/half) with sign extended
    output  reg [31:0]  dmem_data_o,            // data from memory
    // Instruction Port: LSU <-> MEM[instruction]
    input       [31:0]  iport_data_i,           // Data from memory
    input               iport_ready,            // memory is ready
    input               iport_error,            // Bus error
    output      [31:0]  iport_address,          // data address
    output      [3:0]   iport_wr,               // write = byte select, read = 0000,
    output              iport_enable,           // enable operation
    // Data Port : LSU <-> (MEM[data], I/O)
    input       [31:0]  dport_data_i,           // Data from memory
    input               dport_ready,            // memory is ready
    input               dport_error,            // Bus error
    output      [31:0]  dport_address,          // data address
    output      [31:0]  dport_data_o,           // data to memory
    output  reg [3:0]   dport_wr,               // write = byte select, read = 0000,
    output              dport_enable,           // enable operation
    // pipeline signals
    input               exception_ready,
    input               mem_kernel_mode,        // For exception logic
    input               mem_llsc,               // Atomic operation
    input               id_eret,                // for llsc1
    output              exc_address_if,         // panic
    output              exc_address_l_mem,      // panic
    output              exc_address_s_mem,      // panic
    output              imem_request_stall,     // long operation
    output              dmem_request_stall      // long operation
    );

    //--------------------------------------------------------------------------
    // wire and registers
    //--------------------------------------------------------------------------
    wire        exc_invalid_word_iaddress;      // Not word-aligned instructions address
    wire        exc_invalid_space_iaddress;     // try to access I/O space
    wire        exc_invalid_word_maddress;      // Not word-aligned data address
    wire        exc_invalid_half_maddress;      // Not halfword-aligned data address
    wire        exc_invalid_space_maddress;     // try to access kernel space
    wire        dmem_operation;                 // Read or Write?
    wire        data_word;                      // LW/SW operation

    wire        exc_invalid_maddress;
    wire        write_enable;
    wire        read_enable;

    reg  [29:0] llsc_address;
    reg         llsc_atomic;
    wire        llsc_mem_write_mask;

    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign exc_invalid_word_iaddress  = imem_address[1] | imem_address[0];                                              // Bits 0 and 1 must be zeros for word access
    assign exc_invalid_space_iaddress = 0;                                                                              // FIX: implement User/Kernel space. This implies using 2 memory regions

    assign exc_invalid_word_maddress  = (dmem_address[1] | dmem_address[0]) & data_word;                                // Word access. Bits 0 and 1 must be zeros
    assign exc_invalid_half_maddress  = dmem_address[0] & dmem_halfword;                                                // Halfword access. Bit 0 must be zero
    assign exc_invalid_space_maddress = ~mem_kernel_mode & (dmem_address < `MUSB_SEG_2_SPACE_LOW);                          // Can't access first 500 MB
    assign exc_invalid_maddress       = exc_invalid_space_maddress | exc_invalid_word_maddress | exc_invalid_half_maddress;

    assign exc_address_if             = exc_invalid_word_iaddress | exc_invalid_space_iaddress;                         // AdIF
    assign exc_address_l_mem          = dmem_read  & exc_invalid_maddress;                                              // AdEL
    assign exc_address_s_mem          = dmem_write & exc_invalid_maddress;                                              // AdES

    assign write_enable               = dmem_write & ~exc_invalid_maddress & ~llsc_mem_write_mask;                      // only if no exceptions
    assign read_enable                = dmem_read  & ~exc_invalid_maddress;                                             // only if no exceptions

    assign dmem_operation             = (write_enable ^ read_enable) | mem_llsc;                                        // exclusive operation (normal). In case of SC, enable the operation (it writes to memory, AND to GPR)
    assign data_word                  = ~(dmem_halfword | dmem_byte);                                                   // Only one. Change to XOR maybe?

    assign imem_request_stall         = iport_enable & ~dport_error;                                     // Memory access in progress
    assign dmem_request_stall         = dport_enable;                                                                   //

    assign iport_enable               = (rst) ? 1'b0 : ((~iport_ready & ~exception_ready) & ~iport_error);                // Abort in case of errors & exception in the pipe
    assign dport_enable               = ~dport_ready & dmem_operation & ~dport_error;                                   // dmem_operation takes exception into account

    //--------------------------------------------------------------------------
    // Load Linked and Store Conditional logic
    //--------------------------------------------------------------------------
    /*
        From XUM project:

        A 32-bit register keeps track of the address for atomic Load Linked / Store Conditional
        operations. This register can be updated during stalls since it is not visible to
        forward stages. It does not need to be flushed during exceptions, since ERET destroys
        the atomicity condition and there are no detrimental effects in an exception handler.

        The atomic condition is set with a Load Linked instruction, and cleared on an ERET
        instruction or when any store instruction writes to one or more bytes covered by
        the word address register. It does not update on a stall condition.

        The MIPS32 spec states that an ERET instruction between LL and SC will cause the
        atomicity condition to fail. This implementation uses the ERET signal from the ID
        stage, which means instruction sequences such as "LL SC" could appear to have an
        ERET instruction between them even though they don't. One way to fix this is to pass
        the ERET signal through the pipeline to the MEM stage. However, because of the nature
        of LL/SC operations (they occur in a loop which checks the result at each iteration),
        an ERET will normally never be inserted into the pipeline programmatically until the
        LL/SC sequence has completed (exceptions such as interrupts can still cause ERET, but
        they can still cause them in the LL SC sequence as well). In other words, by not passing
        ERET through the pipeline, the only possible effect is a performance penalty. Also this
        may be irrelevant since currently ERET stalls for forward stages which can cause exceptions,
        which includes LL and SC.
    */

    always @(posedge clk) begin
        llsc_address <= (rst) ? 30'b0 : ( (dmem_read && mem_llsc) ? dmem_address[31:2] : llsc_address );
    end

    always @(posedge clk) begin
        if (rst) begin
            llsc_atomic <= 1'b0;
        end
        else if (dmem_read) begin
            llsc_atomic <= (mem_llsc) ? 1'b1 : llsc_atomic;
        end
        else if (id_eret | (~dmem_request_stall & dmem_write & (dmem_address[31:2] == llsc_address))) begin                // take into account IF stall??
            llsc_atomic <= 1'b0;
        end
        else begin
            llsc_atomic <= llsc_atomic;
        end
    end

    assign llsc_mem_write_mask = (mem_llsc & dmem_write & (~llsc_atomic | (dmem_address[31:2] != llsc_address)));           // If atomic and using the same address: enable the write. Else, ignore.

    //--------------------------------------------------------------------------
    // Map address and I/O ports
    //--------------------------------------------------------------------------
    assign iport_address = imem_address[31:0];                                                                          // full assign
    assign dport_address = dmem_address[31:0];                                                                          // full assign

    //--------------------------------------------------------------------------
    // Read instruction memory
    //--------------------------------------------------------------------------
    assign iport_wr     = 4'b0000;                                                                                      // DO NOT WRITE
    always @(*) begin
        imem_data <= iport_data_i;                                                                                      // simple
    end

    //--------------------------------------------------------------------------
    // Read from data data port.
    //--------------------------------------------------------------------------
    always @(*) begin
        if (dmem_byte) begin
            case (dmem_address[1:0])
                2'b00   : dmem_data_o <= (dmem_sign_extend) ? { {24{dport_data_i[7]} },  dport_data_i[7:0] }   : {24'b0, dport_data_i[7:0]};
                2'b01   : dmem_data_o <= (dmem_sign_extend) ? { {24{dport_data_i[15]} }, dport_data_i[15:8] }  : {24'b0, dport_data_i[15:8]};
                2'b10   : dmem_data_o <= (dmem_sign_extend) ? { {24{dport_data_i[23]} }, dport_data_i[23:16] } : {24'b0, dport_data_i[23:16]};
                2'b11   : dmem_data_o <= (dmem_sign_extend) ? { {24{dport_data_i[31]} }, dport_data_i[31:24] } : {24'b0, dport_data_i[31:24]};
                default : dmem_data_o <= 32'hx;
            endcase
        end
        else if (dmem_halfword) begin
            case (dmem_address[1])
                1'b0    : dmem_data_o <= (dmem_sign_extend) ? { {16{dport_data_i[15]} }, dport_data_i[15:0] }   : {16'b0, dport_data_i[15:0]};
                1'b1    : dmem_data_o <= (dmem_sign_extend) ? { {16{dport_data_i[31]} }, dport_data_i[31:16] }  : {16'b0, dport_data_i[31:16]};
                default : dmem_data_o <= 32'hx;
            endcase
        end
        else if (mem_llsc & dmem_write) begin
            dmem_data_o <= (llsc_atomic & (dmem_address[31:2] == llsc_address)) ? 32'h0000_0001 : 32'h0000_0000;
        end
        else begin
            dmem_data_o <= dport_data_i;
        end
    end

    //--------------------------------------------------------------------------
    // Write to data port
    // Format data:
    // byte : {b, b, b, b}
    // half : {h, h}
    // word : {w}
    //
    // Modify to implement Reverse Endian
    //--------------------------------------------------------------------------
    always @(*) begin
        dport_wr <= 4'b0000;
        if (write_enable) begin
             dport_wr[3] <= (dmem_byte & (dmem_address[1:0] == 2'b11)) | (dmem_halfword & dmem_address[1])  | data_word;
             dport_wr[2] <= (dmem_byte & (dmem_address[1:0] == 2'b10)) | (dmem_halfword & dmem_address[1])  | data_word;
             dport_wr[1] <= (dmem_byte & (dmem_address[1:0] == 2'b01)) | (dmem_halfword & ~dmem_address[1]) | data_word;
             dport_wr[0] <= (dmem_byte & (dmem_address[1:0] == 2'b00)) | (dmem_halfword & ~dmem_address[1]) | data_word;
        end
    end

    assign dport_data_o[31:24] = (dmem_byte)                 ? dmem_data_i[7:0] : ((dmem_halfword) ? dmem_data_i[15:8] : dmem_data_i[31:24]);
    assign dport_data_o[23:16] = (dmem_byte | dmem_halfword) ? dmem_data_i[7:0]                                        : dmem_data_i[23:16];
    assign dport_data_o[15:8]  = (dmem_byte)                 ? dmem_data_i[7:0]                                        : dmem_data_i[15:8];
    assign dport_data_o[7:0]   =                                                                                         dmem_data_i[7:0];
 endmodule
