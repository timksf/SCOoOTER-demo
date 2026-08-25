/* RV32 application startup.*/
.section .text.init, "ax", @progbits
.globl _start
.type _start, @function
_start:
    csrw    mie, zero
    csrc    mstatus, 8
    la      sp, __stack_top
    la      gp, __global_pointer$

    la      t0, __bss_start
    la      t1, __bss_end
1:
    bgeu    t0, t1, 2f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       1b
2:
    la      t0, trap_entry
    csrw    mtvec, t0
    call    demo_main
3:
    j       3b
.size _start, . - _start
