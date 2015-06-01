#!/bin/bash
#-------------------------------------------------------------------------------
# Copyright (C) 2015 Angel Terrones <angelterrones@gmail.com>
#-------------------------------------------------------------------------------
#
# File Name: help_screen
#
# Author:
#             - Angel Terrones <angelterrones@gmail.com>
#
#-------------------------------------------------------------------------------

###################################################################
# Constants
###################################################################
# text attributes: normal, bold, underline
n='\e[0m';
b='\e[1m';
u='\e[4m';

# bold+green
g='\e[32m';

# bold+red
r='\e[31m';

# brown+blue
B='\e[34m';

###############################################################################
#                                 Help Menu                                   #
###############################################################################
echo -e ""
echo -e "${g}Makefile: ${n} HELP SCREEN"
echo -e ""
echo -e "${b}USAGE:${n}"
echo -e "\tmake ${u}TARGET${n} ${u}VARIABLE${n}"
echo -e ""
echo -e ""
echo -e "${b}TARGET:${n}"
echo -e "\t${b}check${n}"
echo -e "\t    Check Verilog files found in ${u}Hardware${n} and ${u}Simulation/testbench${n} directories;"
echo -e ""
echo -e "\t${b}compile${n}"
echo -e "\t    Compiles Verilog testbench found in ${u}Simulation/testbench${n} directory;"
echo -e "\t    places all outputs (waveforms, regdump, etc.) in ${b}Simulation/out${n} folder"
echo -e ""
echo -e "\t${b}run${n}"
echo -e "\t    Compiles Verilog testbench found in ${u}Simulation/testbench${n} directory;"
echo -e "\t    simulates Verilog using ${b}MIF${n} as input (memory image);"
echo -e "\t    places all outputs (waveforms, regdump, etc.) in ${b}Simulation/out${n} folder"
echo -e ""
echo -e "\t${b}view${n}"
echo -e "\t    Open the vcd file ${b}VCD${n} in ${b}Simulation/out${n} folder with GTKWave"
echo -e ""
echo -e ""
echo -e "${b}VARIABLE:${n}"
echo -e "\t${b}TB${n}=${u}VERILOG TESTBENCH${n}"
echo -e "\t    For ${b}compile${n} and ${b}run${n} targets, specifies the testbench file for simulation;"
echo -e ""
echo -e "\t${b}MIF${n}=${u}MEMORY INPUT FILE${n}"
echo -e "\t    For ${b}run${n} target, specifies the memory image: program and data;"
echo -e ""
echo -e "\t${b}VCD${n}=${u}WAVEFORM FILE${n}"
echo -e "\t    For ${b}view${n} target, specifies the waveform file to be opened with GTKWave;"
echo -e ""
echo -e ""
echo -e "${b}EXAMPLES:${n}"
echo -e "\tmake check"
echo -e "\tmake compile TB=../testbench/tb_core.v"
echo -e "\tmake run TB=../testbench/tb_core.v MIF=../inputs/mif/addiu.mif"
echo -e "\tmake view VCD=../out/tb_core.vcd"
echo -e ""
echo -e ""
echo -e "(END)"
exit 0
