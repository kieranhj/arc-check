; ============================================================================
; Text screen plotting.
; ============================================================================

text_screen_data_p:
    .long text_screen_1_no_adr

text_screen_colour_word:
    .long 0x33333333            ; or 0x77777777

text_screen_plot:
    str lr, [sp, #-4]!
    ldr r8, text_screen_data_p
    ldr r10, text_screen_colour_word
    bl plot_bitplane_1_to_screen_and_mask

    ldr r0, text_screen_top
    ldr r1, text_screen_top_dir
    add r0, r0, r1
    cmp r0, #0
    movlt r0, #0
    cmp r0, #255
    movgt r0, #255
    str r0, text_screen_top

    ldr r0, text_screen_bottom
    ldr r1, text_screen_bottom_dir
    add r0, r0, r1
    cmp r0, #0
    movlt r0, #0
    cmp r0, #255
    movgt r0, #255
    str r0, text_screen_bottom

    ldr pc, [sp], #4

text_screen_top:
    .long 0

text_screen_top_dir:
    .long 0

text_screen_bottom:
    .long 255

text_screen_bottom_dir:
    .long 0

.if 0
; R12=screen addr
plot_text_screen_masked:
    ldr r9, text_screen_data_p
    ldr r10, text_screen_colour_word

    mov r11, #0                 ; scanline.
.1:
    .rept Screen_Stride / 16
    ldmia r12, {r0-r3}              ; screen.
    ldmia r9!, {r4-r7}              ; image.

.if 1
    ; Mask out image pixels from screen.
    bic r0, r0, r4
    bic r1, r1, r5
    bic r2, r2, r6
    bic r3, r3, r7

    ; Mask in colour to image pixels.
    and r4, r4, r10
    and r5, r5, r10
    and r6, r6, r10
    and r7, r7, r10

    ; Mask coloured image pixels over screen.
    orr r0, r0, r4
    orr r1, r1, r5
    orr r2, r2, r6
    orr r3, r3, r7

    stmia r12!, {r0-r3}
.else
    stmia r12!, {r4-r7}
.endif
    .endr

    add r11, r11, #1
    cmp r11, #Screen_Height
    blt .1

    mov pc, lr
.endif
