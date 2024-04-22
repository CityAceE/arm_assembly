macro	mov32	reg, value {
	ldr	reg, [pc]
	b	@f
	dw	value
@@:
}

format binary as 'img'

	org	0x8000
	mov	sp, 0x8000	; setup the stack
	bl	uart0_init	; init UART0
	adr	r1, message
	bl	uart0_puts	; put welcome string to UART0

halt:
	b	halt

PERIPHERAL_BASE = 0x20000000 ; Peripheral Base Address for raspi1

UART0BASE	= PERIPHERAL_BASE + 0x201000 ; 0x3F201000 for raspi2 & 3, 0x20201000 for raspi1
UART0_CR	= UART0BASE + 0x30
UART0_ICR	= UART0BASE + 0x44
UART0_IBRD	= UART0BASE + 0x24
UART0_FBRD	= UART0BASE + 0x28
UART0_LCRH	= UART0BASE + 0x2C
UART0_IMSC	= UART0BASE + 0x38
UART0_FR	= UART0BASE + 0x18
UART0_DR	= UART0BASE + 0x00
GPIO_BASE	= PERIPHERAL_BASE + 0x200000 ; 0x3F200000 for raspi2 & 3, 0x20200000 for raspi1
GPPUD		= GPIO_BASE + 0x94
GPPUDCLK0	= GPIO_BASE + 0x98

macro	wait	count {
	mov	r1, count
local m1001
m1001:
	sub	r1, 1
	cmp	r1, 0
	bne	m1001
}

macro	mem_write  addr,val {
	mov32	r1,addr
	mov	r2, val
	str	r2, [r1]
}

macro mem_write_l  addr,val {
	mov32	r1,addr
	mov32	r2, val
	str	r2, [r1]
}

; init UART0 to 115200, no parity
uart0_init:
	mem_write UART0_CR, 0			; disable UART0
	mem_write GPPUD, 0			; disable pull up/down for all GPIO pins
	wait 150
	mem_write GPPUDCLK0, 1100000000000000b
	wait 150
	mem_write GPPUDCLK0,  0
	mem_write_l UART0_ICR,	0x7FF		; clear pending interrupts
	mem_write UART0_IBRD, 1			; divider = 3000000 / (16 * 115200) = 1.627 = ~1
	mem_write UART0_FBRD, 40		; fractional part register = (.627 * 64) + 0.5 = 40.6 = ~40
	mem_write UART0_LCRH, 1110000b		; enable FIFO & 8 bit data transmission (1 stop bit, no parity)
	mem_write_l UART0_IMSC, 11111110010b	; mask all interrupts
	mem_write_l UART0_CR,	1100000001b	; enable UART0, receive & transfer part of UART
	bx	lr

; writes null-terminated strting to UART0
; r1 - string pointer
uart0_puts:
	mov32	r3, UART0_DR
	mov32	r4, UART0_FR

putc_loop:
	ldr	r0, [r4]	; wait for UART0 to be ready
	tst	r0, 0x20
	bne	putc_loop
	ldrb	r2, [r1]	; char = *str
	cmp	r2, 0		; jump to end if char == 0
	beq	uart0_puts_end
	str	r2, [r3]	; *UART0_DR = char
	add	r1, r1, 1	; str++
	b	putc_loop
uart0_puts_end:
	bx	lr

message:
	db	"Hello, World!", 13, 10 ; "\r\n"
	db	0
