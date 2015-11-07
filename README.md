![logo](https://github.com/AngelTerrones/MUSB/wiki/images/logo_musb.png)

__(Currently, this project is not under development. The new MIPS processor (core only): https://github.com/AngelTerrones/antares)__

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
-  No address space verification for the instruction port: Code runs always in kernel mode.
-  Documentation in-source.
-  Vendor-independent code.

The project includes the standalone MIPS32 processor and a basic SoC design with GPIO and UART/hardware bootloader.
Tested in Xilinx Spartan-3 (Digilent) and Spartan-6 (XuLA2-LX25) boards.

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
├── Documentation/
│   ├── src/                : Source files (texinfo).
│   └── makefile
├── Hardware/
│   ├── core/               : Verilog files for the core.
│   ├── include/            : Opcodes and processor configuration.
│   ├── musoc/              : SoC implementation.
│   ├── ram/                : Internal block RAM for synthesis and simulation.
│   └── README.md
├── Simulation/
│   ├── inputs/             : Demos written in assembly.
│   ├── run/                : Scripts to simulate the project using Icarus Verilog.
│   ├── testbench/          : Verilog tests.
│   └── README.md
├── Software/
│   ├── Lib/                : Support libraries.
│   └── Toolchain\          : MIPS cross-compile toolchain.
├── MITlicense.md
└── README.md
```

## License

Copyright (c) 2014 Angel Terrones (<aterrones@usb.ve>).

Release under the [MIT License](MITlicense.md).

[1]: http://iverilog.icarus.com
