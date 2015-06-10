//==================================================================================================
//  Filename      : uart_bootloader.v
//  Created On    : 2015-01-09 22:32:46
//  Last Modified : 2015-06-10 15:21:20
//  Revision      : 1.0
//  Author        : Angel Terrones
//  Company       : Universidad Simón Bolívar
//  Email         : aterrones@usb.ve
//
//  Description   : A RS232 compatible UART, with a bootloader
//                  Based on the Rx module from XUM project.
//                  Author: Grant Ayers (ayers@cs.utah.edu)
//
//                  MUSB Boot Protocol Description:
//                  ------------------------------
//                  The protocol is over a COM (serial) port, 115200 bauds, 8N1, no parity.
//
//                  1. At reset, the target/bootloader sends "USB". The Master Reset is asserted by this module.
//                  2. The programmer/uploader sends "ACK" token, starting the boot protocol, with timeout of 1 second.
//                     After 1 second, it will release the Master Reset, and enter Slave Mode.
//                  3. The programmer/uploader sends the size, in words, of the bin file, minus 1.
//                     This size is 18-bits (3 bytes). The size is sent from low-order to high-order bytes (Little-Endian).
//                  4. The target responds with "KCA", to acknowledge the size.
//                  5. The programmer/uploader sends the bin file (data).
//                  6. The target sends "ACK"
//                  7. The target boots from memory
//
//                  Slave UART. Register address:
//                  ----------------------------
//                  Rx buffer   = 0x00            | Same address
//                  Tx buffer   = 0x00            | Same address
//                  Tx count    = 0x01 & 0x02     | Counter = [0, 2^FIFO_ADDR_WIDTH], so it needs 2 bytes (maximum)
//                  Rx count    = 0x03 & 0x04     | Counter = [0, 2^FIFO_ADDR_WIDTH], so it needs 2 bytes (maximum)
//
//                  Tx and Rx use independent FIFO buffers (Default implementation: 256 bytes each one)
//==================================================================================================

