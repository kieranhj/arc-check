; ============================================================================
; The actual sequence for the demo.
; ============================================================================

.macro set_draw_fn func
    write_addr draw_fn_p, \func
.endm

seq_main_program:

    ; Wait for 250 frames
    wait 250

    ; Crude draw fn.
    set_draw_fn text_screen_plot

    ; Wait for 250 frames
    wait 250

    ; Crude draw fn.
    set_draw_fn plot_checks_to_screen

    ; THE END.
    end_script

    ; TODO: End demo or loop etc.
