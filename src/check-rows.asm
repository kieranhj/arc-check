; ============================================================================
; Checkerboard rows.
; Each line represents a distance from the camera.
; 8 copies of all rows for pixel shift from [0-7]
; ============================================================================

.equ Rows_Width_Pixels, 512
.equ Rows_Width_Bytes, Rows_Width_Pixels/2

.equ Check_Num_Depths, 512
.equ Check_Size_Pixels, 320
.equ Check_Depth_dx, 3276           ; 0.05<<16

.equ Check_Layers, 5
.equ Check_Combos, (1 << Check_Layers)

; ========================================================================

; Pointers to the buffers for check rows at each pixel shift.
check_rows_table:
    .long check_rows_pixel_0_no_adr
    .long check_rows_pixel_1_no_adr
    .long check_rows_pixel_2_no_adr
    .long check_rows_pixel_3_no_adr
    .long check_rows_pixel_4_no_adr
    .long check_rows_pixel_5_no_adr
    .long check_rows_pixel_6_no_adr
    .long check_rows_pixel_7_no_adr

check_depths_dx_p:
    .long check_depths_dx_no_adr

check_line_combo_p:
    .long check_line_combos_no_adr

; ========================================================================

; Plot a row's worth of pixels for the depth given by dx, with
; pixel shift [0-7]. Centres the checks in the centre of the row.
; Plot 'Rows_Width_Pixels' pixels , i.e. 'Rows_Width_Bytes' bytes
; written into the buffer pointed to be R11.
; 
; R1=dx [16.16]
; R4=pixel shift.
; R11=buffer addr.
; Trashes: r0,r2,r3,r5,r9,r10
plot_check_row:
    ; Centre of row is centre of check.
    mov r0, #Check_Size_Pixels<<15        ; [16.16]
    mov r3, #0x0                           ; pixel
    mov r5, #Check_Size_Pixels<<16        ; [16.16]

    ; Step back half a row to find x at start.
    mov r9, #Rows_Width_Pixels/2
    sub r9, r9, r4
.3:
    add r0, r0, r1
    cmp r0, r5              ; X>check size?
    subge r0, r0, r5        ; x-=cw
    eorge r3, r3, #0xf      ; pixel^=1
    subs r9, r9, #1
    bne .3
    rsb r0, r0, r5          ; because we've been adding not subtracting dx

    ; Loop words.
    mov r10, #Rows_Width_Pixels/8  ; word count
.1:
    ; Loop pixels.
    mov r9, #8              ; pixel count
    mov r2, #0              ; accumulated word
.2:
    mov r2, r2, lsr #4      ; make room for next pixel.
    orr r2, r2, r3, lsl #28          ; insert pixel

    add r0, r0, r1          ; x+=dx
    cmp r0, r5              ; X>check size?
    subge r0, r0, r5        ; x-=cw
    eorge r3, r3, #0xf      ; pixel^=1

    subs r9, r9, #1         ; next pixel in word
    bne .2

    str r2, [r11], #4       ; write word

    subs r10, r10, #1       ; next word in row
    bne .1

    mov pc, lr

