# SPDX-License-Identifier: MIT

PROJECT_ROOT := $(CURDIR)

TOP_MODULE := mkScoooterSystem
MAIN_MODULE := ScoooterSystem
PROJECT_NAME := ScoooterCmodA7

TESTBENCH_MODULE := mkTestScoooterSoCOOCDTB
TESTBENCH_FILE := $(PROJECT_ROOT)/test/TestScoooterSoCOOCDTB.bsv
TEST_DIR := $(PROJECT_ROOT)/test
OUTFILE := scoooter_soc_oocd

BSV_TOOLS ?= $(PROJECT_ROOT)/dep/BSVTools

EXTRA_BSV_LIBS :=
EXTRA_LIBRARIES :=
RUN_FLAGS :=

EXTRA_FLAGS += -aggressive-conditions
EXTRA_FLAGS += -keep-inlined-boundaries
EXTRA_FLAGS += -show-schedule
EXTRA_FLAGS += -D "BSV_TIMESCALE=1ns/1ps"
EXTRA_FLAGS += -D "SCOOOTER_DEBUG"

ifeq ($(FINITE_TEST),1)
EXTRA_FLAGS += -D "SCOOOTER_FINITE_TEST"
endif

SCOOOTER_NUM_THREADS ?= 1
SCOOOTER_NUM_CPU ?= 1
EXTRA_FLAGS += -D "SCOOOTER_NUM_THREADS=$(SCOOOTER_NUM_THREADS)"
EXTRA_FLAGS += -D "SCOOOTER_NUM_CPU=$(SCOOOTER_NUM_CPU)"

FPGA_DIR := $(PROJECT_ROOT)/fpga/cmoda7
VERILOGDIR_EXTRAS := $(FPGA_DIR)/rtl
PART := xc7a35tcpg236-1
SCRIPT ?= $(FPGA_DIR)/tcl/synth.tcl

CPU_CONFIG_SOURCE := $(PROJECT_ROOT)/src/ScoooterCpu.bsv
CONFIG_ADAPTER := $(PROJECT_ROOT)/src/Config.bsv

SCOOOTER_CLANG ?= clang
SCOOOTER_LLD ?= ld.lld
SCOOOTER_GDB_OBJECT := $(PROJECT_ROOT)/build/scoooter-gdb.o
SCOOOTER_GDB_ELF := $(PROJECT_ROOT)/build/scoooter-gdb.elf

$(CONFIG_ADAPTER): $(CPU_CONFIG_SOURCE)
	touch $@

ifneq (,$(wildcard $(PROJECT_ROOT)/libraries/*/*.mk))
include $(PROJECT_ROOT)/libraries/*/*.mk
endif

include $(BSV_TOOLS)/scripts/rules.mk

.PHONY: bootrom firmware scoooter-gdb-elf

bootrom:
	$(MAKE) -C $(PROJECT_ROOT)/bootrom

firmware:
	$(MAKE) -C $(PROJECT_ROOT)/firmware

compile compile_top: bootrom firmware $(CONFIG_ADAPTER)

scoooter-gdb-elf: | directories
	$(SCOOOTER_CLANG) --target=riscv32-unknown-elf -march=rv32im -mabi=ilp32 -g \
		-c $(PROJECT_ROOT)/test/scoooter_gdb.S -o $(SCOOOTER_GDB_OBJECT)
	$(SCOOOTER_LLD) -flavor gnu -m elf32lriscv \
		-T $(PROJECT_ROOT)/test/scoooter_ram.ld \
		$(SCOOOTER_GDB_OBJECT) -o $(SCOOOTER_GDB_ELF)
