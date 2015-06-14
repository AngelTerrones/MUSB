# MUSB Verilog HDL design files

Verilog HDL design files for the MUSB project: MIPS32-compliant processor, I/O peripherals and SoC (MUSoC).

## Directory Layout

```
Hardware
├── arbiter/       : Bus arbiter: N-masters, 1 slave.
├── clk_generator/ : System clock generator (simulation).
├── fifo/          : FIFO module.
├── gpio/          : GPIO module: 4 8-bit I/O ports.
├── include/       : Core definitions.
├── io_cell/       : Tri-state buffer.
├── memory/        : BRAM memory (simulation).
├── musb/          : Core implementation.
├── musoc/         : SoC implementation (simulation).
├── mux_switch/    : Bus multiplexer: 1-master, N slaves.
├── ram/           : Generic memory, for FIFO.
├── rst_generator/ : Reset generetor (debounce).
├── uart/          : UART + bootloader.
└── README.md
```
