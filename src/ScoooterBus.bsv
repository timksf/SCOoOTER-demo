package ScoooterBus;

import Connectable :: *;
import Vector :: *;
import BuildVector :: *;

import BlueFabric :: *;
import Types :: *;
import AhbMemory :: *;
import BlueGPIOAPB :: *;
import BlueUartAPB :: *;
import BlueWatchdogAPB :: *;
import ClintAPB :: *;
import PlicAPB :: *;
import Types :: *;

interface ScoooterAhbDevices_ifc;
    interface AhbBootRom_ifc#(32, 32) boot_rom;
    interface AhbFlashImage_ifc#(32, 32) flash_image;
    interface AhbRam_ifc#(32, 32) ram;
    interface AhbApbBridge_ifc#(32, 32, 0) apb_bridge;
endinterface

interface ScoooterApbDevices_ifc;
    interface BlueUartAPB_ifc uart;
    interface BlueGPIOAPB_ifc#(8) gpio;
    interface BlueWatchdogAPB_ifc wdg;
    interface ClintAPB_ifc clint;
    interface PlicAPB_ifc plic;

    method Bool gpio_irq;
    method Bool wdg_irq;
    method Vector#(NUM_HARTS, Bool) timer_irq;
endinterface

interface ScoooterDevices_ifc;
    interface ScoooterAhbDevices_ifc ahb;
    interface ScoooterApbDevices_ifc apb;
endinterface

module [Module] mkScoooterDevices(ScoooterDevices_ifc);
    AhbBootRom_ifc#(32, 32)         i_boot_rom      <- mkAhbBootRom;
    AhbFlashImage_ifc#(32, 32)      i_flash_image   <- mkAhbFlashImage;
    AhbRam_ifc#(32, 32)             i_ram           <- mkAhbRam;
    AhbApbBridge_ifc#(32, 32, 0)    i_apb_bridge    <- mkAhbApbBridge;
    BlueUartAPB_ifc                 i_uart          <- mkBlueUartAPB(16, 16);
    BlueGPIOAPB_ifc#(8)             i_gpio          <- mkBlueGPIOAPB;
    BlueWatchdogAPB_ifc             i_wdg           <- mkBlueWatchdogAPB;
    ClintAPB_ifc                     i_clint         <- mkClintAPB;
    PlicAPB_ifc                     i_plic          <- mkPlicAPB;

    interface ScoooterAhbDevices_ifc ahb;
        interface boot_rom      = i_boot_rom;
        interface flash_image   = i_flash_image;
        interface ram           = i_ram;
        interface apb_bridge    = i_apb_bridge;
    endinterface

    interface ScoooterApbDevices_ifc apb;
        interface uart  = i_uart;
        interface gpio  = i_gpio;
        interface wdg   = i_wdg;
        interface clint = i_clint;
        interface plic  = i_plic;

        method gpio_irq  = i_gpio.interrupt;
        method wdg_irq   = i_wdg.interrupt;
        method timer_irq = i_clint.timer_interrupts;
    endinterface
endmodule

module [IRQMapCtx_t#(16)] scoooter_irq_map#(ScoooterApbDevices_ifc devices)(Empty);
    irq_map_def("SCOoOTER_IRQS");

    irq_map_source(0,  "GPIO IRQ",   vec(devices.gpio_irq));
    irq_map_source(12, "WDG IRQ",    vec(devices.wdg_irq));
endmodule

module [AddrMapCtx_t#(32, ApbSlaveFabric_ifc#(32, 32, 0))] peripheral_addr_map#(ScoooterApbDevices_ifc i_devices)(Empty);
    addr_map_def("SCOoOTER APB peripherals");

    addr_map_target('h0000_0000, 'h0000_1000, "UART",   i_devices.uart.s_apb);
    addr_map_target('h0000_1000, 'h0000_1000, "GPIO",   i_devices.gpio.s_apb);
    addr_map_target('h0000_2000, 'h0000_1000, "WDG",    i_devices.wdg.s_apb);
    addr_map_target('h0000_3000, 'h0000_1000, "CLINT",  i_devices.clint.s_apb);
    addr_map_target('h0040_0000, 'h0040_0000, "PLIC",   i_devices.plic.s_apb);
endmodule

module [AddrMapCtx_t#(32, AhbSlaveFabric_ifc#(32, 32))] system_addr_map#(ScoooterAhbDevices_ifc i_devices)(Empty);
    addr_map_def("SCOoOTER SoC AHB");
    addr_map_target('h0000_0000, 'h0000_1000, "BOOT_ROM", i_devices.boot_rom.s_ahb);
    addr_map_target('h2000_0000, 'h0001_0000, "FLASH",    i_devices.flash_image.s_ahb);
    addr_map_target('h4000_0000, 'h0080_0000, "APB", i_devices.apb_bridge.ahb);
    addr_map_target('h8000_0000, 'h0001_0000, "RAM", i_devices.ram.s_ahb);
endmodule

interface ScoooterBus_ifc;
    interface AhbSlaveFabric_ifc#(32, 32) s_ahb;

    (* always_enabled *)    method Action  gpio_i(Bit#(8) value);
    (* always_ready *)      method Bit#(8) gpio_o;
    (* always_ready *)      method Bit#(8) gpio_oe;
    (* always_enabled *)    method Action   uart_rx(Bit#(1) value);
    (* always_ready *)      method Bit#(1)  uart_tx;

    (* always_ready *)      method Vector#(NUM_HARTS, Bool) ext_irq;
    (* always_ready *)      method Vector#(NUM_HARTS, Bool) timer_irq;
endinterface

module [Module] mkScoooterBus(ScoooterBus_ifc);
    ScoooterDevices_ifc i_devices <- mkScoooterDevices;

    ApbAddrMap_ifc#(5, 32, 32, 0, Empty)    i_apb_map <- create_apb_addr_map(peripheral_addr_map(i_devices.apb));
    AhbAddrMap_ifc#(4, 32, 32, Empty)       i_ahb_map <- create_ahb_addr_map(system_addr_map(i_devices.ahb));

    IRQMap_ifc#(16, Empty) i_irq_map <- create_irq_map(scoooter_irq_map(i_devices.apb));

    mkConnection(i_devices.ahb.apb_bridge.apb, i_apb_map.slave);

    rule r_drive_plic;
        i_devices.apb.plic.interrupt_sources(i_irq_map.irqs);
    endrule

    interface s_ahb = i_ahb_map.slave;

    method gpio_i   = i_devices.apb.gpio.input_value;
    method gpio_o   = i_devices.apb.gpio.output_value;
    method gpio_oe  = i_devices.apb.gpio.output_enable;
    method uart_rx  = i_devices.apb.uart.rx;
    method uart_tx  = i_devices.apb.uart.tx;
    method ext_irq   = i_devices.apb.plic.external_interrupts;
    method timer_irq = i_devices.apb.timer_irq;
endmodule

endpackage
