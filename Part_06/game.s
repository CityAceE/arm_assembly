; Макросы
macro   mov32   reg, value {
        ldr     reg, [pc]
        b       @f
        dw      value
@@:
}

        format  binary as 'img'

        org     0x10000

        mov     sp, 0x8000

        bl      fb_setup

        bl      strips

dead_loop:
        b       dead_loop   ; Конец программы: зацикливаем процедуру

strips:
        push    {lr}
        ldr     r0, [FRAMEBUFFER]
        mov     r1, (SCREEN_X * SCREEN_Y)
        mov32   r3, 0x00020406
        mov32   r4, 0x01030507

strips_01:        
        str     r3, [r0]
        add     r0, 4
        str     r4, [r0]
        add     r0, 4
        subs    r1, 8
        bne     strips_01
        pop     {pc}


; Константы и переменные, необходимые для инициализации Frame Buffer
PERIPHERAL_BASE	        = 0x20000000 ; Peripheral Base Address
MAIL_TAGS    			= 0x8 		 ; Mailbox Channel 8: Tags (ARM to VC)
MAIL_BASE   			= 0xB880 	 ; Mailbox Base Address
MAIL_WRITE  			= 0x20 		 ; Mailbox Write Register
SCREEN_X                = 640
SCREEN_Y                = 480
BITS_PER_PIXEL          = 8
Set_Physical_Display  	= 0x00048003 ; Frame Buffer: Set Physical (Display) Width/Height (Response: Width In Pixels, Height In Pixels)
Set_Virtual_Buffer    	= 0x00048004 ; Frame Buffer: Set Virtual (Buffer) Width/Height (Response: Width In Pixels, Height In Pixels)
Set_Depth             	= 0x00048005 ; Frame Buffer: Set Depth (Response: Bits Per Pixel)
Set_Virtual_Offset    	= 0x00048009 ; Frame Buffer: Set Virtual Offset (Response: X In Pixels, Y In Pixels)
Set_Palette           	= 0x0004800B ; Frame Buffer: Set Palette (Response: RGBA Palette Values (Index 0 To 255))
Allocate_Buffer       	= 0x00040001 ; Frame Buffer: Allocate Buffer (Response: Frame Buffer Base Address In Bytes, Frame Buffer Size In Bytes)


; Инициализация Frame Buffer (экранное ОЗУ)
fb_setup:
        push    {lr}
fb_setup_01:
        mov32   r0, mb_message + MAIL_TAGS	; FB_STRUCT + MAIL_TAGS
        mov32   r1, PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS	; PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
        str     r0, [r1] ; Mail Box Write

        ldr     r0, [FRAMEBUFFER] ; R0 = Frame Buffer Pointer
        cmp     r0, 0 ; Compare Frame Buffer Pointer To Zero
        beq     fb_setup_01 ; IF Zero Re-Initialize Frame Buffer
        and     r0, 0x3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
        str     r0, [FRAMEBUFFER] ; Store Frame Buffer Pointer Physical Address
        pop    {pc}

align 16
mb_message: ; Mailbox Property Interface Buffer Structure
        dw      mb_message_end - mb_message ; Buffer Size In Bytes (Including The Header Values, The End Tag And Padding)
        dw      0x00000000 ; Buffer Request/Response Code
        ; Request Codes: $00000000 Process Request Response Codes: $80000000 Request Successful, $80000001 Partial Response
        ; Sequence Of Concatenated Tags
        dw      Set_Physical_Display ; Tag Identifier
        dw      0x00000008 ; Value Buffer Size In Bytes
        dw      0x00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
        dw      SCREEN_X ; Value Buffer
        dw      SCREEN_Y ; Value Buffer

        dw      Set_Virtual_Buffer ; Tag Identifier
        dw      0x00000008 ; Value Buffer Size In Bytes
        dw      0x00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
        dw      SCREEN_X ; Value Buffer
        dw      SCREEN_Y ; Value Buffer

        dw      Set_Depth ; Tag Identifier
        dw      0x00000004 ; Value Buffer Size In Bytes
        dw      0x00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
        dw      BITS_PER_PIXEL ; Value Buffer

        dw      Set_Virtual_Offset ; Tag Identifier
        dw      0x00000008 ; Value Buffer Size In Bytes
        dw      0x00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
        dw      0 ; Value Buffer
        dw      0 ; Value Buffer

        dw      Set_Palette ; Tag Identifier
        dw      0x00000048 ; Value Buffer Size In Bytes (8 + (16 palette entries * 4)
        dw      0x00000048 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
        dw      0 ; Value Buffer (Offset: First Palette Index To Set (0-255))
        dw      16 ; Value Buffer (Length: Number Of Palette Entries To Set (1-256))

; Палитра 16 цветов, похожая на ZX Spectrum
        ; RGBA Palette Values (Offset To Offset+Length-1)
        ;        R     G     B     Alpha
        db      0x00, 0x00, 0x00, 0x00	; 0x00 Black
        db      0x00, 0x00, 0xbf, 0x00	; 0x01 Blue
        db      0xbf, 0x00, 0x00, 0x00	; 0x02 Red
        db      0xbf, 0x00, 0xbf, 0x00	; 0x03 Magenta
        db      0x00, 0xbf, 0x00, 0x00	; 0x04 Green
        db      0x00, 0xbf, 0xbf, 0x00	; 0x05 Cyan
        db      0xbf, 0xbf, 0x00, 0x00	; 0x06 Yellow
        db      0xbf, 0xbf, 0xbf, 0x00	; 0x07 White

        db      0x00, 0x00, 0x00, 0x00	; 0x08 Black Bright
        db      0x00, 0x00, 0xff, 0x00	; 0x09 Blue Bright
        db      0xff, 0x00, 0x00, 0x00	; 0x0A Red Bright
        db      0xff, 0x00, 0xff, 0x00	; 0x0B Magenta Bright
        db      0x00, 0xff, 0x00, 0x00	; 0x0C Green Bright
        db      0x00, 0xff, 0xff, 0x00	; 0x0D Cyan Bright
        db      0xff, 0xff, 0x00, 0x00	; 0x0E Yellow Bright
        db      0xff, 0xff, 0xff, 0x00	; 0x0F White Bright

        dw      Allocate_Buffer ; Tag Identifier
        dw      0x00000008 ; Value Buffer Size In Bytes
        dw      0x00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FRAMEBUFFER:
        dw      0 ; Value Buffer
        dw      0 ; Value Buffer

        dw      0x00000000 ; $0 (End Tag)
mb_message_end:
