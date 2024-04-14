; Макросы
macro	mov32	reg, value {
	ldr	reg, [pc]
	b	@f
	dw	value
@@:
}

; Модели:
; 0 - QEMU
; 1 - Raspberry Pi 1, Raspberry Pi Zero
; 2 - Raspberry Pi 2, Raspberry Pi 3
model = 0

	format	binary as 'img'

if model = 0
	org	0x10000
else	
	org	0x8000
end if	

if model = 2
; Глушим все ядра кроме одного
	; Return CPU ID (0..3) Of The CPU Executed On
	mrc	p15, 0, r0, c0, c0, 5	; R0 = Multiprocessor Affinity Register (MPIDR)
	ands	r0, 3			; R0 = CPU ID (Bits 0..1)
	bne 	dead_loop		; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)
end if

	mov	sp, 0x8000

	bl	fb_setup

	bl	strips
	
	mov32	r1, ((SCREEN_X - (message_end - message) * 8) / 2) + (SCREEN_Y / 2 * SCREEN_X)
	adr	r2, message
	bl	print_string

dead_loop:
if model = 2
	wfe 			; Режим низкого энергопотребления
end if
	b	dead_loop	; Конец программы: зацикливаем процедуру

strips:
	push	{lr}
	mov	r1, (SCREEN_X * SCREEN_Y)
	mov	r2, 0
	mov32	r3, 0x01010404

strips_01:	  
	str	r3, [r0, r2]
	add	r2, 4
	subs	r1, 4
	bne	strips_01
	pop	{pc}

; Печать строки символов
; r1 - адрес на экране
; r2 - адрес текста
print_string:	
	mov	r9, lr
print_string_01:
	ldrb	r3, [r2]
	cmp	r3, 0
	beq	print_string_02
	bl	print_symbol
	add	r1, 8			; Ширина символа в пикселях
	add	r2, 1
	b	print_string_01
print_string_02:
	bx	r9

PAPER 	= 0x0A
INK 	= 0x0E

; Подпрограмма печати символа
; r3 - код символа	
; r1 - адрес во Frame Buffer
print_symbol:
	mov	r4, r1
	; adr	r5, font - 32 * 8	
	ldr	r5, [FONT]
	sub	r5, 32*8		; Адрес начала знакогенератора
	
	add	r5, r3, lsl 3

	mov	r6, 8			; Количество строк в символе
print_symbol_01:
	ldrb	r8, [r5]

	add	r4, 7

	mov	r7, 8			; Количество точек (бит) в байте
print_symbol_02:
	lsrs	r8, 1
	movcc	r3, PAPER
	movcs	r3, INK
	strb	r3, [r0, r4]
	sub	r4, 1
	subs	r7, 1
	bne	print_symbol_02


	add	r4, SCREEN_X
	add	r4, 1			; Следующая линия на экране
	add	r5, 1			; Следующая линия в символе знакогенератора
	
	subs	r6, 1
	bne	print_symbol_01
	
	bx	lr			; Возврат из подпрограммы

; Константы и переменные, необходимые для инициализации Frame Buffer

if model = 2
PERIPHERAL_BASE		= 0x3F000000	; Peripheral Base Address Raspberry Pi 2 & 3
else
PERIPHERAL_BASE		= 0x20000000	; Peripheral Base Address Raspberry Pi 2 & Zero
end if

MAIL_TAGS		= 0x8		; Mailbox Channel 8: Tags (ARM to VC)
MAIL_BASE		= 0xB880	; Mailbox Base Address
MAIL_WRITE		= 0x20		; Mailbox Write Register
SCREEN_X		= 640
SCREEN_Y		= 480
BITS_PER_PIXEL		= 8
Set_Physical_Display	= 0x00048003	; Frame Buffer: Set Physical (Display) Width/Height (Response: Width In Pixels, Height In Pixels)
Set_Virtual_Buffer	= 0x00048004	; Frame Buffer: Set Virtual (Buffer) Width/Height (Response: Width In Pixels, Height In Pixels)
Set_Depth		= 0x00048005	; Frame Buffer: Set Depth (Response: Bits Per Pixel)
Set_Virtual_Offset	= 0x00048009	; Frame Buffer: Set Virtual Offset (Response: X In Pixels, Y In Pixels)
Set_Palette		= 0x0004800B	; Frame Buffer: Set Palette (Response: RGBA Palette Values (Index 0 To 255))
Allocate_Buffer		= 0x00040001	; Frame Buffer: Allocate Buffer (Response: Frame Buffer Base Address In Bytes, Frame Buffer Size In Bytes)

