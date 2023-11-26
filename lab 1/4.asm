ORG 0x7C00  ; Set the origin for the program at memory address 0x7C00

; Setup segment registers
mov AX, DS   ; Move the data segment (DS) value into AX register
mov ES, AX   ; Copy that value into the extra segment (ES) register

; Call various methods to print characters to the screen
call Method_a    ; Call the method that prints 'h' using BIOS interrupt
call NextRow     ; Move the cursor to the next row on the screen

call Method_b    ; Call the method that prints 'e' using BIOS interrupt
call NextRow     ; Move the cursor to the next row on the screen

call Method_c    ; Call the method that prints 'l' using BIOS interrupt
call NextRow     ; Move the cursor to the next row on the screen

call Method_d    ; Call the method that prints the second 'l' using BIOS interrupt
call NextRow     ; Move the cursor to the next row on the screen

call Method_e    ; Call the method that prints 'o' using BIOS interrupt
call NextRow     ; Move the cursor to the next row on the screen

call Method_str1  ; Call the method to print the string "nice"
call NextRow      ; Move the cursor to the next row on the screen

call Method_str2  ; Call the method to print the string "race"
call NextRow      ; Move the cursor to the next row on the screen

call M8           ; Call the new method to print "hello" directly to video memory
call NextRow      ; Move to next row after M8

; Infinite loop to hang the program
hang:
    jmp hang      ; Jump to 'hang' label indefinitely

; Method definitions to print characters on the screen
Method_a:
    mov AH, 0Eh       ; Function 0Eh - Teletype output
    mov AL, 'h'       ; Move character 'h' into AL
    int 10h           ; BIOS interrupt to print character in AL
    ret               ; Return from the method

Method_b:
    mov AH, 0aH       ; Function 0Ah - Write character at cursor position
    mov AL, 'e'       ; Move character 'e' into AL
    int 10h           ; BIOS interrupt to print character in AL
    ret               ; Return from the method

Method_c:
    mov AH, 09h       ; Function 09h - Write character and attribute at cursor position
    mov AL, 'l'       ; Move character 'l' into AL
    mov BH, 0         ; Page number (usually 0)
    mov BL, 0x07      ; Attribute for the character (light grey on black)
    mov CX, 1         ; Number of times to write the character (1 time)
    int 10h           ; BIOS interrupt to print character in AL
    ret               ; Return from the method

Method_d:
    mov AH, 13h       ; Function 13h - Write string of characters
    mov AL, 2         ; Write mode (2 = move cursor after writing)
    mov BH, 0         ; Page number
    mov BL, 0x1E      ; Attribute (yellow on blue)
    mov DH, 4         ; Row position to start writing
    mov DL, 0         ; Column position to start writing
    mov CX, 1         ; Number of characters to write
    lea BP, [Msg_d]   ; Load effective address of message 'l' into BP
    int 10h           ; BIOS interrupt to print string pointed to by BP
    ret               ; Return from the method

Method_e:
    mov AH, 13h       ; Function 13h - Write string of characters
    mov AL, 3         ; Write mode (3 = update cursor position only)
    mov BH, 0         ; Page number
    mov BL, 0x2E      ; Attribute (green on red)
    mov DH, 5         ; Row position to start writing
    mov DL, 0         ; Column position to start writing
    mov CX, 1         ; Number of characters to write
    lea BP, [Msg_e]   ; Load effective address of message 'o' into BP
    int 10h           ; BIOS interrupt to print string pointed to by BP
    ret               ; Return from the method

Method_str1:
    mov AH, 13h       ; Function 13h - Write string of characters
    mov AL, 1         ; Write mode (1 = update cursor, write string, and handle tabs)
    mov BH, 0         ; Page number
    mov BL, 0x07      ; Attribute (light grey on black)
    mov DH, 8         ; Row position to start writing
    mov DL, 0         ; Column position to start writing
    lea BP, Msg_str1  ; Load effective address of message "nice" into BP
    mov CX, 8         ; Number of characters to write (8, includes attribute bytes)
    int 10h           ; BIOS interrupt to print string pointed to by BP
    ret               ; Return from the method

Method_str2:
    mov AH, 13h       ; Function 13h - Write string of characters
    mov AL, 1         ; Write mode (1 = update cursor, write string, and handle tabs)
    mov BH, 0         ; Page number
    mov BL, 0x07      ; Attribute (light grey on black)
    mov DH, 10        ; Row position to start writing
    mov DL, 0         ; Column position to start writing
    lea BP, Msg_str2  ; Load effective address of message "race" into BP
    mov CX, 8         ; Number of characters to write (8, includes attribute bytes)
    int 10h           ; BIOS interrupt to print string pointed to by BP
    ret               ; Return from the method

NextRow:
    mov AH, 02h       ; Function 02h - Set cursor position
    mov BH, 0         ; Page number
    inc DH            ; Increment row (move cursor down one line)
    mov DL, 0         ; Reset column to 0 (start of the line)
    int 10h           ; BIOS interrupt to set cursor position
    ret               ; Return from the method

; Define messages with their attributes
Msg_d db 'l',  0x23   ; Message 'l' with attribute byte (foreground and background color)
Msg_e db 'o',  0x12   ; Message 'o' with attribute byte
Msg_str1 db 'n', 0x07, 'i', 0x07, 'c', 0x07, 'e', 0x07  ; Message "nice" with attributes
Msg_str2 db 'r', 0x07, 'a', 0x07, 'c', 0x07, 'e', 0x07  ; Message "race" with attributes

M8:
    ; Directly write to video memory to print "hello"
    mov ax, 0xB800    ; Move the video memory segment address into AX
    mov es, ax        ; Set Extra Segment (ES) to point to video memory
    mov di, 1920      ; DI register points to the 8th row (0-based index, 160 bytes per row, 8*160=1280)

    ; Writing the letters of "hello" to video memory with attributes
    mov ax, 0x0720 | 'h'  ; AH = attribute (grey on black), AL = 'h'
    mov es:[di], ax       ; Store the character 'h' at the current position in video memory
    add di, 2             ; Move to the next cell (2 bytes per cell)

    ; Repeat for the remaining letters 'e', 'l', 'l', 'o'
    mov ax, 0x0720 | 'e'
    mov es:[di], ax
    add di, 2

    mov ax, 0x0720 | 'l'
    mov es:[di], ax
    add di, 2

    mov ax, 0x0720 | 'l'
    mov es:[di], ax
    add di, 2

    mov ax, 0x0720 | 'o'
    mov es:[di], ax
    ret  ; Return from method after writing "hello"
