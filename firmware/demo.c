typedef unsigned int uint32_t;

#define GPIO_BASE           0x40001000u
#define GPIO_INPUT_EN       (GPIO_BASE + 0x04u)
#define GPIO_OUTPUT_EN      (GPIO_BASE + 0x08u)
#define GPIO_OUTPUT_VAL     (GPIO_BASE + 0x0cu)
#define GPIO_RISE_IE        (GPIO_BASE + 0x18u)
#define GPIO_RISE_IP        (GPIO_BASE + 0x1cu)

#define CLINT_BASE          0x40003000u
#define CLINT_MTIME_LO      (CLINT_BASE + 0x00u)
#define CLINT_MTIME_HI      (CLINT_BASE + 0x04u)
#define CLINT_MTIMECMP_LO   (CLINT_BASE + 0x08u)
#define CLINT_MTIMECMP_HI   (CLINT_BASE + 0x0cu)

#define WDG_IRQ_PENDING     (0x40002000u + 0x18u)

#define PLIC_BASE           0x40400000u
#define PLIC_PRIORITY_GPIO  (PLIC_BASE + 0x04u)
#define PLIC_PRIORITY_WDG   (PLIC_BASE + 0x34u)
#define PLIC_ENABLE         (PLIC_BASE + 0x2000u)
#define PLIC_THRESHOLD      (PLIC_BASE + 0x200000u)
#define PLIC_CLAIM          (PLIC_BASE + 0x200004u)

#define BUTTON_BIT          (1u << 2)
#define LED_MASK            0x03u
#define MSTATUS_MIE         (1u << 3)
#define MIE_MTIE            (1u << 7)
#define MIE_MEIE            (1u << 11)
#define IRQ_FLAG            0x80000000u

extern void trap_entry(uint32_t cause, uint32_t epc);

static volatile uint32_t led_pattern;
static volatile uint32_t timer_ticks;
static volatile uint32_t timer_deadline;

static inline void write32(uint32_t address, uint32_t value) {
    *(volatile uint32_t *)address = value;
}

static inline uint32_t read32(uint32_t address) {
    return *(volatile uint32_t *)address;
}

static inline void set_mie(uint32_t value) {
    __asm__ volatile ("csrw mie, %0" : : "r"(value) : "memory");
}

static inline void set_mtvec(void (*handler)(uint32_t, uint32_t)) {
    __asm__ volatile ("csrw mtvec, %0" : : "r"(handler) : "memory");
}

static inline void enable_interrupts(void) {
    __asm__ volatile ("csrs mstatus, %0" : : "r"(MSTATUS_MIE) : "memory");
}

static void schedule_next_timer(void) {
    timer_deadline += 0x1000u;

    /* Avoid a transient low compare while programming the 64-bit register. */
    write32(CLINT_MTIMECMP_HI, 0xffffffffu);
    write32(CLINT_MTIMECMP_LO, timer_deadline);
    write32(CLINT_MTIMECMP_HI, 0u);
}

void trap_handler(uint32_t cause, uint32_t epc) {
    uint32_t interrupt = cause & IRQ_FLAG;
    uint32_t code = cause & 0x7fu;

    (void)epc;
    if (!interrupt) {
        set_mie(0u);
        for (;;) {
            __asm__ volatile ("nop");
        }
    }

    if (code == 7u) {
        ++timer_ticks;
        led_pattern ^= 1u;
        write32(GPIO_OUTPUT_VAL, led_pattern & LED_MASK);
        schedule_next_timer();
    }
    else if (code == 11u) {
        uint32_t claim = read32(PLIC_CLAIM);
        if (claim == 1u) {
            led_pattern ^= 2u;
            write32(GPIO_OUTPUT_VAL, led_pattern & LED_MASK);
            write32(GPIO_RISE_IP, BUTTON_BIT);
        }
        else if (claim == 13u) {
            write32(WDG_IRQ_PENDING, 1u);
        }
        if (claim != 0u) {
            write32(PLIC_CLAIM, claim);
        }
    }
}

void demo_main(void) {
    led_pattern = 1u;
    timer_ticks = 0u;
    timer_deadline = 0u;

    write32(GPIO_INPUT_EN, BUTTON_BIT);
    write32(GPIO_OUTPUT_EN, LED_MASK);
    write32(GPIO_OUTPUT_VAL, led_pattern);
    write32(GPIO_RISE_IE, BUTTON_BIT);

    write32(PLIC_PRIORITY_GPIO, 1u);
    write32(PLIC_PRIORITY_WDG, 1u);
    write32(PLIC_ENABLE, (1u << 1) | (1u << 13));
    write32(PLIC_THRESHOLD, 0u);

    write32(CLINT_MTIME_HI, 0u);
    write32(CLINT_MTIME_LO, 0u);
    schedule_next_timer();

    set_mtvec(trap_entry);
    set_mie(MIE_MTIE | MIE_MEIE);
    enable_interrupts();

    for (;;) {
        __asm__ volatile ("nop");
    }
}
