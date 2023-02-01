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

.equ _DUAL_PF, 1

.if _DUAL_PF
.equ Check_Layers, 3
.equ Check_PF_Layers, Check_Layers * 2
.else
.equ Check_Layers, 5
.endif

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

.if _DUAL_PF
check_line_combo_PF_p:
    .long check_line_combos_PF_no_adr
.endif

; ========================================================================
; Plot a row's worth of pixels for the depth given by dx, with
; pixel shift [0-7]. Centres the checks in the centre of the row.
; Plot 'Rows_Width_Pixels' pixels , i.e. 'Rows_Width_Bytes' bytes
; written into the buffer pointed to be R11.
; ========================================================================
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


; ========================================================================
; Plot a screen widths worth of checks to the destination buffer.
; ========================================================================

.if _DUAL_PF==0
; R9=check row source.
; R10=colour word.
; R12=dest line buffer.
; Trashes: r0-r7
.p2align 6
plot_check_line_parity_0:
.rept Screen_Stride / 16
    ldmia r9!, {r0-r3}      ; load 4 words of source (all bits set for a pixel, so 0xabcdefg where each=0x0 or 0xf)
    ; 8c
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

; As above but invert source pixels.
; R9=check row source.
; R10=colour word.
; R12=dest line buffer.
; Trashes: r0-r7
.p2align 6
plot_check_line_parity_1:
.rept Screen_Stride / 16
    ldmia r9!, {r0-r3}      ; load 4 words of source (all bits set for a pixel, so 0xabcdefg where each=0x0 or 0xf)
    ; 8c
    mov r4, #0xffffffff     ; TODO: can we keep this around?
    eor r0, r0, r4
    eor r1, r1, r4
    eor r2, r2, r4
    eor r3, r3, r4
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

