SCOOOTER_CLANG ?= clang
SCOOOTER_LLD ?= ld.lld
LLVM_OBJCOPY ?= llvm-objcopy

CFLAGS := --target=riscv32-unknown-elf -march=rv32i_zicsr -mabi=ilp32
CFLAGS += -ffreestanding -fno-builtin -fno-stack-protector -fno-pic
CFLAGS += -msmall-data-limit=0 -mno-relax -O2

OBJECTS := demo.o demo_start.o trap.o

.PHONY: all clean

all: demo.hex

demo.o: demo.c
	$(SCOOOTER_CLANG) $(CFLAGS) -c $< -o $@

demo_start.o: demo.S
	$(SCOOOTER_CLANG) $(CFLAGS) -c $< -o $@

trap.o: trap.S
	$(SCOOOTER_CLANG) $(CFLAGS) -c $< -o $@

demo.elf: $(OBJECTS) demo.ld
	$(SCOOOTER_LLD) -flavor gnu -m elf32lriscv -T demo.ld $(OBJECTS) -o $@

demo.bin: demo.elf
	$(LLVM_OBJCOPY) -O binary $< $@

demo.hex: demo.bin
	od -An -tx4 -w4 -v $< | tr -d ' ' > $@

clean:
	rm -f $(OBJECTS) demo.elf demo.bin demo.hex
