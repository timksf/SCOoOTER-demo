SCOOOTER_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../dep/SCOoOTER)
SCOOOTER_CORE_SRC := $(SCOOOTER_ROOT)/core/src
SCOOOTER_CORE_DIRS := $(SCOOOTER_CORE_SRC) \
    $(shell find $(SCOOOTER_CORE_SRC)/src_bus $(SCOOOTER_CORE_SRC)/src_core -type d -print)

EXTRA_BSV_LIBS += $(SCOOOTER_CORE_DIRS)

$(info Adding SCOoOTER from $(SCOOOTER_CORE_SRC))
