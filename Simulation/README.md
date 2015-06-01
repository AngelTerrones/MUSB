# Simulation

Software needed to simulate the MUSB processor.

## Directory Layout

```
Simulation
├── inputs/                 : Demos.
│   ├── asm/                : Assembler demos.
│   └── mif/                : Compiled demos (Memory Input File).
├── run/                    :
│   ├── check_verilog.sh*   : Check syntax.
│   ├── compile.sh*         : Compile testbench.
│   ├── create_filelist.sh* : Create list of verilog input files.
│   ├── help_screen.sh*     : Print help screen (make).
│   ├── makefile            : makefile to run the testbenchs
│   └── run_sim.sh*         : Execute compiled simulation.
├── testbench/              :
│   ├── components/         : Testbenchs for Core and SoC internals.
│   ├── tb_core_uart.v      : Testbench for the SoC.
│   └── tb_core.v           : Testbench for the Core.
└── README.md
```

## Run the simulation

To simulate the processor, follow the makefile instructions:

- Change directory to ```<project directory>\Simulation\run```.
- Execute ```make``` to get help screen. The output of ```make``` with no targets:

        ```
        Makefile:  HELP SCREEN

        USAGE:
            make TARGET VARIABLE


        TARGET:
            check
                Check Verilog files found in Hardware and Simulation/testbench directories;

            compile
                Compiles Verilog testbench found in Simulation/testbench directory;
                places all outputs (waveforms, regdump, etc.) in Simulation/out folder

            run
                Compiles Verilog testbench found in Simulation/testbench directory;
                simulates Verilog using MIF as input (memory image);
                places all outputs (waveforms, regdump, etc.) in Simulation/out folder

            view
                Open the vcd file VCD in Simulation/out folder with GTKWave


        VARIABLE:
            TB=VERILOG TESTBENCH
                For compile and run targets, specifies the testbench file for simulation;

            MIF=MEMORY INPUT FILE
                For run target, specifies the memory image: program and data;

            VCD=WAVEFORM FILE
                For view target, specifies the waveform file to be opened with GTKWave;


        EXAMPLES:
            make check
            make compile TB=../testbench/tb_core.v
            make run TB=../testbench/tb_core.v MIF=../inputs/mif/addiu.mif
            make view VCD=../out/tb_core.vcd


        (END)
        ```

- Execute, from the __run__ folder: ```make run TB=../testbench/tb_core.v MIF=../inputs/MIF/addiu.mif```.
  For each variable, the __user must specify the relative path__ to the input file.
