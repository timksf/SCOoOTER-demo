typedef unsigned int uint32_t;

#define GPIO_BASE       0x40001000u
#define GPIO_OUTPUT_EN  (GPIO_BASE + 0x08u)
#define GPIO_OUTPUT_VAL (GPIO_BASE + 0x0cu)

#define FLASH_BASE      0x20000000u
#define RAM_BASE        0x80000000u
#define BOOT_WORKSPACE  0x8000f000u
#define IMAGE_MAGIC     0x53434f4fu

struct image_header {
    uint32_t magic;
    uint32_t size;
    uint32_t destination;
    uint32_t entry;
};

static inline void mmio_write(uint32_t address, uint32_t value) {
    *(volatile uint32_t *)address = value;
}

static void boot_park(uint32_t pattern) {
    //park loop with error-specific GPIO output pattern
    mmio_write(GPIO_OUTPUT_EN, 0xffu);
    mmio_write(GPIO_OUTPUT_VAL, pattern);
    for (;;) {
        __asm__ volatile ("nop");
    }
}

void trap_handler(uint32_t cause, uint32_t epc) {
    (void)cause;
    (void)epc;
    boot_park(0x81u);
}

void boot_main(void) {
    const volatile struct image_header  *header = (const volatile struct image_header *)FLASH_BASE;
    const volatile uint32_t             *source = (const volatile uint32_t *)(FLASH_BASE + sizeof(*header));

    volatile uint32_t *target;
    uint32_t size;
    uint32_t destination;
    uint32_t end;
    uint32_t i;
    void (*entry)(void);

    size = header->size;
    if (header->magic != IMAGE_MAGIC || size == 0u) {
        boot_park(0x11u);
    }

    destination = header->destination;
    if (destination < RAM_BASE || destination >= BOOT_WORKSPACE ||
        size > BOOT_WORKSPACE - destination ||
        (destination & 3u) != 0u || (size & 3u) != 0u) {
        boot_park(0x22u);
    }

    end = destination + size;
    if (end < destination || end > BOOT_WORKSPACE ||
        header->entry < destination || header->entry >= end ||
        (header->entry & 3u) != 0u) {
        boot_park(0x33u);
    }

    target = (volatile uint32_t *)destination;
    for (i = 0; i < size; i += 4u) {
        target[i >> 2] = source[i >> 2];
    }

    /* SCOoOTER has no instruction cache; retain ordering for the handoff. */
    __asm__ volatile ("fence" ::: "memory");
    __asm__ volatile ("csrw mie, zero"      ::: "memory");
    __asm__ volatile ("csrc mstatus, 8"     ::: "memory");
    __asm__ volatile ("csrw mtvec, zero"    ::: "memory");

    entry = (void (*)(void))header->entry;
    entry();
    boot_park(0x44u);
}
