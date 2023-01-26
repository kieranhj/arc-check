; ============================================================================
; Checkerboard rows.
; ============================================================================

.equ Rows_Width, 512
.equ Rows_Height, 512
.equ Check_Width, 320
.equ Row_dx, 3276           ; 0.05<<16

.equ Check_Layers, 6
.equ Check_Combos, (1 << Check_Layers)

; Each line represents a distance from the camera.

check_rows_table:
    .long check_rows_pixel_0_no_adr
    .long check_rows_pixel_1_no_adr
    .long check_rows_pixel_2_no_adr
    .long check_rows_pixel_3_no_adr
    .long check_rows_pixel_4_no_adr
    .long check_rows_pixel_5_no_adr
    .long check_rows_pixel_6_no_adr
    .long check_rows_pixel_7_no_adr

; R1=dx [16.16]
; R4=pixel shift.
; R11=buffer addr.
; Trashes: r0,r2,r3,r5,r9,r10
plot_check_row:
    ; Centre of row is centre of check.
    mov r0, #Check_Width<<15        ; [16.16]
    mov r3, #0x0                    ; pixel
    mov r5, #Check_Width<<16        ; [16.16]

    ; Step back half a row to find x at start.
    mov r9, #Rows_Width/2
    sub r9, r9, r4
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

; R4 = pixel shift.
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

check_rows_init:
    str lr, [sp, #-4]!

    mov r4, #0
.1:
    adr r0, check_rows_table
    ldr r11, [r0, r4, lsl #2] 
    bl make_check_rows
    add r4, r4, #1
    cmp r4, #8
    blt .1

    ldr pc, [sp], #4


; R8=parity 0x00000000 or 0xffffffff
; R9=check row src.
; R10=colour word.
; R12=dest line buffer.
; Trashes: r0-r7
plot_check_line:
.rept 10
    ldmia r9!, {r0-r3}      ; load 4 words of source (all bits set for a pixel, so 0xabcdefg where each=0x0 or 0xf)
    ; 8c
    eor r0, r0, r8
    eor r1, r1, r8
    eor r2, r2, r8
    eor r3, r3, r8
    ; 4c
    ldmia r12, {r4-r7}      ; load 4 words of screen
    ; 8c
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r0, r0, r10        ; mask colour with source word
    orr r4, r4, r0         ; mask in colour word
    ; 3c
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r1, r1, r10        ; mask colour with source word
    orr r5, r5, r1         ; mask in colour word
    ; 3c
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r2, r2, r10        ; mask colour with source word
    orr r6, r6, r2         ; mask in colour word
    ; 3c
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r3, r3, r10        ; mask colour with source word
    orr r7, r7, r3         ; mask in colour word
    ; 3c
    stmia r12!, {r4-r7}     ; write 4 words back to screen
    ; 8c
.endr
    ; 40c per iteration.
    ; 400c per line.
    mov pc, lr

; R12=dest line buffer.
; Trashes r0-r3
plot_blank_line:
    mov r0, #0
    mov r1, r0
    mov r2, r0
    mov r3, r0
.rept 10
    stmia r12!, {r0-r3}
.endr
    mov pc, lr

check_line_combo_p:
    .long check_line_combos

check_layer_x_pos:
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16

check_layer_y_pos:
    .long 0 << 16
    .long 1 << 16
    .long 2 << 16
    .long 3 << 16
    .long 4 << 16
    .long 5 << 16
    .long 6 << 16
    .long 7 << 16

check_layer_z_pos:
    .long 160 << 16
    .long 128 << 16
    .long 96 << 16
    .long 64 << 16
    .long 32 << 16
    .long 8 << 16

; R12 = screen addr (for now)
plot_check_line_combos:
    str lr, [sp, #-4]!
    ; ldr r12, check_line_combo_p
    ; TEMP: Plot to screen for debug.
    str r12, check_line_combo_p

    ; Blank all line combos.
    mov r11, #Check_Combos
.1:
    bl plot_blank_line
    subs r11, r11, #1
    bne .1

    ; For each layer, plot appropriate line 2^N times.
    mov r10, #0x1
.2:
    ; R12=dest line buffer.
    ldr r12, check_line_combo_p

    ; R9=check row src.
    ; Compute from x and z for layer.
    adr r4, check_layer_x_pos-4
    ldr r0, [r4, r10, lsl #2]           ; [16.16]
    mov r0, r0, lsr #16                 ; [16.0]

    and r2, r0, #7                      ; pixel shift [0-7]
    bic r0, r0, #7                      ; word shift

    adr r9, check_rows_table
    ldr r9, [r9, r2, lsl #2]            ; select check rows for shift 
    add r9, r9, r0, lsr #1              ; X word

    adr r5, check_layer_z_pos-4
    ldr r1, [r5, r10, lsl #2]           ; [16.16]
    mov r1, r1, lsr #16

    ; Add Rows_Width * z_pos
    add r9, r9, r1, lsl #9              ; z * 512

    ; Convert layer number into colour word.
    ; R10=colour word.
    orr r10, r10, r10, lsl #4
    orr r10, r10, r10, lsl #8
    orr r10, r10, r10, lsl #16

    ; Combo #
    mov r11, #0
.3:
    ; R8=parity 0x00000000 or 0xffffffff
    and r1, r10, #0xf
    sub r1, r1, #1              ; layer
    mov r2, #1
    ands r0, r11, r2, lsl r1    ; parity = combo & (1 << layer)
    moveq r8, #0x00000000
    movne r8, #0xffffffff

    ; Plot the check row for this layer & parity.
    bl plot_check_line          ; 400c

    ; Reset R9 (repeat this line for all combos)
    sub r9, r9, #Screen_Stride

    ; Next line in the combo.
    add r11, r11, #1
    cmp r11, #Check_Combos
    blt .3

    ; 400c * 2^4 = 6400c
    ; 400c * 2^5 = 12800c
    ; 400c * 2^6 = 51200c

    ; Retrieve layer.
    and r10, r10, #0xf
    add r10, r10, #1
    cmp r10, #Check_Layers
    ble .2

    ; 6400c * 4 = 25600c
    ; 12800c * 5 = 64000c
    ; 51200c * 6 = 307200c <= but this seems to be less than a frame on real hw?

    ldr pc, [sp], #4
