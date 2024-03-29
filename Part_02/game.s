; Макросы
macro   mov32   reg, immediate {
        mov     reg, immediate and 0x0000ffff   ; Вычленяем нижнюю половину слова
        movt    reg, immediate / 0x10000        ; Вычленяем верхнюю половину слова
}
        
; Начало программы
        org     0x6001000       ; Адрес компиляции и запуска
        
        mov32   r0, 0x10009000  ; Загружаем в регистр r0 адрес консоли
        adr     r1, text        ; Загружаем в регистр r1 адрес начала текста
        mov     r2, 0           ; Обнуляем счётчик в регистре r2

loop:
        ldrb    r3, [r1, r2]    ; Загружаем в регистр r3 код следующего символа надписи
        cmp     r3, 0           ; Сравниваем код символа с кодом перевода строки
        beq     finish
        strb    r3, [r0]        ; Выводим в консоль код символа из регистра r3
        add     r2, 1           ; Увеличиваем счётчик на единицу
        b       loop            ; Переходим к следующему символу, если код символа не равен коду перевода
        
finish:
        b       finish          ; В конце программы зацикливаем строку саму на себя

text:
        db      "Hello, World!" ; Выводимый текст
        db      0               ; Маркер конца текста
