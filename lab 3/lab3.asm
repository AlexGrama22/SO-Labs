[org 0x7C00] ; Boot sector origin
cli             ; Disable interrupts
mov ax, 0x07C0  ; Setup stack segment
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7C00  ; Stack grows down from here
sti             ; Enable interrupts
mov [DriveNumber], dl ; Save the drive number

jmp start ; Jump to start of the program

; Data and strings
String times 512 db 0 ; Buffer for keyboard input
Buffer times 512 db 0 ; General-purpose buffer
DriveNumber db 0
DataStart db "Your data here", 0
START_SECTOR_1 equ 181 ; Start sector for Task 1
END_SECTOR_1 equ 210 ; End sector for Task 1
START_SECTOR_2 equ 451 ; Start sector for Task 2
END_SECTOR_2 equ 480 ; End sector for Task 2
START_SECTOR_3 equ 721 ; Start sector for Task 3
END_SECTOR_3 equ 750 ; End sector for Task 3
MenuPrompt db "Choose an option:", 0Dh,0Ah, "1. Write String to Disk", 0Dh,0Ah, "2. Read from Disk", 0Dh,0Ah, "3. Write RAM Data to Disk", 0Dh,0Ah, "Option: ", 0

start:
    ; Display Menu
    mov si, MenuPrompt
    call DISPLAY_STRING

    ; Wait for user input
    call GET_CHAR
    cmp al, '1'
    je TASK_1
    cmp al, '2'
    je TASK_2
    cmp al, '3'
    je TASK_3

    ; Invalid input, restart
    jmp start

TASK_1:
    CALL READ_STRING
    CALL WRITE_TO_DISK_1
    jmp $

TASK_2:
    CALL READ_FROM_DISK
    CALL DISPLAY_DATA
    jmp $

TASK_3:
    CALL PREPARE_RAM_DATA
    CALL WRITE_TO_DISK_3
    jmp $

; [Insert the subroutine definitions here: READ_STRING, WRITE_TO_DISK_1, READ_FROM_DISK, DISPLAY_DATA, PREPARE_RAM_DATA, WRITE_TO_DISK_3, etc.]

dw 0xAA55 ; Boot signature

; Subroutine Definitions
; Add the definitions for subroutines like READ_STRING, WRITE_TO_DISK_1, DISPLAY_STRING, GET_CHAR, etc.
; For example:

; Display string subroutine
DISPLAY_STRING:
    pusha               ; Save all registers
    mov ah, 0x0E        ; Function for teletype output
.repeat:
    lodsb               ; Load string byte at SI into AL and increment SI
    cmp al, 0           ; Check if the character is the null terminator
    je .done            ; If it's null terminator, we are done
    int 0x10            ; Call BIOS video interrupt
    jmp .repeat         ; Repeat for next character
.done:
    popa                ; Restore all registers
    ret
; Get character input subroutine
GET_CHAR:
    push ax             ; Save AX register
    mov ah, 0x00        ; Function for getting keystroke
    int 0x16            ; Call BIOS keyboard interrupt
    pop ax              ; Restore AX register, AL now contains the character
    ret

; Read string from keyboard
READ_STRING:
    xor bx, bx ; Reset buffer index
    .read_loop:
        mov ah, 0x00 ; BIOS keyboard read
        int 0x16 ; Wait for key press
        cmp al, 0x0D ; Enter key
        je .exit_read
        cmp al, 0x08 ; Backspace
        je .backspace
        mov [String + bx], al ; Store character
        inc bx
        jmp .read_loop
    .backspace:
        dec bx ; Move back in buffer
        jmp .read_loop
    .exit_read:
        mov byte [String + bx], 0 ; Null-terminate string
    ret

; Write string to disk
WRITE_TO_DISK_1:
    mov ah, 0x03 ; Write sectors
    mov al, 1 ; Write one sector at a time
    mov ch, 0 ; Cylinder number
    mov dh, 0 ; Head number
    mov dl, [DriveNumber] ; Drive number
    mov cx, START_SECTOR_1 ; Start sector
    call WRITE_SECTOR
    mov cx, END_SECTOR_1 ; End sector
    call WRITE_SECTOR
    ret

; Read from disk
READ_FROM_DISK:
    mov ah, 0x02 ; Read sectors
    mov al, 1 ; Read one sector at a time
    mov ch, 0 ; Cylinder number
    mov dh, 0 ; Head number
    mov dl, [DriveNumber] ; Drive number
    mov cx, START_SECTOR_2 ; Start sector
    call READ_SECTOR
    mov cx, END_SECTOR_2 ; End sector
    call READ_SECTOR
    ret

; Display data
DISPLAY_DATA:
    mov bx, Buffer 
    mov cx, 512 ; Number of bytes to display
    .display_loop:
        mov al, [bx]
        call DISPLAY_CHAR
        inc bx
        loop .display_loop
    ret

; Prepare RAM Data
PREPARE_RAM_DATA:
    mov si, DataStart
    mov di, Buffer
    mov cx, 512 ; Number of bytes to copy
    rep movsb ; Copy data to buffer
    ret

; Write RAM data to disk
WRITE_TO_DISK_3:
    mov ah, 0x03 ; Write sectors
    mov al, 1 ; Write one sector at a time
    mov ch, 0 ; Cylinder number
    mov dh, 0 ; Head number
    mov dl, [DriveNumber] ; Drive number
    mov cx, START_SECTOR_3 ; Start sector
    call WRITE_SECTOR
    mov cx, END_SECTOR_3 ; End sector
    call WRITE_SECTOR
    ret

READ_SECTOR:
    ; Assume ES:BX points to the buffer
    push ax
    push bx
    push cx
    push dx
    mov bx, Buffer ; Data buffer address
    int 0x13 ; BIOS Disk Service
    jc .error
    pop dx
    pop cx
    pop bx
    pop ax
    ret
.error:
    ; Handle disk error
    pop dx
    pop cx
    pop bx
    pop ax
    ret	

WRITE_SECTOR:
    ; Assume ES:BX points to the buffer
    push ax
    push bx
    push cx
    push dx
    mov bx, Buffer ; Data buffer address
    int 0x13 ; BIOS Disk Service
    jc .error
    pop dx
    pop cx
    pop bx
    pop ax
    ret
.error:
    ; Handle disk error
    pop dx
    pop cx
    pop bx
    pop ax
    ret

DISPLAY_CHAR:
    mov ah, 0x0E ; Teletype output
    int 0x10 ; Video interrupt
    ret	