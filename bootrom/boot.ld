OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
}

SECTIONS
{
    . = ORIGIN(ROM);
    .text :
    {
        KEEP(*(.text.init))
        *(.text.trap)
        *(.text .text.*)
    } > ROM

    .rodata :
    {
        *(.rodata .rodata.*)
    } > ROM

    .data : ALIGN(4)
    {
        __data_start = .;
        *(.data .data.*)
        . = ALIGN(4);
        __data_end = .;
    } > RAM AT> ROM

    __data_load_start = LOADADDR(.data);

    .bss (NOLOAD) : ALIGN(4)
    {
        __bss_start = .;
        *(.bss .bss.* COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    PROVIDE(__global_pointer$ = ORIGIN(RAM));
    PROVIDE(__boot_stack_top = ORIGIN(RAM) + LENGTH(RAM));

    ASSERT(SIZEOF(.text) + SIZEOF(.rodata) + SIZEOF(.data) <= LENGTH(ROM), "boot ROM exceeds 4 KiB")
    ASSERT(__bss_end <= ORIGIN(RAM) + LENGTH(RAM) - 0x1000, "boot state exceeds reserved workspace")
}
