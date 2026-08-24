# SCOoOTER + BlueJ debug demo

This standalone project combines the SCOoOTER RISC-V core with BlueJ's JTAG,
RISC-V Debug Module, and BlueBus support. Its primary purpose is simulation and
OpenOCD/GDB regression testing. A Cmod A7 hardware flow is retained under
`fpga/cmoda7` for continued development.

The project owns only the SoC integration in `src/`, its testbench, boot ROM,
and board wrapper. SCOoOTER, BlueJ, BSVTools, and the reusable peripheral and
bus libraries are Git submodules under `dep/`; no dependency sources are
copied into this repository.

## Checkout and toolchain

Initialize only the top-level submodules. The dependencies have their own
development submodules, but this project deliberately uses one flat set of
compatible revisions from `dep/`.

```sh
git clone <repository-url> scoooter-bluej-demo
cd scoooter-bluej-demo
git submodule update --init
nix develop ./nix
```

The Makefile uses BSVTools' standard library discovery. The small adapters in
`libraries/` add each submodule's BSV source directories; the BlueAXI,
BlueLib, and BlueCSR entries are symlinks to the integration files supplied by
those projects.

## Simulation

Compile the native Bluesim testbench:

```sh
make compile
```

Run the remote-bitbang simulation in one terminal. It waits for OpenOCD:

```sh
make sim
```

Connect OpenOCD from a second terminal:

```sh
openocd -f openocd.cfg
```

Build the RV32 test image and run the GDB regression from a third terminal:

```sh
make scoooter-gdb-elf
gdb -q -batch -x test/scoooter_gdb.gdb build/scoooter-gdb.elf
```

The batch test loads RAM through the RISC-V Debug Module, checks single-step,
sets and removes a software breakpoint, and steps over the restored
instruction. The `gdb` supplied by the Nix shell supports RV32; on distributions
whose native GDB does not, use `gdb-multiarch` with the same arguments.

The demo defaults to one hart. Use matching build and OpenOCD settings for a
multi-hart configuration:

```sh
make SCOOOTER_NUM_THREADS=2 SCOOOTER_NUM_CPU=1 compile
openocd -c "set SCOOOTER_HART_COUNT 2" -f openocd.cfg
```

Hart indices are flattened as `cpu * NUM_THREADS + thread`.

To use BlueJ's custom BlueBus scan without creating a RISC-V target:

```sh
openocd -c "set SCOOOTER_RISCV_TARGET 0" -f openocd.cfg
```

The OpenOCD telnet console then provides `bluebus_read32` and
`bluebus_write32`.

## Memory map

| Base | Size | Target |
| --- | ---: | --- |
| `0x0000_0000` | 4 KiB | Boot ROM |
| `0x4000_0000` | 8 MiB | APB bridge |
| `0x8000_0000` | 64 KiB | RAM |

| APB offset | Size | Target |
| --- | ---: | --- |
| `0x0000` | 4 KiB | BlueUART |
| `0x1000` | 4 KiB | BlueGPIO |
| `0x2000` | 4 KiB | Watchdog |
| `0x0040_0000` | 4 MiB | PLIC |

The boot ROM initializes `sp` to `0x8000_1000` and jumps to RAM at
`0x8000_0000`. `make compile` regenerates `bootrom/boot.hex` when required.

## Cmod A7 flow

The board-specific wrapper, constraints, OpenOCD configuration, and Vivado
scripts are isolated in `fpga/cmoda7`. These flows are intentionally separate
from the simulation-first root Makefile:

```sh
make -C fpga/cmoda7 synth
make -C fpga/cmoda7 bitstream
make -C fpga/cmoda7 program
make -C fpga/cmoda7 program-flash
```

The board flow targets `xc7a35tcpg236-1`. The generated bitstream and flash
image are placed below `build/ScoooterCmodA7/`. The hardware OpenOCD setup is
`fpga/cmoda7/openocd.cfg`.

## Project layout

```text
bootrom/          Minimal RV32 boot ROM
dep/              Git submodules only
fpga/cmoda7/      Board wrapper, constraints, and Vivado/OpenOCD scripts
libraries/        BSVTools dependency integration metadata
nix/              Reproducible development shell
src/              Demo-owned SCOoOTER/BlueJ SoC integration
test/             Remote-bitbang testbench and GDB regression
```
