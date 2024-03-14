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

		mov		r1, SCREEN_X / 8 * (SCREEN_Y - 1)
		adr		r2, picture + 0x3e
		mov		r4, SCREEN_Y
show_picture_02:
		mov		r3, SCREEN_X / 8
show_picture_01:
		ldr	r5, [r2]
		rbit	r5, r5
		rev		r5,  r5
		str	r5, [r0, r1]
		add		r1, 4
		add		r2, 4
		subs	r3, 4
		bne		show_picture_01
		sub		r1, SCREEN_X / 8 * 2
		subs	r4, 1
		bne		show_picture_02

finish:
        b       finish          ; В конце программы зацикливаем строку саму на себя

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

picture:
		file	"cuphead_640x480_1bpp.bmp"
