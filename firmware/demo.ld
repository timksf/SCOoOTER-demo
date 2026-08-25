OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x20000000, LENGTH = 64K
    RAM   (rwx) : ORIGIN = 0x80000000, LENGTH = 0xF000
}

SECTIONS
{
    .flash_header ORIGIN(FLASH) : ALIGN(4)
    {
        LONG(0x53434f4f)
        LONG(SIZEOF(.payload))
        LONG(ADDR(.payload))
        LONG(_start)
    } > FLASH

    .payload ORIGIN(RAM) : ALIGN(4)
    {
        __payload_start = .;
        KEEP(*(.text.init))
        KEEP(*(.text.trap))
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
        *(.data .data.*)
        *(.sdata .sdata.*)
        . = ALIGN(4);
        __payload_end = .;
    } > RAM AT> FLASH

    .bss (NOLOAD) : ALIGN(4)
    {
        __bss_start = .;
        *(.sbss .sbss.*)
        *(.bss .bss.* COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    PROVIDE(__global_pointer$ = ORIGIN(RAM));
    PROVIDE(__stack_top = ORIGIN(RAM) + LENGTH(RAM));

    ASSERT(LOADADDR(.payload) == ORIGIN(FLASH) + SIZEOF(.flash_header), "payload is not contiguous with flash header")
    ASSERT(LOADADDR(.payload) + SIZEOF(.payload) <= ORIGIN(FLASH) + LENGTH(FLASH), "application exceeds flash window")
    ASSERT(ADDR(.payload) + SIZEOF(.payload) <= ORIGIN(RAM) + LENGTH(RAM), "application payload exceeds RAM workspace")
    ASSERT(__bss_end <= ORIGIN(RAM) + LENGTH(RAM), "application bss exceeds RAM")
}
