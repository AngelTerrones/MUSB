#!/bin/bash
#-------------------------------------------------------------------------------
# Copyright (C) 2014 Angel Terrones <angelterrones@gmail.com>
#-------------------------------------------------------------------------------
#
# File Name: create_filelist
#
# Author:
#             - Angel Terrones <angelterrones@gmail.com>
#
#-------------------------------------------------------------------------------

# Set the folders
if [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    MUSB_ROOT="$(cd ../../; pwd -W)"        # windows
else
    MUSB_ROOT="$(cd ../../; pwd)"           # linux/Mac
fi

RTL_FOLDER=$MUSB_ROOT/Hardware
TEST_FOLDER=$MUSB_ROOT/Simulation/bench

# Set Filelist
mkdir -p build
FILELIST_ICARUS=$PWD/build/filelist.prj

# remove old files
rm -f build/*

#create the new filelist of rtl
touch $FILELIST_ICARUS

find $RTL_FOLDER -name "*.v" >> $FILELIST_ICARUS
find $TEST_FOLDER -name "*.v" >> $FILELIST_ICARUS

#-------------------------------------------------------------------------------
# Xilinx libraries.
# echo +libdir+/opt/Xilinx/14.7/ISE_DS/ISE/verilog/src/unisims >> $FILELIST_ICARUS
#-------------------------------------------------------------------------------

for folder in $(find $RTL_FOLDER -type d)
do
    echo "+incdir+"$folder >> $FILELIST_ICARUS
done
