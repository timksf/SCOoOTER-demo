BLUEGPIO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../dep/bluegpio)
BLUEGPIO_SRC := $(BLUEGPIO_ROOT)/src

EXTRA_BSV_LIBS += $(BLUEGPIO_SRC)

$(info Adding BlueGPIO from $(BLUEGPIO_SRC))
