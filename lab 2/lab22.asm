[org 0x7C00]         ; Set origin to 0x7C00, where BIOS loads the boot sector
[bits 16]            ; Operate in 16-bit real mode

; Define constants
MAX_CHARS EQU 256    ; Maximum characters the buffer can hold
DATA_BUFFER EQU 0x8000 ; Start address for the data buffer
SCAN_F1_START EQU 0x3B ; Scan code for the start of F1 key
SCAN_F1_END EQU 0x44   ; Scan code for the end of F12 key

; Entry point of the program
boot_start:
    cli             ; Disable interrupts
    xor ax, ax      ; Clear AX register
    mov ds, ax      ; Set DS (Data Segment) register to 0
    mov es, ax      ; Set ES (Extra Segment) register to 0
    mov fs, ax      ; Set FS register to 0
    mov gs, ax      ; Set GS register to 0
    mov ss, ax      ; Set SS (Stack Segment) register to 0
    mov sp, 0xFFFF  ; Set SP (Stack Pointer) to top of the stack
    sti             ; Enable interrupts

    ; Set video mode to 80x25 text mode
    mov ah, 0x00    ; Function code for setting video mode
    mov al, 0x03    ; Video mode: 80x25 text mode
    int 0x10        ; Call video interrupt

    ; Initialize the data buffer
    mov si, DATA_BUFFER ; SI points to buffer start
    mov [si], byte 0   ; Set first byte of buffer to 0

; Main keyboard input loop
keyboard_loop:
    ; Check if the buffer is full
    mov di, si          ; Copy current buffer position to DI
    sub di, DATA_BUFFER ; Calculate buffer size
    cmp di, MAX_CHARS   ; Compare with max buffer size
    je end_input        ; Jump to end_input if buffer is full

    ; Read keyboard input
    xor ah, ah      ; Clear AH register
    int 0x16        ; Call keyboard interrupt

    ; Check for F1-F12 keys
    cmp ah, SCAN_F1_START ; Compare with F1 start scan code
    jae .checkF1End ; If above or equal, possibly an F key
    jmp .processKey ; If not, process the key

    .checkF1End:
    cmp ah, SCAN_F1_END   ; Compare with F1 end scan code
    jbe keyboard_loop     ; If below or equal, it's an F key, ignore

    .processKey:
    ; Process entered key
    cmp ah, 0x1C    ; Check if Enter key was pressed
    je process_enter ; If Enter, go to process_enter

    cmp ah, 0x0E    ; Check if Backspace was pressed
    je process_backspace ; If Backspace, go to process_backspace

    ; Store and display the character
    mov [si], al    ; Store character in buffer
    inc si          ; Increment buffer pointer
    mov ah, 0x0E    ; Teletype output function
    int 0x10        ; Call video interrupt to display character

    jmp keyboard_loop ; Continue keyboard loop

; Function to handle Enter key press
process_enter:
    mov di, si             ; Copy buffer index to DI
    sub di, DATA_BUFFER    ; Calculate the number of characters in the buffer
    test di, di            ; Check if buffer has any input
    jz reset_buffer        ; If buffer is empty, jump to reset_buffer to clear it

    ; Print the buffer content
    call newline           ; Call newline function to move to the next line
    call newline           ; Call newline again for additional line spacing
    mov di, DATA_BUFFER    ; Reset DI to the start of the buffer
    call display_string    ; Call display_string to print the buffer content

reset_buffer:
    ; Clear the buffer
    call clear_buffer      ; Call clear_buffer function to clear the buffer

    ; Print new lines for spacing
    call newline           ; Call newline function to move to the next line
    call newline           ; Call newline again for additional line spacing

    jmp keyboard_loop      ; Jump back to the main keyboard input loop

clear_buffer:
    ; Subroutine to clear the buffer
    mov di, DATA_BUFFER    ; Set DI to the start of the buffer
    mov cx, MAX_CHARS      ; Set CX to the maximum number of characters in the buffer
    mov al, 0              ; Set AL to 0 (the value to clear the buffer with)
    rep stosb              ; Use STOSB to repeatedly store AL at DI, incrementing DI each time
    mov si, DATA_BUFFER    ; Reset SI to the start of the buffer
    ret                    ; Return from the subroutine