; Инициализация Frame Buffer (экранное ОЗУ)
fb_setup:
	push	{lr}
fb_setup_01:
	mov32	r0, mb_message + MAIL_TAGS	; FB_STRUCT + MAIL_TAGS
	mov32	r1, PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS	; PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
	str	r0, [r1]		; Mail Box Write

	ldr	r0, [FRAMEBUFFER]	; R0 = Frame Buffer Pointer
	cmp	r0, 0 			; Compare Frame Buffer Pointer To Zero
	beq	fb_setup_01 		; IF Zero Re-Initialize Frame Buffer
	and	r0, 0x3FFFFFFF 		; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
	str	r0, [FRAMEBUFFER] 	; Store Frame Buffer Pointer Physical Address
	pop    {pc}

align 16
mb_message: ; Mailbox Property Interface Buffer Structure
	dw	mb_message_end - mb_message ; Buffer Size In Bytes (Including The Header Values, The End Tag And Padding)
	dw	0x00000000 ; Buffer Request/Response Code
	; Request Codes: $00000000 Process Request Response Codes: $80000000 Request Successful, $80000001 Partial Response
	; Sequence Of Concatenated Tags
	dw	Set_Physical_Display ; Tag Identifier
	dw	0x00000008 ; Value Buffer Size In Bytes
	dw	0x00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
	dw	SCREEN_X ; Value Buffer
	dw	SCREEN_Y ; Value Buffer

	dw	Set_Virtual_Buffer ; Tag Identifier
	dw	0x00000008 ; Value Buffer Size In Bytes
	dw	0x00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
	dw	SCREEN_X ; Value Buffer
	dw	SCREEN_Y ; Value Buffer

	dw	Set_Depth ; Tag Identifier
	dw	0x00000004 ; Value Buffer Size In Bytes
	dw	0x00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
	dw	BITS_PER_PIXEL ; Value Buffer

	dw	Set_Virtual_Offset ; Tag Identifier
	dw	0x00000008 ; Value Buffer Size In Bytes
	dw	0x00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
	dw	0 ; Value Buffer
	dw	0 ; Value Buffer

	dw	Set_Palette ; Tag Identifier
	dw	0x00000048 ; Value Buffer Size In Bytes (8 + (16 palette entries * 4)
	dw	0x00000048 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
	dw	0 ; Value Buffer (Offset: First Palette Index To Set (0-255))
	dw	16 ; Value Buffer (Length: Number Of Palette Entries To Set (1-256))

; Палитра 16 цветов, похожая на ZX Spectrum
	; RGBA Palette Values (Offset To Offset+Length-1)
	;	 R     G     B	   Alpha
	db	0x00, 0x00, 0x00, 0x00	; 0x00 Black
	db	0x00, 0x00, 0xbf, 0x00	; 0x01 Blue
	db	0xbf, 0x00, 0x00, 0x00	; 0x02 Red
	db	0xbf, 0x00, 0xbf, 0x00	; 0x03 Magenta
	db	0x00, 0xbf, 0x00, 0x00	; 0x04 Green
	db	0x00, 0xbf, 0xbf, 0x00	; 0x05 Cyan
	db	0xbf, 0xbf, 0x00, 0x00	; 0x06 Yellow
	db	0xbf, 0xbf, 0xbf, 0x00	; 0x07 White

	db	0x00, 0x00, 0x00, 0x00	; 0x08 Black Bright
	db	0x00, 0x00, 0xff, 0x00	; 0x09 Blue Bright
	db	0xff, 0x00, 0x00, 0x00	; 0x0A Red Bright
	db	0xff, 0x00, 0xff, 0x00	; 0x0B Magenta Bright
	db	0x00, 0xff, 0x00, 0x00	; 0x0C Green Bright
	db	0x00, 0xff, 0xff, 0x00	; 0x0D Cyan Bright
	db	0xff, 0xff, 0x00, 0x00	; 0x0E Yellow Bright
	db	0xff, 0xff, 0xff, 0x00	; 0x0F White Bright

	dw	Allocate_Buffer ; Tag Identifier
	dw	0x00000008 ; Value Buffer Size In Bytes
	dw	0x00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FRAMEBUFFER:
	dw	0 ; Value Buffer
	dw	0 ; Value Buffer

	dw	0x00000000 ; $0 (End Tag)
mb_message_end:

message:
	db	"Hello, World!"
message_end:
	db	0	; Маркер конца строки

	align 4
FONT	dw	font
font:
	file	"font_bold.bin"
