BLUEJ_INTEGRATION_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BLUEJ_ROOT := $(abspath $(BLUEJ_INTEGRATION_DIR)/../../dep/bluej)
BLUEJ_SRC := $(BLUEJ_ROOT)/hdl/src

EXTRA_BSV_LIBS += $(BLUEJ_SRC)
C_FILES += $(BLUEJ_INTEGRATION_DIR)/jtag_bdpi.cc
VERILOGDIR_EXTRAS += $(BLUEJ_SRC)/rtl

$(info Adding BlueJ from $(BLUEJ_SRC))