module uart_bootloader#(
    parameter SIM_MODE        = "NONE",         // Simulation Mode. "SIM" = simulation. "NONE" = Abort protocol.
    parameter BUS_FREQ        = 100.0           // Bus frequency
    )(
    input             clk,
    input             rst,
    // Bus I/O (uart)
    input      [2:0]  uart_address,             // Address
    input      [7:0]  uart_data_i,              // Data from bus
    input             uart_wr,                  // Byte select
    input             uart_enable,              // Enable operation
    output reg [31:0] uart_data_o,              // Data to bus
    output reg        uart_ready,               // Ready operation
    // Master I/O (Bootloader)
    input      [31:0] boot_master_data_i,       // Data from memory
    input             boot_master_ready,        // memory is ready
    output reg [31:0] boot_master_address,      // data address
    output reg [31:0] boot_master_data_o,       // data to memory
    output     [3:0]  boot_master_wr,           // write = byte select, read = 0000,
    output            boot_master_enable,       // enable operation
    // Interrupt: Data available in Rx fifo
    output            uart_rx_ready_int,        // Data available
    output            uart_rx_full_int,         // Rx Buffer full (kind of useless)
    // Internal
    output            bootloader_reset_core,    // In boot-loader mode, reset core
    // Off chip I/O
    input             uart_rx,                  // Rx pin
    output            uart_tx                   // Tx pin
    );

    //--------------------------------------------------------------------------
    // Localparams
    //--------------------------------------------------------------------------
    // FIFO
    localparam FIFO_ADDR_WIDTH = 10;   // 1024 bytes (Rx & Tx. Total: 512)

    // state
    localparam [4:0] IDLE      = 0;   // Waiting
    localparam [4:0] INIT1     = 1;   // Send header: U
    localparam [4:0] INIT2     = 2;   // Send header: S
    localparam [4:0] INIT3     = 3;   // Send header: B
    localparam [4:0] ACK1      = 4;   // Wait for ACK: A
    localparam [4:0] ACK2      = 5;   // Wait for ACK: C
    localparam [4:0] ACK3      = 6;   // Wait for ACK: K
    localparam [4:0] SIZE1     = 7;   // Wait for number of words: byte 1
    localparam [4:0] SIZE2     = 8;   // Wait for number of words: byte 2
    localparam [4:0] SIZE3     = 9;   // Wait for number of words: byte 3
    localparam [4:0] ACK4      = 10;  // Wait for ACK: A
    localparam [4:0] ACK5      = 11;  // Wait for ACK: C
    localparam [4:0] ACK6      = 12;  // Wait for ACK: K
    localparam [4:0] DATA1     = 13;  // Wait for data: byte 1
    localparam [4:0] DATA2     = 14;  // Wait for data: byte 2
    localparam [4:0] DATA3     = 15;  // Wait for data: byte 3
    localparam [4:0] DATA4     = 16;  // Wait for data: byte 4
    localparam [4:0] NEXTADD   = 17;  // Increment address
    localparam [4:0] ACK7      = 18;  // Wait for ACK: A
    localparam [4:0] ACK8      = 19;  // Wait for ACK: C
    localparam [4:0] ACK9      = 20;  // Wait for ACK: K
    localparam [4:0] DONE      = 21;  // Boot end
    localparam [4:0] END       = 22;  // Boot end

    // directions
    localparam [2:0] RX_TX_BUFFER   = 0;                                // base address: In/Out buffer
    localparam [2:0] TX_COUNT_L     = 1;                                // base address: Tx fifo count, low byte
    localparam [2:0] TX_COUNT_H     = 2;                                // base address: Tx fifo count, high byte
    localparam [2:0] RX_COUNT_L     = 3;                                // base address: Rx fifo count, low byte
    localparam [2:0] RX_COUNT_H     = 4;                                // base address: Rx fifo count, high byte
    localparam integer COUNT_RANGE  = BUS_FREQ*1000000;                 // Number of ticks for 1 second timeout (bootloader)
    localparam integer RANGE        = (COUNT_RANGE <= 1 << 1)  ? 1  :   // Get the minimum width for the timeout counter
                                      (COUNT_RANGE <= 1 << 2)  ? 2  :
                                      (COUNT_RANGE <= 1 << 3)  ? 3  :
                                      (COUNT_RANGE <= 1 << 4)  ? 4  :
                                      (COUNT_RANGE <= 1 << 5)  ? 5  :
                                      (COUNT_RANGE <= 1 << 6)  ? 6  :
                                      (COUNT_RANGE <= 1 << 7)  ? 7  :
                                      (COUNT_RANGE <= 1 << 8)  ? 8  :
                                      (COUNT_RANGE <= 1 << 9)  ? 9  :
                                      (COUNT_RANGE <= 1 << 10) ? 10 :
                                      (COUNT_RANGE <= 1 << 11) ? 11 :
                                      (COUNT_RANGE <= 1 << 12) ? 12 :
                                      (COUNT_RANGE <= 1 << 13) ? 13 :
                                      (COUNT_RANGE <= 1 << 14) ? 14 :
                                      (COUNT_RANGE <= 1 << 15) ? 15 :
                                      (COUNT_RANGE <= 1 << 16) ? 16 :
                                      (COUNT_RANGE <= 1 << 17) ? 17 :
                                      (COUNT_RANGE <= 1 << 18) ? 18 :
                                      (COUNT_RANGE <= 1 << 19) ? 19 :
                                      (COUNT_RANGE <= 1 << 20) ? 20 :
                                      (COUNT_RANGE <= 1 << 21) ? 21 :
                                      (COUNT_RANGE <= 1 << 22) ? 22 :
                                      (COUNT_RANGE <= 1 << 23) ? 23 :
                                      (COUNT_RANGE <= 1 << 24) ? 24 :
                                      (COUNT_RANGE <= 1 << 25) ? 25 :
                                      (COUNT_RANGE <= 1 << 26) ? 26 :
                                      (COUNT_RANGE <= 1 << 27) ? 27 :
                                      (COUNT_RANGE <= 1 << 28) ? 28 :
                                      (COUNT_RANGE <= 1 << 29) ? 29 : 30;

    //--------------------------------------------------------------------------
    // registers
    //--------------------------------------------------------------------------
    reg  [ 4:0]      state;
    reg  [17:0]      rx_count;               // Number of 32-bit words received (boot-loader)
    reg  [17:0]      rx_size;                // Number of 32-bit words to expect (boot-loader)
    reg  [7:0]       uart_data_i_reg;
    reg  [7:0]       tx_input_data;
    reg              uart_read_reg;
    reg              uart_write_reg;
    reg              uart_data_ready_reg;
    reg              enable_counter;
    reg              boot_rst;


    //--------------------------------------------------------------------------
    // wires
    //--------------------------------------------------------------------------
    wire [15:0] uart_tx_count;          // assume a size >= 256
    wire [15:0] uart_rx_count;          // assume a size >= 256
    wire [7:0]  uart_data_in;
    wire [7:0]  uart_data_out;
    wire        uart_write;
    wire        uart_read;
    wire        uart_data_ready;
    wire        tx_free;

    //--------------------------------------------------------------------------
    // assignments
    //--------------------------------------------------------------------------
    assign uart_data_in       = (bootloader_reset_core) ? uart_data_i_reg : tx_input_data;
    assign uart_write         = (bootloader_reset_core) ? uart_write_reg  : (uart_wr & uart_ready);
    assign uart_read          = (bootloader_reset_core) ? uart_read_reg   : (~uart_wr & uart_ready & (uart_address == RX_TX_BUFFER)); // Only if reading the buffer
    assign boot_master_wr     = (state == NEXTADD)      ? 4'b1111         : 4'b0000;
    assign boot_master_enable = (state == NEXTADD)      ? 1'b1            : 1'b0;

    //--------------------------------------------------------------------------
    // handle the counter to disable boot-loader mode
    // SIM_MODE == "NONE"
    //      Disable boot for 1 sec, waiting for boot
    // SIM_MODE == "SIM"
    //      Send USB, wait 256 cycles, enable boot
    //--------------------------------------------------------------------------
    generate
        if (SIM_MODE == "NONE") begin
            reg  [RANGE-1:0] bootloader_counter;     // Get 1 sec @ BUS_FREQ MHz.

            always @(posedge clk) begin
                bootloader_counter <= (rst | ~enable_counter) ? {RANGE{1'b0}} : ((bootloader_counter != COUNT_RANGE) ? bootloader_counter + 1'd1 : bootloader_counter);
            end
            assign bootloader_reset_core = boot_rst | (enable_counter & (bootloader_counter != COUNT_RANGE));
        end
        else if (SIM_MODE == "SIM") begin
            reg  [15:0] bootloader_counter;

            always @(posedge clk) begin
                bootloader_counter <= (rst | ~enable_counter) ? 16'h0000 : ((bootloader_counter != 16'h8000) ? bootloader_counter + 16'd1 : bootloader_counter); // simulation
            end
            assign bootloader_reset_core = boot_rst | (enable_counter & (bootloader_counter != 16'h8000));     // simulation
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Register the data_ready signal
    //--------------------------------------------------------------------------
    always @(posedge clk ) begin
        if (rst) begin
            uart_data_ready_reg <= 0;
        end
        else begin
            uart_data_ready_reg <= uart_data_ready & ~uart_data_ready_reg;
        end
    end

    //--------------------------------------------------------------------------
    // Next state logic
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE    : state <= (bootloader_reset_core) ?  INIT1 : IDLE;                                       // Initial state.
                INIT1   : state <= INIT2;                                                                         // Send U
                INIT2   : state <= INIT3;                                                                         // Send S
                INIT3   : state <= ACK1;                                                                          // Send B
                ACK1    : state <= (uart_data_ready_reg) ? ( (uart_data_out == 8'h41) ? ACK2  : IDLE ) : ((bootloader_reset_core) ? ACK1 : END);    // Receive A
                ACK2    : state <= (uart_data_ready_reg) ? ( (uart_data_out == 8'h43) ? ACK3  : IDLE ) : ACK2;                                      // Receive C
                ACK3    : state <= (uart_data_ready_reg) ? ( (uart_data_out == 8'h4B) ? SIZE1 : IDLE ) : ACK3;                                      // Receive K
                SIZE1   : state <= (uart_data_ready_reg) ? SIZE2 : SIZE1;
                SIZE2   : state <= (uart_data_ready_reg) ? SIZE3 : SIZE2;
                SIZE3   : state <= (uart_data_ready_reg) ? ACK4 : SIZE3;
                ACK4    : state <= ACK5;                                                                          // Send ACK
                ACK5    : state <= ACK6;                                                                          // Send ACK
                ACK6    : state <= DATA1;                                                                         // Send ACK
                DATA1   : state <= (uart_data_ready_reg) ? DATA2 : DATA1;
                DATA2   : state <= (uart_data_ready_reg) ? DATA3 : DATA2;
                DATA3   : state <= (uart_data_ready_reg) ? DATA4 : DATA3;
                DATA4   : state <= (uart_data_ready_reg) ? NEXTADD : DATA4;
                NEXTADD : state <= (boot_master_ready)   ? ((rx_count == rx_size) ? ACK7 : DATA1) : NEXTADD;
                ACK7    : state <= ACK8;                                                                          // Send ACK
                ACK8    : state <= ACK9;                                                                          // Send ACK
                ACK9    : state <= DONE;                                                                          // Send ACK
                DONE    : state <= (uart_tx_count == 0 & tx_free) ? END : DONE;                                  // Wait until Tx buffer is empty
                END     : state <= END;
                default : state <= IDLE;
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // output logic for bootloader
    //--------------------------------------------------------------------------
    always @(*) begin
        case(state)
            IDLE    : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            INIT1   : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h55; uart_write_reg <= 1'b1; enable_counter <= 1'b0; boot_rst <= 1'b1; end     // U
            INIT2   : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h53; uart_write_reg <= 1'b1; enable_counter <= 1'b0; boot_rst <= 1'b1; end     // S
            INIT3   : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h42; uart_write_reg <= 1'b1; enable_counter <= 1'b0; boot_rst <= 1'b1; end     // B
            ACK1    : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b1; boot_rst <= 1'b0; end
            ACK2    : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            ACK3    : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            SIZE1   : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            SIZE2   : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            SIZE3   : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            ACK4    : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h4B; uart_write_reg <= 1'b1; enable_counter <= 1'b0; boot_rst <= 1'b1; end     // K. Inverted for testing.
            ACK5    : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h43; uart_write_reg <= 1'b1; enable_counter <= 1'b0; boot_rst <= 1'b1; end     // C. Inverted for testing.
            ACK6    : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h41; uart_write_reg <= 1'b1; enable_counter <= 1'b0; boot_rst <= 1'b1; end     // A. Inverted for testing.
            DATA1   : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            DATA2   : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            DATA3   : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            DATA4   : begin uart_read_reg <= uart_data_ready_reg; uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            NEXTADD : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            ACK7    : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h41; uart_write_reg <= 1'b1; enable_counter <= 1'b0; boot_rst <= 1'b1; end     // A
            ACK8    : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h43; uart_write_reg <= 1'b1; enable_counter <= 1'b0; boot_rst <= 1'b1; end     // C
            ACK9    : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h4B; uart_write_reg <= 1'b1; enable_counter <= 1'b0; boot_rst <= 1'b1; end     // K
            DONE    : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
            END     : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b0; end
            default : begin uart_read_reg <= 0;                   uart_data_i_reg <= 8'h00; uart_write_reg <= 1'b0; enable_counter <= 1'b0; boot_rst <= 1'b1; end
        endcase
    end

    //--------------------------------------------------------------------------
    // Handle data to master port
    //--------------------------------------------------------------------------
    // data
    always @(posedge clk) begin
        if (rst) begin
            boot_master_data_o <= 32'h0;
        end
        else begin
            boot_master_data_o[7:0]   <= (rst) ? 8'h00 : (((state == DATA1) & uart_data_ready) ? uart_data_out : boot_master_data_o[7:0]);
            boot_master_data_o[15:8]  <= (rst) ? 8'h00 : (((state == DATA2) & uart_data_ready) ? uart_data_out : boot_master_data_o[15:8]);
            boot_master_data_o[23:16] <= (rst) ? 8'h00 : (((state == DATA3) & uart_data_ready) ? uart_data_out : boot_master_data_o[23:16]);
            boot_master_data_o[31:24] <= (rst) ? 8'h00 : (((state == DATA4) & uart_data_ready) ? uart_data_out : boot_master_data_o[31:24]);
        end
    end
    // address
    always @(posedge clk) begin
        if (rst) begin
            boot_master_address <= 32'h0;
        end
        else if (state == NEXTADD & boot_master_ready) begin
            boot_master_address <= boot_master_address + 4;
        end
    end

    //--------------------------------------------------------------------------
    // Handle data count
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            rx_count <= 18'b0;
        end
        else begin
            rx_count <= (state == IDLE) ? 18'h00000 : (((state == NEXTADD) & boot_master_ready) ? rx_count + 18'b1 : rx_count);
        end
    end

    always @(posedge clk) begin
        rx_size[7:0]   <= (rst) ? 8'h00 : (((state == SIZE1) & uart_data_ready) ? uart_data_out[7:0] : rx_size[7:0]);
        rx_size[15:8]  <= (rst) ? 8'h00 : (((state == SIZE2) & uart_data_ready) ? uart_data_out[7:0] : rx_size[15:8]);
        rx_size[17:16] <= (rst) ? 2'b00 : (((state == SIZE3) & uart_data_ready) ? uart_data_out[1:0] : rx_size[17:16]);
    end

    //--------------------------------------------------------------------------
    // Handle R to this module (Slave mode)
    // Only if boot-loader mode == 0
    // The core reads words (ALWAYS), so we need to concatenate the registers.
    // Search for a better way to do this.
    //--------------------------------------------------------------------------
    assign uart_tx_count[15:FIFO_ADDR_WIDTH+1] = 0;  // clear the remaining bytes.
    assign uart_rx_count[15:FIFO_ADDR_WIDTH+1] = 0;  // clear the remaining bytes.

    always @(posedge clk) begin
        if (~uart_wr & uart_enable & ~bootloader_reset_core) begin
            case (uart_address[2])
                1'b0    : begin uart_data_o <= {uart_rx_count[7:0], uart_tx_count[15:0], uart_data_out}; uart_ready <= 1'b1; end
                1'b1    : begin uart_data_o <= {24'b0, uart_rx_count[15:8]};                             uart_ready <= 1'b1; end
                default : begin uart_data_o <= 32'hx;                                                    uart_ready <= 1'b1; end
            endcase
        end
        else if (uart_wr & uart_enable & ~bootloader_reset_core) begin
            case (uart_address)
                RX_TX_BUFFER : begin tx_input_data <= uart_data_i; uart_ready <= 1'b1; end
                default      : begin tx_input_data <= 8'hxx;       uart_ready <= 1'b1; end
            endcase
        end
        else begin
            tx_input_data <= 8'hxx;
            uart_data_o <= 32'hxx;
            uart_ready  <= 1'b0;
        end
    end

    //--------------------------------------------------------------------------
    // Instantiate modules
    //--------------------------------------------------------------------------
    uart_min #(
        .FIFO_ADDR_WIDTH (FIFO_ADDR_WIDTH),               // Address width.
        .BUS_FREQ        (BUS_FREQ)
        )
        uart(
        .clk                ( clk                         ),
        .rst                ( rst                         ),
        .write              ( uart_write                  ),
        .data_i             ( uart_data_in[7:0]           ),
        .read               ( uart_read                   ),
        .data_o             ( uart_data_out[7:0]          ),
        .data_ready         ( uart_data_ready             ),
        .rx_count           ( uart_rx_count[FIFO_ADDR_WIDTH:0] ),
        .tx_count           ( uart_tx_count[FIFO_ADDR_WIDTH:0] ),
        .tx_free            ( tx_free                     ),
        .uart_rx_ready_int  ( uart_rx_ready_int           ),
        .uart_rx_full_int   ( uart_rx_full_int            ),
        .uart_rx            ( uart_rx                     ),
        .uart_tx            ( uart_tx                     )
        );
endmodule
