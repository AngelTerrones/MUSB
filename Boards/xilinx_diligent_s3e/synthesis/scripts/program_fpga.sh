#!/bin/bash
#-------------------------------------------------------------------------------
# Copyright (C) 2015 Angel Terrones <angelterrones@gmail.com>
#-------------------------------------------------------------------------------
#
# File Name: program_fpga.sh
#
# Author:
#             - Angel Terrones <angelterrones@gmail.com>
# Description:
#       Generate PROM file
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Parameter check
#-------------------------------------------------------------------------------
EXPECTED_ARGS=3
if [ $# -ne $EXPECTED_ARGS ]; then
    echo ""
    echo "ERROR   : wrong number of arguments"
    echo "USAGE   : ./program_fpga.sh <prom name> <prom folder> <build folder>"
    echo ""
    exit 1
fi

#-------------------------------------------------------------------------------
# Check if requiered file exists
#-------------------------------------------------------------------------------
promfile=$2/$1.bit;

if [ ! -e $promfile ]; then
    echo
    echo "PROM file does not exist: $promfile"
    echo
    exit 1
fi

#-------------------------------------------------------------------------------
# move to build folder
#-------------------------------------------------------------------------------
cd $3

#-------------------------------------------------------------------------------
# copy impact script & update
#-------------------------------------------------------------------------------
cp ../scripts/impact_program_fpga.batch .
sed -i "s/BITSTREAM_NAME/$1/g" ./impact_program_fpga.batch

#-------------------------------------------------------------------------------
# Program FPGA
#-------------------------------------------------------------------------------
impact -batch ./impact_program_fpga.batch

#-------------------------------------------------------------------------------
# return
#-------------------------------------------------------------------------------
cd ..
