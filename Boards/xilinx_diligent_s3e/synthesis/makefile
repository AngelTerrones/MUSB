###############################################################################
# Makefile to compile the project
# Angel Terrones <angelterrones@gmail.com>
###############################################################################
SHELL := bash

#-------------------------------------------------------------------------------
#FPGA
#-------------------------------------------------------------------------------
.FPGA=3S500EFG320-4

#-------------------------------------------------------------------------------
# Folders
#-------------------------------------------------------------------------------
.BUILD_FOLDER=./build
.BIT_FOLDER=./bitstream
.MUSB_RTL=$(shell cd ../../../Hardware; pwd)
.BOARD_RTL_FOLDER=$(shell cd ../rtl; pwd)

#-------------------------------------------------------------------------------
# TARGETS
#-------------------------------------------------------------------------------
.PHONY: clean

#-------------------------------------------------------------------------------
build-bitstream:
	@mkdir -p ${.BUILD_FOLDER}
	@mkdir -p ${.BIT_FOLDER}
	@./scripts/create_project.sh ${.MUSB_RTL} ${.BOARD_RTL_FOLDER} ${.BUILD_FOLDER}
	@./scripts/create_bitstream.sh ${.FPGA} ${.BUILD_FOLDER} ${.BIT_FOLDER}

build-prom:
	@./scripts/generate_prom_file.sh musoc ${.BIT_FOLDER} ${.BUILD_FOLDER}

program-fpga:
	@./scripts/program_fpga.sh musoc ${.BIT_FOLDER} ${.BUILD_FOLDER}

#-------------------------------------------------------------------------------
clean:
	@echo -e ""
	rm -rf ${.BUILD_FOLDER}
	rm -rf ${.BIT_FOLDER}
	@echo -e ""