; ========================================================================
; Plot the 2^N possible combinations of layers visible based on
; the depth and X position of each layer, starting from the furthest
; away.
;
; Requires plotting (and masking) the checks from each layer 2^N times.
; ========================================================================
;
; R8=layer no.
; R9=check row source.
; R10=colour word (layer + 1)
; R12=dest line buffer.
; Trashes: r0-r8, r11
plot_check_combo_lines:
    str lr, [sp, #-4]!
    ; Combo #
    mov r11, #0
.3:
    mov r2, #1
    ands r0, r11, r2, lsl r8    ; parity = combo & (1 << layer)

    ; Plot the check row for this layer & parity.
    bleq plot_check_line_parity_0
    blne plot_check_line_parity_1
    ; Trashes: r0-r7
    ; 400c

    ; Reset R9 (repeat this line for all combos)
    sub r9, r9, #Screen_Stride

    ; Next line in the combo.
    add r11, r11, #1
    cmp r11, #Check_Combos
    blt .3
    ldr pc, [sp], #4
.endif

.if _DUAL_PF
plot_check_combos:
    str lr, [sp, #-4]!
    ldr r12, check_line_combo_p

    ; Blank all line combos.
    mov r0, #0
    mov r1, r0
    mov r2, r0
    mov r3, r0
    mov r4, r0
    mov r5, r0
    mov r6, r0
    mov r7, r0
    mov r11, #Check_Combos * 2
.1:
.rept Screen_Stride / 32
    stmia r12!, {r0-r7}
.endr
    subs r11, r11, #1
    bne .1

    ldr r12, check_line_combo_p
    adr r4, check_layer_x_pos
    adr r5, check_layer_z_pos
    mov r10, #0
    bl plot_check_combo_layers

    ldr r12, check_line_combo_PF_p
    adr r4, check_layer_x_pos + Check_Layers*4
    adr r5, check_layer_z_pos + Check_Layers*4
    mov r10, #0x02
    bl plot_check_combo_layers

    ldr pc, [sp], #4
.else
; Plot blank line of screen width.
; R12=dest line buffer.
; Trashes r0-r3
.p2align 6
plot_blank_line:
    mov r0, #0
    mov r1, r0
    mov r2, r0
    mov r3, r0
.rept Screen_Stride / 16
    stmia r12!, {r0-r3}
.endr
    mov pc, lr

plot_check_combos:
    str lr, [sp, #-4]!
    ldr r12, check_line_combo_p

    ; Blank all line combos.
    mov r11, #Check_Combos
.1:
    bl plot_blank_line
    subs r11, r11, #1
    bne .1

    adr r4, check_layer_x_pos
    adr r5, check_layer_z_pos
    mov r10, #0
    bl plot_check_combo_layers
    ldr pc, [sp], #4
.endif

; R4=ptr to layer x pos table.
; R5=ptr to layer z pos table.
; R10=PF mask.
; R12=ptr to destination buffer for combo lines.
plot_check_combo_layers:
    str lr, [sp, #-4]!
    str r4, check_combos_x_table
    str r5, check_combos_z_table
    str r10, check_combos_pf_mask

    ; For each layer, plot appropriate line 2^N times.
    mov r11, #0
.2:
    ; R9=check row src.
    ; Compute from x and z for layer.
    ldr r4, check_combos_x_table
    ldr r0, [r4, r11, lsl #2]           ; [16.16]
    mov r0, r0, lsr #16                 ; [16.0]

    and r2, r0, #7                      ; pixel shift [0-7]
    bic r0, r0, #7                      ; word shift

    adr r9, check_rows_table
    ldr r9, [r9, r2, lsl #2]            ; select check rows for shift 
    add r9, r9, r0, lsr #1              ; X word

    ldr r5, check_combos_z_table
    ldr r1, [r5, r11, lsl #2]           ; [16.16]
    mov r1, r1, lsr #16

    ; Add Rows_Width * z_pos
    .if Rows_Width_Bytes == 256
    add r9, r9, r1, lsl #8              ; z * 256
    .else
    .error "Expected Rows_Width_Bytes to be 256."
    .endif

    ; Convert layer number into colour word.
    ; R10=colour word.
    add r10, r11, #1                     ; colour = layer+1
    ; Insert PF mask.
    ldr r0, check_combos_pf_mask
;    orr r10, r10, r0
    mov r10, r10, lsl r0                 ; abxx or xxab
    ; Convert into colour word.
    orr r10, r10, r10, lsl #4
    orr r10, r10, r10, lsl #8
    orr r10, r10, r10, lsl #16

    ; Plots the 2^N combo lines for layer R11 from R9 to R12 in colour R10.
    adr r8, plot_layer_fns
    adr lr, .3
    ldr pc, [r8, r11, lsl #2]       ; was bl plot_check_combo_lines
    .3:
    ; Trashes: r0-r7, r11
    
    ; Reset destination buffer ptr R12.
    sub r12, r12, #Screen_Stride

    ; Next layer.
    add r11, r11, #1
    cmp r11, #Check_Layers
    blt .2

    ldr pc, [sp], #4

check_combos_pf_mask:
    .long 0

check_combos_x_table:
    .long 0

check_combos_z_table:
    .long 0

.if _DUAL_PF
.else
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
.endif


; ========================================================================
; Plot all checks to the screen based on the Y position for each
; layer. For each scanline we maintain the y value within each layer
; and therefore the 'parity' of the check. Given the parity of all
; layers we select which of the 2^N check combo lines to copy to the
; screen.
; ========================================================================
; 
; R12=screen addr
;
; TODO NEXT: Convert this into _DUAL_PF implementation.
; Worth just generating the per-scanline bitmask first?
; Then do the source merge after?
;
.if _DUAL_PF
calculate_scanline_bitmasks:
    str lr, [sp, #-4]!

    ; Need 6x registers for dx.
    adr r0, check_layer_z_pos
    ldr r1, check_depths_dx_p

    ldmia r0, {r6-r11}            ; r6-r11 = zpos
    mov r6, r6, lsr #16
    ldr r6, [r1, r6, lsl #2]      ; r6=dx for layer 0 at zpos
    mov r7, r7, lsr #16
    ldr r7, [r1, r7, lsl #2]      ; r7=dx for layer 1 at zpos
    mov r8, r8, lsr #16
    ldr r8, [r1, r8, lsl #2]      ; r8=dx for layer 2 at zpos
    mov r9, r9, lsr #16
    ldr r9, [r1, r9, lsl #2]      ; r9=dx for layer 3 at zpos
    mov r10, r10, lsr #16
    ldr r10, [r1, r10, lsl #2]    ; r10=dx for layer 4 at zpos
    mov r11, r11, lsr #16
    ldr r11, [r1, r11, lsl #2]    ; r11=dx for layer 5 at zpos
    
    ; Need 6x registers for y pos.
    adr r14, check_layer_y_pos
    ldmia r14, {r0-r5}          ; r0-r5 = ypos

    ; 1x register for scanline counter - combine ?
    ; 1x register for bitmask           |
    mov r14, #0                 ; bitmask & scanline counter!!
.1:
    cmp r0, #Check_Size_Pixels<<16
    subge r0, r0, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 0
    bge .1

.2:
    cmp r1, #Check_Size_Pixels<<16
    subge r1, r1, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 1
    bge .2

.3:
    cmp r2, #Check_Size_Pixels<<16
    subge r2, r2, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 2
    bge .3

.4:
    cmp r3, #Check_Size_Pixels<<16
    subge r3, r3, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 3
    bge .4

.5:
    cmp r4, #Check_Size_Pixels<<16
    subge r4, r4, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 4
    bge .5

.6:
    cmp r5, #Check_Size_Pixels<<16
    subge r5, r5, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 5
    bge .6

    ; 1x register for address to write bitmask.
    ldr r12, check_scanline_bitmask_p

    ; Scanline counter is top halfword of r14.
.7:
    str r14, [r12], #4           ; store parity bitmask to table.

    ; Update all the running y positions per scanline...
    add r0, r0, r6              ; y_pos += dx
    cmp r0, #Check_Size_Pixels<<16
    subge r0, r0, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 0

    add r1, r1, r7              ; y_pos += dx
    cmp r1, #Check_Size_Pixels<<16
    subge r1, r1, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 1

    add r2, r2, r8              ; y_pos += dx
    cmp r2, #Check_Size_Pixels<<16
    subge r2, r2, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 2

    add r3, r3, r9              ; y_pos += dx
    cmp r3, #Check_Size_Pixels<<16
    subge r3, r3, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 3

    add r4, r4, r10             ; y_pos += dx
    cmp r4, #Check_Size_Pixels<<16
    subge r4, r4, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 4

    add r5, r5, r11             ; y_pos += dx
    cmp r5, #Check_Size_Pixels<<16
    subge r5, r5, #Check_Size_Pixels<<16
    eorge r14, r14, #1 << 5

    ; Next scanline.
    add r14, r14, #1<<16
    cmp r14, #Screen_Height<<16
    blt .7

    ldr pc, [sp], #4

plot_checks_to_screen:
    str lr, [sp, #-4]!

    ; Now blit everything to the screen.
    ldr r14, check_line_combo_PF_p
    ldr r10, check_scanline_bitmask_p
    mov r11, #Screen_Height                 ; scanline.
.8:
    mov r9, r14
    sub r8, r9, #Screen_Stride * Check_Combos

    ldr r7, [r10], #4       ; parity bitmask
    mov r0, r7, lsr #Check_Layers
    and r0, r0, #Check_Combos-1

    .if Screen_Stride == 160
    add r9, r9, r0, lsl #7  ; + parity word * 128
    add r9, r9, r0, lsl #5  ; + parity word * 32
    .else
    .error "Expected Screen_Stride to be 160."
    .endif

    and r7, r7, #Check_Combos-1
    add r8, r8, r7, lsl #7  ; + parity word * 128
    add r8, r8, r7, lsl #5  ; + parity word * 32

    ; 'Blit' to screen from r9 to r12.
.rept Screen_Stride / 16
    ldmia r9!, {r0-r3}      ; load 4 words of top layers (top bits set, so 0b11aa11bb11cc...)
    ; 8c
    ldmia r8!, {r4-r7}      ; load 4 words of bottom layers
    ; 8c
    orr r4, r4, r0          ; mask in pixels from top layer
    orr r5, r5, r1          ; mask in pixels from top layer
    orr r6, r6, r2          ; mask in pixels from top layer
    orr r7, r7, r3          ; mask in pixels from top layer
    ; 4c
    stmia r12!, {r4-r7}
    ; 8c
.endr
    ; Trashes r0-r7

    ; Next scanline.
    subs r11, r11, #1
    bne .8

    ldr pc, [sp], #4

check_scanline_bitmask_p:
    .long check_scanline_bitmask_no_adr

.else
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

    ; 'Blit' to screen from r9 to r12.
    bl copy_combo_row
    ; Trashes r0-r3

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
.endif

; ========================================================================

update_check_layers:
    str lr, [sp, #-4]!

    ; TODO: A less long-hand way of achieving this.
    .if _ENABLE_ROCKET
    .set _layer, 0
    .rept Check_Layers * (1 + _DUAL_PF)
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

check_layer_y_pos:
    .long 160 << 16
    .long 20 << 16
    .long 30 << 16
    .long 40 << 16
    .long 50 << 16
    .long 60 << 16
    .long 70 << 16
    .long 80 << 16

check_layer_z_pos:
    .long 511 << 16
    .long 256 << 16
    .long 128 << 16
    .long 96 << 16
    .long 64 << 16
    .long 32 << 16
    .long 16 << 16
    .long 8 << 16

; ========================================================================

.if _DUAL_PF
plot_layer_fns:
    .long plot_layer_0_check_lines
    .long plot_layer_1_check_lines
    .long plot_layer_2_check_lines

; R9=check row source.
; R10=colour word.
; R12=dest line buffer.
; Trashes: r0-r7, r8
.p2align 6
plot_layer_0_check_lines:
.rept Screen_Stride / 32
    ldmia r9!, {r0-r7}      ; load 4 words of source (all bits set for a pixel, so 0xabcdefg where each=0x0 or 0xf)
    and r0, r0, r10        ; mask colour with source word
    and r1, r1, r10        ; mask colour with source word
    and r2, r2, r10        ; mask colour with source word
    and r3, r3, r10        ; mask colour with source word
    and r4, r4, r10        ; mask colour with source word
    and r5, r5, r10        ; mask colour with source word
    and r6, r6, r10        ; mask colour with source word
    and r7, r7, r10        ; mask colour with source word
    stmia r12, {r0-r7}      ; +0
    add r8, r12, #Screen_Stride*2
    stmia r8, {r0-r7}       ; +2
    add r8, r8, #Screen_Stride*2
    stmia r8, {r0-r7}       ; +4
    add r8, r8, #Screen_Stride*2
    stmia r8, {r0-r7}       ; +6

    eor r0, r0, r10         ; invert colour bits
    eor r1, r1, r10         ; invert colour bits
    eor r2, r2, r10         ; invert colour bits
    eor r3, r3, r10         ; invert colour bits
    eor r4, r4, r10         ; invert colour bits
    eor r5, r5, r10         ; invert colour bits
    eor r6, r6, r10         ; invert colour bits
    eor r7, r7, r10         ; invert colour bits
    add r8, r12, #Screen_Stride
    stmia r8, {r0-r7}       ; +1
    add r8, r8, #Screen_Stride*2
    stmia r8, {r0-r7}       ; +3
    add r8, r8, #Screen_Stride*2
    stmia r8, {r0-r7}       ; +5
    add r8, r8, #Screen_Stride*2
    stmia r8, {r0-r7}       ; +7
    add r12, r12, #32
.endr
    mov pc, lr

plot_layer_1_check_lines:
.rept Screen_Stride / 16
    ldmia r9!, {r0-r3}      ; load 4 words of source (all bits set for a pixel, so 0xabcdefg where each=0x0 or 0xf)

    ; +0
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}      ; write 4 words back to screen

    ; +1
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +4
    add r12, r12, #Screen_Stride * 3
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +5
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    mov r8, #0xffffffff
    eor r0, r0, r8         ; invert source bits
    eor r1, r1, r8         ; invert source bits
    eor r2, r2, r8         ; invert source bits
    eor r3, r3, r8         ; invert source bits

    ; +2
    sub r12, r12, #Screen_Stride * 3
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +3
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +6
    add r12, r12, #Screen_Stride * 3
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +7
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12!, {r4-r7}     ; write 4 words back to screen

    sub r12, r12, #Screen_Stride * 7
.endr
    mov pc, lr

plot_layer_2_check_lines:
.rept Screen_Stride / 16
    ldmia r9!, {r0-r3}      ; load 4 words of source (all bits set for a pixel, so 0xabcdefg where each=0x0 or 0xf)

    ; +0
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}      ; write 4 words back to screen

    ; +1
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +2
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +3
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    mov r8, #0xffffffff
    eor r0, r0, r8         ; invert source bits
    eor r1, r1, r8         ; invert source bits
    eor r2, r2, r8         ; invert source bits
    eor r3, r3, r8         ; invert source bits

    ; +4
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +5
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +6
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12, {r4-r7}     ; write 4 words back to screen

    ; +7
    add r12, r12, #Screen_Stride
    ldmia r12, {r4-r7}      ; load 4 words of screen
    bic r4, r4, r0          ; mask out screen pixels to be written
    and r8, r0, r10         ; mask colour with source word
    orr r4, r4, r8          ; mask in colour word
    bic r5, r5, r1          ; mask out screen pixels to be written
    and r8, r1, r10         ; mask colour with source word
    orr r5, r5, r8          ; mask in colour word
    bic r6, r6, r2          ; mask out screen pixels to be written
    and r8, r2, r10         ; mask colour with source word
    orr r6, r6, r8          ; mask in colour word
    bic r7, r7, r3          ; mask out screen pixels to be written
    and r8, r3, r10         ; mask colour with source word
    orr r7, r7, r8          ; mask in colour word
    stmia r12!, {r4-r7}     ; write 4 words back to screen

    sub r12, r12, #Screen_Stride * 7
.endr
    mov pc, lr

.endif