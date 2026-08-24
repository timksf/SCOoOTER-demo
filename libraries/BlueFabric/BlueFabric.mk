BLUEFABRIC_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../dep/bluefabric)
BLUEFABRIC_SRC := $(BLUEFABRIC_ROOT)/src
BLUEFABRIC_SRC_DIRS := $(shell find $(BLUEFABRIC_SRC) -type d -print)

EXTRA_BSV_LIBS += $(BLUEFABRIC_SRC_DIRS)

$(info Adding BlueFabric from $(BLUEFABRIC_SRC))
