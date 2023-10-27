ORG 0x7C00

mov AX, DS
mov ES, AX

call Method_a
call NextRow

call Method_b
call NextRow

call Method_c
call NextRow

call Method_d
call NextRow

call Method_e
call NextRow

call Method_str1
call NextRow

call Method_str2
call NextRow

call M8             ; Call the new method to print "hello" directly to video memory
call NextRow        ; Move to next row after M8

hang:
    jmp hang

Method_a:
    mov AH, 0Eh
    mov AL, 'h'
    int 10h
    ret

Method_b:
    mov AH, 0aH
    mov AL, 'e'
    int 10h
    ret

Method_c:
    mov AH, 09h  
    mov AL, 'l'  
    mov BH, 0    
    mov BL, 0x07 
    mov CX, 1    
    int 10h      
    ret          

Method_d:
    mov AH, 13h
    mov AL, 2
    mov BH, 0
    mov BL, 0x1E
    mov DH, 4
    mov DL, 0
    mov CX, 1
    lea BP, [Msg_d]
    int 10h
    ret

Method_e:
    mov AH, 13h
    mov AL, 3
    mov BH, 0
    mov BL, 0x2E
    mov DH, 5
    mov DL, 0
    mov CX, 1
    lea BP, [Msg_e]
    int 10h
    ret

Method_str1:
    mov AH, 13h
    mov AL, 1
    mov BH, 0
    mov BL, 0x07
    mov DH, 8
    mov DL, 0
    lea BP, Msg_str1
    mov CX, 8
    int 10h
    ret

Method_str2:
    mov AH, 13h
    mov AL, 1
    mov BH, 0
    mov BL, 0x07
    mov DH, 10
    mov DL, 0
    lea BP, Msg_str2
    mov CX, 8
    int 10h
    ret

NextRow:
    mov AH, 02h
    mov BH, 0
    inc DH
    mov DL, 0
    int 10h
    ret

Msg_d db 'l',  0x23
Msg_e db 'o',  0x12
Msg_str1 db 'n', 0x07, 'i', 0x07, 'c', 0x07, 'e', 0x07
Msg_str2 db 'r', 0x07, 'a', 0x07, 'c', 0x07, 'e', 0x07

M8:
    ; Set ES to video segment
    mov ax, 0xB800
    mov es, ax
    mov di, 1920        ; Set DI to point to the start of the 8th row

    ; Print 'h'
    mov ax, 0x0720 | 'h' ; AH = attribute (grey on black), AL = 'h'
    mov es:[di], ax      ; Store to video memory
    add di, 2            ; Move to next cell

    ; Print 'e'
    mov ax, 0x0720 | 'e'
    mov es:[di], ax
    add di, 2

    ; Print 'l'
    mov ax, 0x0720 | 'l'
    mov es:[di], ax
    add di, 2

    ; Print 'l'
    mov ax, 0x0720 | 'l'
    mov es:[di], ax
    add di, 2

    ; Print 'o'
    mov ax, 0x0720 | 'o'
    mov es:[di], ax
    ret