process_backspace:
    ; Handle the Backspace key
    cmp si, DATA_BUFFER    ; Compare buffer index to buffer start
    je keyboard_loop       ; If at the start, jump back to keyboard_loop (nothing to delete)

    mov byte [si], 0       ; Clear the character in the buffer at current position
    call cursor_back       ; Call cursor_back to move the cursor back one position
    jmp keyboard_loop      ; Jump back to keyboard_loop for next key

end_input:
    ; Handle the situation when the buffer is full
    xor ah, ah             ; Clear AH register
    int 0x16               ; Wait for key press using keyboard interrupt
    cmp ah, 0x1C           ; Check if Enter key is pressed
    je process_enter       ; If Enter, jump to process_enter
    cmp ah, 0x0E           ; Check if Backspace key is pressed
    je process_backspace   ; If Backspace, jump to process_backspace
    jmp end_input          ; If another key, repeat end_input

newline:
    ; Print newline characters
    mov ah, 0x0E           ; Function code for teletype output
    mov al, 0x0A           ; ASCII code for line feed
    int 0x10               ; Call video interrupt
    mov al, 0x0D           ; ASCII code for carriage return
    int 0x10               ; Call video interrupt again
    ret                    ; Return from the subroutine

cursor_back:
    ; Move cursor back
    cmp si, DATA_BUFFER    ; Compare buffer index with buffer start
    je .buffer_start       ; If at start, jump to buffer_start label (do nothing)
    dec si                 ; Decrement buffer index
    mov byte [si], 0       ; Clear the character at the new buffer position

    ; Get current cursor position
    mov ah, 0x03           ; Function code to get cursor position
    xor bh, bh             ; Set page number to 0
    int 0x10               ; Call BIOS interrupt for cursor position

    ; Check line start
    cmp dl, 0              ; Compare current column position with line start
    je .new_line           ; If at start of line, jump to new_line label

    ; Move cursor back
    dec dl                 ; Decrement column position
    jmp .update_cursor     ; Jump to update_cursor label to update cursor position

.new_line:
    ; Handle new line
    mov dl, 79             ; Set column position to end of line
    cmp dh, 0              ; Compare row position with top of screen
    je .buffer_start       ; If at top, jump to buffer_start (do nothing)
    dec dh                 ; Decrement row position (move up one line)

.update_cursor:
    ; Update cursor position
    mov ah, 0x02           ; Function code to set cursor position
    xor bh, bh             ; Set page number to 0
    int 0x10               ; Call BIOS interrupt to set cursor position

    ; Erase character and move back
    mov ah, 0x0E           ; Function code for teletype output
    mov al, ' '            ; Space character (used to erase)
    int 0x10               ; Call video interrupt to display space
    mov ah, 0x02           ; Function code to set cursor position
    mov bh, 0              ; Set page number to 0
    int 0x10               ; Call BIOS interrupt again to set cursor position

    jmp .done              ; Jump to done label

.buffer_start:
    ; Handle start of buffer
    nop                    ; No operation (used when at the start of the buffer)

.done:
    ret                    ; Return from cursor_back subroutine

display_string:
    ; Display string subroutine
    .print_char:
        mov al, [di]       ; Load character from buffer into AL
        or al, al          ; Logical OR AL with itself (to set zero flag if AL is zero)
        jz .done           ; If AL is zero (end of string), jump to done label
        mov ah, 0x0E       ; Function code for teletype output
        int 0x10           ; Call video interrupt to display character
        inc di             ; Increment DI to point to next character
        jmp .print_char    ; Jump back to start of print_char label
    .done:
        ret                ; Return from display_string subroutine

; Boot signature
times 510-($-$$) db 0   ; Fill remainder of boot sector with zeros
dw 0xAA55               ; Boot sector signature at the end