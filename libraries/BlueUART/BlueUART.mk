BLUEUART_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../dep/blueuart)
BLUEUART_SRC := $(BLUEUART_ROOT)/hdl/src

EXTRA_BSV_LIBS += $(BLUEUART_SRC)

$(info Adding BlueUART from $(BLUEUART_SRC))
