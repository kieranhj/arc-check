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
    wait FramesPerPattern*20                                        ; will be one frame out...!

    ; Display overlay image
    set_draw_fn text_screen_plot
    write_addr text_screen_top, 127
    write_addr text_screen_top_dir, -1
    write_addr text_screen_bottom, 128
    write_addr text_screen_bottom_dir, 1
    write_addr text_screen_data_p, text_screen_1_no_adr             ; bitshifters logo
    write_addr layer_colour_start, Check_Layers_per_bitplane        ; don't set colours for layers on 'bottom' bitplane.

    wait FramesPerPattern-64
    write_addr text_screen_top, 127-64
    write_addr text_screen_top_dir, 1
    write_addr text_screen_bottom, 127+64
    write_addr text_screen_bottom_dir, -1
    wait 64
    ; wait 1*FramesPerPattern

    write_addr text_screen_top, 127
    write_addr text_screen_top_dir, -1
    write_addr text_screen_bottom, 128
    write_addr text_screen_bottom_dir, 1
    write_addr text_screen_data_p, text_screen_4_no_adr             ; torment logo

    wait FramesPerPattern-64
    write_addr text_screen_top, 127-64
    write_addr text_screen_top_dir, 1
    write_addr text_screen_bottom, 127+64
    write_addr text_screen_bottom_dir, -1
    wait 64
    ; wait 1*FramesPerPattern

    write_addr text_screen_top, 127
    write_addr text_screen_top_dir, -2
    write_addr text_screen_bottom, 128
    write_addr text_screen_bottom_dir, 2
    write_addr text_screen_data_p, text_screen_3_no_adr             ; greets

    wait FramesPerPattern-64
    write_addr text_screen_top_dir, 2
    write_addr text_screen_bottom_dir, -2
    wait 64
    ;wait 1*FramesPerPattern

    write_addr text_screen_data_p, text_screen_2_no_adr             ; credits
    write_addr text_screen_top, 127
    write_addr text_screen_top_dir, -2
    write_addr text_screen_bottom, 128
    write_addr text_screen_bottom_dir, 2

    wait FramesPerPattern-64
    write_addr text_screen_top_dir, 2
    write_addr text_screen_bottom_dir, -2
    wait 64
    ;wait 1*FramesPerPattern

    ; Back to all layers.
    set_draw_fn plot_checks_to_screen
    write_addr layer_colour_start, 0                                ; set colours for all layers.

    ; THE END.
    end_script

    ; TODO: End demo or loop etc.
