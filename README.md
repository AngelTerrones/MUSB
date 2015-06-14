![logo](https://github.com/AngelTerrones/MUSB/wiki/images/logo_musb.png)

Implementation of the MIPS32 release 1 processor.

Based on the [XUM project](https://github.com/grantea/mips32r1_xum) created by Grant Ayers
for the eXtensible Utah Multicore (XUM) project at the University of Utah.

## Processor Details

-  Single-issue in-order 6-stage pipeline with full forwarding and hazard detection.
-  Harvard architecture, with separate instruction and data ports.
-  A subset of the MIPS32 instruction set. Includes: hardware multiplication, hardware division, MAC/MAS, load
   linked / store conditional.
-  No MMU.
-  No FPU. Only software-base floating point support (toolchain).
-  Multi-cycle Hardware divider (Disabled by default).
-  Hardware multiplier (5-stages pipeline, disabled by default).
-  Hardware is Little-Endian. No support for reverse-endian mode.
-  Coprocessor 0 allows ISA-compliant interrupts, exceptions, and user/kernel modes.
-  No address space verification for the instruction port: code can be at any address.
-  Documentation in-source.
-  Vendor-independent code.

The project includes the standalone MIPS32 processor and a basic SoC design with GPIO and UART/hardware bootloader.
Tested in Xilinx Spartan-3 y Spartan-3e (Digilent) and Spartan-6 (XuLA2-LX25) boards.

## Peripherals (SoC)

-   GPIO module: 4 x 8-bits module, with edge detection (interrupt).
-   UART module: 115200 baud, 8-N-1.
-   BRAM internal memory.
-   Reset generator.
-   Clock manager.


## Getting Started

This repository provides all you need to simulate and synthesize the processor:

-   Standalone processor.
-   Hardware bootloader, using UART
-   Internal memory using BRAM (Vendor-independent code).
-   Scripts to simulate the processor and other modules.

## Software Details

-  Software toolchain based on Mentor Graphics Sourcery CodeBench Lite for MIPS ELF (easy way).
-  Demos written in assembly.

## Directory Layout

```
MUSB
├── Boards/
│   ├── xilinx_diligent_s3/  : SoC implementations for the Spartan-3 board.
│   └── xilinx_diligent_s3e/ : SoC implementations for the Spartan-3e board.
├── Documentation/
│   ├── src/                 : Source files (texinfo).
│   └── makefile
├── Hardware/
│   ├── arbiter/             : Bus arbiter: N-masters, 1 slave.
│   ├── clk_generator/       : System clock generator (simulation).
│   ├── fifo/                : FIFO module.
│   ├── gpio/                : GPIO module: 4 8-bit I/O ports.
│   ├── include/             : Core definitions.
│   ├── io_cell/             : Tri-state buffer.
│   ├── memory/              : BRAM memory (simulation).
│   ├── musb/                : Core implementation.
│   ├── musoc/               : SoC implementation (simulation).
│   ├── mux_switch/          : Bus multiplexer: 1-master, N slaves.
│   ├── ram/                 : Generic memory, for FIFO.
│   ├── rst_generator/       : Reset generetor (debounce).
│   ├── uart/                : UART + bootloader.
│   └── README.md
├── Simulation/
│   ├── bench/               : Testbenchs for the core & SoC.
│   ├── run/                 : Run scripts (makefile).
│   ├── scripts/             : Scripts needed for the simulation makefile.
│   ├── tests/               : Test folders: assembler & C
│   └── README.md
├── Software/
│   ├── board/               : ??
│   ├── c_project_loader/    :
│   ├── drivers/             : Drivers for the generic SoC.
│   ├── lib/                 : Support libraries for the SoC.
│   ├── templates/           : Templates for project creation.
│   ├── toolchain/           : Toolchain instructions.
│   └── utils/               : Utilities for creating the binary image and HEX file for simulation.
├── MITlicense.md
├── musb.todo
└── README.md
```

## License

Copyright (c) 2014, 2015 Angel Terrones (<aterrones@usb.ve>).

Release under the [MIT License](MITlicense.md).

[1]: http://iverilog.icarus.com
