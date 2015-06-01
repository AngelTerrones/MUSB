# MUSB Verilog HDL design files

Verilog HDL design files for the MUSB project: MIPS32-compliant processor, I/O peripherals and SoC (MUSoC).

## Directory Layout

```
Hardware
├── arbiter/        : N-Masters, 1-Slave arbiter.
├── clk_generator/  : Clock generation.
├── fifo/           : FIFO module.
├── gpio/           : General Purpose Input Output, 4 x 8-bits module, with edge detection (interrupt).
├── include/        : Opcodes and processor configuration.
├── mem/            : Internal memory for synthesis.
├── musb/           : The RTL files for the processor.
├── musoc/          : SoC implementation (top file).
├── mux_switch/     : 1-Master, N-Slaves bus multiplexer.
├── ram/            : RAM memory
├── rst_generator/  : Reset generator.
├── uart/           : 115200 baud, 8-N-1. Includes a hardware bootloader.
└── README.md
```