; Plot 'Check_Num_Depths' check rows to the buffer pointed to
; by R11. Starting at dx=1.0 (i.e. check will be 'Check_Size_Pixels'
; wide) and step by Check_Depth_dx for each additional depth.
;
; R4 = pixel shift.
; R11 = buffer address.
make_check_rows:
    str lr, [sp, #-4]!
    mov r1, #1<<16          ; start at dx=1.0

    ldr r6, check_depths_dx_p

    ; Loop rows.
    mov r8, #Check_Num_Depths
.1:
    str r1, [r6], #4        

    bl plot_check_row
    add r1, r1, #Check_Depth_dx     ; dx+=0.05

    subs r8, r8, #1
    bne .1

    ldr pc, [sp], #4

; Make all check rows for all depths at all pixel shifts [0-7].
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

; Plot a screen widths worth of checks to the destination buffer.
; 
; R8=parity 0x00000000 or 0xffffffff
; R9=check row source.
; R10=colour word.
; R12=dest line buffer.
; Trashes: r0-r7
plot_check_line:
.rept Screen_Stride / 16
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

; Plot blank line of screen width.
; R12=dest line buffer.
; Trashes r0-r3
plot_blank_line:
    mov r0, #0
    mov r1, r0
    mov r2, r0
    mov r3, r0
.rept Screen_Stride / 16
    stmia r12!, {r0-r3}
.endr
    mov pc, lr

; Plot the 2^N possible combinations of layers visible based on
; the depth and X position of each layer, starting from the furthest
; away.
;
; Requires plotting (and masking) the checks from each layer 2^N times.
plot_check_line_combos:
    str lr, [sp, #-4]!
    ldr r12, check_line_combo_p

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
    adr r4, check_layer_x_pos-4         ; layer-1
    ldr r0, [r4, r10, lsl #2]           ; [16.16]
    mov r0, r0, lsr #16                 ; [16.0]

    and r2, r0, #7                      ; pixel shift [0-7]
    bic r0, r0, #7                      ; word shift

    adr r9, check_rows_table
    ldr r9, [r9, r2, lsl #2]            ; select check rows for shift 
    add r9, r9, r0, lsr #1              ; X word

    adr r5, check_layer_z_pos-4         ; layer-1
    ldr r1, [r5, r10, lsl #2]           ; [16.16]
    mov r1, r1, lsr #16

    ; Add Rows_Width * z_pos
    .if Rows_Width_Bytes == 256
    add r9, r9, r1, lsl #8              ; z * 256
    .else
    .error "Expected Rows_Width_Bytes to be 256."
    .endif

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

; Copy a line to screen (Screen_Stride bytes).
; R9=source ptr.
; R12=screen addr.
; Trashes: r0-r3
copy_combo_row:
.rept Screen_Stride / 16
    ldmia r9!, {r0-r3}
    stmia r12!, {r0-r3}
.endr
    mov pc, lr

; Plot all checks to the screen based on the Y position for each
; layer. For each scanline we maintain the y value within each layer
; and therefore the 'parity' of the check. Given the parity of all
; layers we select which of the 2^N check combo lines to copy to the
; screen.
; 
; R12=screen addr
plot_checks_to_screen:
    str lr, [sp, #-4]!

    adr r8, check_layer_y_pos
    adr r6, check_layer_running_y
    adr r4, check_layer_dx
    adr r3, check_layer_z_pos
    ldr r2, check_depths_dx_p

    mov r7, #0                  ; parity word.
    mov r5, #1                  ; bit!

    ; Work out y pos and parity for top line of screen.

    mov r10, #0                 ; layer
.1:
    ldr r1, [r8, r10, lsl #2]   ; y pos
.2:
    cmp r1, #Check_Size_Pixels<<16
    subge r1, r1, #Check_Size_Pixels<<16
    eorge r7, r7, r5, lsl r10
    bge .2

    str r1, [r6, r10, lsl #2]   ; running y

    ldr r1, [r3, r10, lsl #2]   ; z pos for layer
    mov r1, r1, lsr #16
    ldr r1, [r2, r1, lsl #2]    ; dx for z pos for layer
    str r1, [r4, r10, lsl #2]   ; store dx for layer

    add r10, r10, #1
    cmp r10, #Check_Layers
    bne .1

    mov r11, #0             ; scanline.
.3:
    ; Work out which combo line to plot based on parity of y pos.
    ldr r9, check_line_combo_p
    .if Screen_Stride == 160
    add r9, r9, r7, lsl #7  ; + parity word * 128
    add r9, r9, r7, lsl #5  ; + parity word * 32
    .else
    .error "Expected Screen_Stride to be 160."
    .endif

    ; 'Blit' to screen
    bl copy_combo_row

    ; Update all the running y positions per scanline...
    mov r10, #0                 ; layer
.4:
    ldr r1, [r6, r10, lsl #2]   ; running y pos
    ldr r2, [r4, r10, lsl #2]   ; dx for layer
    add r1, r1, r2              ; y_pos += dx

    ; Track parity for this layer.
    cmp r1, #Check_Size_Pixels<<16
    subge r1, r1, #Check_Size_Pixels<<16
    eorge r7, r7, r5, lsl r10

    str r1, [r6, r10, lsl #2]   ; running y

    ; Next layer.
    add r10, r10, #1
    cmp r10, #Check_Layers
    bne .4

    ; Next scanline.
    add r11, r11, #1
    cmp r11, #Screen_Height
    blt .3

    ldr pc, [sp], #4

check_layer_running_y:
    .skip Check_Layers * 4

check_layer_dx:
    .skip Check_Layers * 4

; ========================================================================

update_check_layers:
    str lr, [sp, #-4]!

    ; TODO: A less long-hand way of achieving this.
    .if _ENABLE_ROCKET
    .set _layer, 0
    .rept Check_Layers
    .set _track_base, _layer * 4
    mov r0, #_track_base + 0
    bl rocket_sync_get_val
    str r1, check_layer_x_pos + _track_base

    mov r0, #_track_base + 1
    bl rocket_sync_get_val
    str r1, check_layer_y_pos + _track_base

    mov r0, #_track_base + 2
    bl rocket_sync_get_val
    str r1, check_layer_z_pos + _track_base

    ; TODO: Layer colour in _track_base + 3
    .set _layer, _layer + 1
    .endr
    .endif

    ldr pc, [sp], #4


; ========================================================================
; X, Y, Z positions for each layer.
; ========================================================================

check_layer_x_pos:
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16
    .long 96 << 16

    .long 97 << 16
    .long 98 << 16
    .long 99 << 16
    .long 100 << 16
    .long 101 << 16
    .long 102 << 16
    .long 103 << 16

check_layer_y_pos:
    .long 160 << 16
    .long 20 << 16
    .long 30 << 16
    .long 40 << 16
    .long 50 << 16
    .long 60 << 16
    .long 70 << 16

check_layer_z_pos:
    .long 256 << 16
    .long 128 << 16
    .long 96 << 16
    .long 64 << 16
    .long 8 << 16
    .long 4 << 16
    .long 2 << 16

; ========================================================================
