; ============================================================================
; The actual sequence for the demo.
; ============================================================================

.equ FramesPerRow, 3.33333333
.equ RowsPerPattern, 64
.equ FramesPerPattern, FramesPerRow*RowsPerPattern

.macro set_draw_fn func
    write_addr draw_fn_p, \func
.endm

seq_main_program:

    ; Initial state.
    set_draw_fn plot_checks_to_screen
    write_addr layer_colour_start, 0                                ; set colours for all layers.
    write_addr layer_colour_default, 0x0fff

    ; Wait for 250 frames
    wait FramesPerPattern*12                                        ; will be one frame out...!

    ; Crude draw fn.
    set_draw_fn text_screen_plot
    write_addr layer_colour_start, Check_Layers_per_bitplane        ; don't set colours for layers on 'bottom' bitplane.

    wait 2*FramesPerPattern
    write_addr text_screen_data_p, text_screen_2_no_adr

    wait 2*FramesPerPattern
    write_addr text_screen_data_p, text_screen_3_no_adr

    ; Wait for 250 frames
    wait 2*FramesPerPattern

    ; Crude draw fn.
    set_draw_fn plot_checks_to_screen
    write_addr layer_colour_start, 0                                ; set colours for all layers.

    ; THE END.
    end_script

    ; TODO: End demo or loop etc.
