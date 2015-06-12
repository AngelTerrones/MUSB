#!/bin/bash
#-------------------------------------------------------------------------------
# Copyright (C) 2014 Angel Terrones <angelterrones@gmail.com>
#-------------------------------------------------------------------------------
#
# File Name: create_project.sh
#
# Author:
#             - Angel Terrones <angelterrones@gmail.com>
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Parameter check
#-------------------------------------------------------------------------------
EXPECTED_ARGS=3
if [ $# -ne $EXPECTED_ARGS ]; then
    echo ""
    echo "ERROR : wrong number of arguments"
    echo "USAGE : create_project.sh <MUSB rtl> <board rtl> <build folder>"
    echo ""
    exit 1
fi

#-------------------------------------------------------------------------------
# Hardware folder
#-------------------------------------------------------------------------------
RTL_FOLDER=$1

#-------------------------------------------------------------------------------
# Modules
#-------------------------------------------------------------------------------
# Hardware folder
ARBITER=$RTL_FOLDER/arbiter
FIFO=$RTL_FOLDER/fifo
GPIO=$RTL_FOLDER/gpio
IO_CELL=$RTL_FOLDER/io_cell
MUSB=$RTL_FOLDER/musb
MUX_SWITCH=$RTL_FOLDER/mux_switch
RAM=$RTL_FOLDER/ram
RST_GEN=$RTL_FOLDER/rst_generator
UART=$RTL_FOLDER/uart
# Board folder
CLK_GEN=$2/verilog/clk_generator
MEMORY=$2/verilog/memory
MUSOC=$2/verilog/musoc

MODULES="$ARBITER $FIFO $GPIO $IO_CELL $MUSB $MUX_SWITCH $RAM $RST_GEN $UART $CLK_GEN $MEMORY $MUSOC"

#-------------------------------------------------------------------------------
# File project
#-------------------------------------------------------------------------------
FILE_PROJECT=$3/musoc.prj

#-------------------------------------------------------------------------------
# Create project file
#-------------------------------------------------------------------------------
rm -f $FILE_PROJECT
touch $FILE_PROJECT

for module in $MODULES; do
    for file in $(find $module -name "*.v")
    do
        echo "\`include \"$file\"" >> $FILE_PROJECT
    done
done
