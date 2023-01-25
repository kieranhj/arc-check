; ============================================================================
; Checkerboard rows.
; ============================================================================

.equ Rows_Width, 320
.equ Rows_Height, 256
.equ Check_Width, 256
.equ Row_dx, 6553           ; 0.1<<16

; Each line represents a distance from the camera.


; R1=dx [16.16]
; R11=buffer addr.
; Trashes: r0,r2,r3,r5,r9,r10
plot_check_row:
    ; Centre of row is centre of check.
    mov r0, #Check_Width<<15        ; [16.16]
    mov r3, #0x0                    ; pixel
    mov r5, #Check_Width<<16        ; [16.16]

    ; Step back half a row to find x at start.
    mov r9, #Rows_Width/2
.3:
    add r0, r0, r1
    cmp r0, r5              ; X>check width?
    subge r0, r0, r5        ; x-=cw
    eorge r3, r3, #0xf      ; pixel^=1
    subs r9, r9, #1
    bne .3
    rsb r0, r0, r5          ; because we've been adding not subtracting dx

    ; Loop words.
    mov r10, #Rows_Width/8  ; word count
.1:
    ; Loop pixels.
    mov r9, #8              ; pixel count
    mov r2, #0              ; accumulated word
.2:
    mov r2, r2, lsr #4      ; make room for next pixel.
    orr r2, r2, r3, lsl #28          ; insert pixel

    add r0, r0, r1          ; x+=dx
    cmp r0, r5              ; X>check width?
    subge r0, r0, r5        ; x-=cw
    eorge r3, r3, #0xf      ; pixel^=1

    subs r9, r9, #1         ; next pixel in word
    bne .2

    str r2, [r11], #4       ; write word

    subs r10, r10, #1       ; next word in row
    bne .1

    mov pc, lr

; R11 = buffer address.
make_check_rows:
    str lr, [sp, #-4]!
    mov r1, #1<<16          ; start at dx=1.0

    ; Loop rows.
    mov r8, #Rows_Height
.1:
    bl plot_check_row
    add r1, r1, #Row_dx       ; dx+=0.05

    subs r8, r8, #1
    bne .1

    ldr pc, [sp], #4
