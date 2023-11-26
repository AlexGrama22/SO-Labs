[org 0x7C00]    ; Origin set to 0x7C00, the memory address where BIOS loads the boot sector
[bits 16]       ; We are operating in 16-bit real mode

; Define constants
MAX_INPUT EQU 256
BUFFER_OFFSET EQU 0x8000  ; Offset for the buffer starting after the boot sector

; Entry point
start:
    cli                     ; Clear interrupts
    xor ax, ax              ; Initialize AX
    mov ds, ax              ; Initialize DS to 0
    mov es, ax              ; Initialize ES to 0
    mov fs, ax              ; Initialize FS to 0
    mov gs, ax              ; Initialize GS to 0
    mov ss, ax              ; Initialize SS to 0
    mov sp, 0xFFFF          ; Set stack pointer
    sti                     ; Set interrupts

    ; Set video mode to 80x25 text mode
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    mov si, BUFFER_OFFSET   ; SI points to the start of the buffer
    mov [si], byte 0        ; Clear the buffer

read_key:
    ; Check if we've reached 256 characters
    mov di, si
    sub di, BUFFER_OFFSET
    cmp di, MAX_INPUT
    je stop_input

    ; Get key from keyboard
    xor ah, ah
    int 0x16                ; Wait for key press

    ; Check for Enter key (0x1C is the scan code for Enter)
    cmp ah, 0x1C
    je handle_enter

    ; Check for Backspace key (0x0E is the scan code for Backspace)
    cmp ah, 0x0E
    je handle_backspace

    ; Save the key to the buffer and echo it
    mov [si], al
    inc si                  ; Move buffer pointer
    mov ah, 0x0E
    int 0x10                ; Display the character

    jmp read_key            ; Read next key

handle_enter:
    mov di, si
    sub di, BUFFER_OFFSET
    test di, di             ; Test if any characters have been input
    jz clear_buffer         ; If not, clear buffer and print newlines

    ; Move to a new line and print the input string
    call print_newline
    call print_newline      ; Print an extra empty line for spacing
    mov di, BUFFER_OFFSET   ; Reset DI to the start of the buffer
    call print_string

clear_buffer:
    ; Clear the buffer after printing or if it's empty
    call clear_input_buffer

    ; Print newlines for spacing after clearing buffer or printing string
    call print_newline
    call print_newline

    jmp read_key            ; Read next key

clear_input_buffer:
    ; Subroutine to clear the input buffer
    mov di, BUFFER_OFFSET   ; Point to the start of the buffer
    mov cx, MAX_INPUT       ; Number of bytes to clear
    mov al, 0               ; Value to set (0)
    rep stosb               ; Clear the buffer using STOSB
    mov si, BUFFER_OFFSET   ; Reset SI to the start of the buffer
    ret


handle_backspace:
    ; Check if we're at the start position
    cmp si, BUFFER_OFFSET
    je read_key             ; If at start, do nothing

    dec si                  ; Move back the buffer pointer
    mov byte [si], 0        ; "Erase" the character in the buffer by setting it to zero
    call move_cursor_back   ; Move cursor back and erase character on screen
    jmp read_key            ; Read next key


stop_input:
    ; In case of 256 character limit, wait for Enter or Backspace
    xor ah, ah
    int 0x16                ; Wait for key press
    cmp ah, 0x1C            ; Check for Enter
    je handle_enter
    cmp ah, 0x0E            ; Check for Backspace
    je handle_backspace
    jmp stop_input          ; Otherwise, ignore the key and check again

print_newline:
    ; Subroutine to print a newline
    mov ah, 0x0E
    mov al, 0x0A            ; Line Feed
    int 0x10
    mov al, 0x0D            ; Carriage Return
    int 0x10
    ret

move_cursor_back:
    ; Subroutine to move cursor back and overwrite character with space
    mov ah, 0x0E
    mov al, 0x08            ; Backspace
    int 0x10
    mov al, ' '             ; Space
    int 0x10
    mov al, 0x08            ; Backspace
    int 0x10
    ret

print_string:
    ; Subroutine to print a string
    .print_char:
        mov al, [di]         ; Load byte into AL
        or al, al            ; Test if bytedsd is zero (end of string)
        jz .done             ; If zero, we are done
        mov ah, 0x0E
        int 0x10             ; Print character
        inc di               ; Move to next character
        jmp .print_char
    .done:
        ret

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
