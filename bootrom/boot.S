/* RV32 reset and C runtime entry for the first-stage boot ROM */
.section .text.init, "ax", @progbits
.globl _start
.type _start, @function
_start:
    csrw    mie, zero
    csrc    mstatus, 8

    la      sp, __boot_stack_top
    la      gp, __global_pointer$

    la      t0, __data_load_start
    la      t1, __data_start
    la      t2, __data_end
1:
    bgeu    t1, t2, 2f
    lw      t3, 0(t0)
    sw      t3, 0(t1)
    addi    t0, t0, 4
    addi    t1, t1, 4
    j       1b
2:
    la      t0, __bss_start
    la      t1, __bss_end
3:
    bgeu    t0, t1, 4f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       3b
4:
    la      t0, trap_entry
    csrw    mtvec, t0
    call    boot_main
5:
    wfi
    j       5b
.size _start, . - _start
