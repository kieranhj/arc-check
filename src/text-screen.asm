; ============================================================================
; Text screen plotting.
; ============================================================================

test_screen_p:
    .long test_screen_no_adr

test_colour:
    .long 0x33333333            ; or 0x77777777

.if 0
; R12=screen addr
plot_text_screen_masked:
    ldr r9, test_screen_p
    ldr r10, test_colour

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
