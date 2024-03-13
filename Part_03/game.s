; Макросы
macro   mov32   reg, immediate {
        mov     reg, immediate and 0x0000ffff   ; Вычленяем нижнюю половину слова
        movt    reg, immediate / 0x10000        ; Вычленяем верхнюю половину слова
}

FRAMEBUFF = 0x60020000
SCREEN_X = 640
SCREEN_Y = 480

; Начало программы
        org     0x6001000       ; Адрес компиляции и запуска

        bl      display_setup

        mov     r2, (SCREEN_X / 8 / 2 - (zxfont - text) / 2) + (SCREEN_Y / 2 * SCREEN_X / 8)
        adr     r6, text
print_string_01:
        ldrb	r1, [r6]
		cmp		r1, 0
		beq     finish
		bl		print_symbol
		add		r2, 1
		add		r6, 1
		b		print_string_01

finish:
        b       finish          ; В конце программы зацикливаем строку саму на себя

; Печать символа
; R1 - код символа
; R2 - сдвиг во frame buffer
print_symbol:
        mov     r7, r2
        lsl		r1, 3
		adr		r3, zxfont - 32 * 8
		mov32	r4, 8
print_symbol_01:
		ldrb	r5, [r3, r1]
        rbit    r5, r5
        mvn     r5, r5, lsr 24
		strb	r5, [r0, r2]
		add		r2, SCREEN_X / 8
		add		r1, 1
		subs 	r4, 1
		bne		print_symbol_01
        mov     r2, r7
        bx      lr

; Инициализация дисплея PL111
; На выходе в R0 адрес framebuffer
display_setup:
		mov32	r1, 0x10020000	; LCD control registers base address

		;Установка разрешения 640x480
		mov32	r2, 0x3F1F3F9C	; LCDTiming0
		str		r2, [r1, 0x0]	; Horizontal Axis Panel Control Register

		mov32	r2, 0x090B61DF	; LCDTiming1
		str		r2, [r1, 0x4]	; Vertical Axis Panel Control Register

		mov32	r2, 0x067F1800	; LCDTiming2
		str		r2, [r1, 0x8]	; Clock and Signal Polarity Control Register

		; Установка адреса кадрового буфера
		ldr 	r0, [framebuff]
		str		r0, [r1, 0x10]	; Upper and Lower Panel Frame Base Address Registers

		; Установка режима цветности
		mov		r2, 0x0821		; 1bpp
		str		r2, [r1, 0x18]	; LCD Control Register

		; Установка ч/б палитры
		mov		r2, 0x0000		; Цвет 0 - чёрный
		movt	r2, 0xffff		; Цвет 1 - белый
		str		r2, [r1, 0x200]	; Color Palette Register Base

        bx		lr

framebuff:
        dw		FRAMEBUFF

text:
		db		"Hello, World!"
        db      0                  ; Маркер конца строки
zxfont:
		file	"zxfont.bin"
