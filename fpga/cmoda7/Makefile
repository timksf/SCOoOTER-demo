# SPDX-License-Identifier: MIT

PROJECT_ROOT := $(abspath ../..)
PROJECT_NAME := ScoooterCmodA7
BUILD_DIR ?= $(PROJECT_ROOT)/build
PROJECT_DIR := $(BUILD_DIR)/$(PROJECT_NAME)

SYNTH_SCRIPT := $(CURDIR)/tcl/synth_only.tcl
BITSTREAM_SCRIPT := $(CURDIR)/tcl/synth.tcl
BITSTREAM_FILE := $(PROJECT_DIR)/$(PROJECT_NAME).bit
FLASH_IMAGE := $(PROJECT_DIR)/$(PROJECT_NAME).mcs
CFGMEM_PART ?= mx25l3273f-spi-x1_x2_x4

.PHONY: synth bitstream program flash-image program-flash

synth:
	$(MAKE) -C $(PROJECT_ROOT) SIM_TYPE=VERILOG SCRIPT=$(SYNTH_SCRIPT) vivado_tcl

bitstream:
	$(MAKE) -C $(PROJECT_ROOT) SIM_TYPE=VERILOG SCRIPT=$(BITSTREAM_SCRIPT) vivado_tcl

program:
	vivado -mode batch -source $(CURDIR)/tcl/program_bitstream.tcl \
		-tclargs $(BITSTREAM_FILE)

flash-image:
	vivado -mode batch -source $(CURDIR)/tcl/create_flash_image.tcl \
		-tclargs $(BITSTREAM_FILE) $(FLASH_IMAGE)

program-flash: flash-image
	vivado -mode batch -source $(CURDIR)/tcl/program_flash.tcl \
		-tclargs $(FLASH_IMAGE) $(BITSTREAM_FILE) $(CFGMEM_PART)
