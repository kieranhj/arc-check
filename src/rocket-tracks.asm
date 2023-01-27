; ============================================================================
; Rocket track data.
; ============================================================================

.if _SYNC_EDITOR

; TODO: automate from MOD file.
; BBPD MOD has short (32 line) patterns at 8, 15, 20, 21.
.if !Patterns_All64Rows
rocket_music_pattern_lengths:
    .set ps, 0
    pat_len ps, 64   ; 0
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 32   ; 8
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 32   ; 15
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 64
    pat_len ps, 32   ; 20
    pat_len ps, 32   ; 21
    pat_len ps, 64   ; 22
.endif

.else

track_0_data_no_adr:
    .incbin "data/rocket/rubber_pos_x.track"

track_1_data_no_adr:
    .incbin "data/rocket/rubber_pos_y.track"

track_2_data_no_adr:
    .incbin "data/rocket/rubber_pos_z.track"

track_3_data_no_adr:
    .incbin "data/rocket/rubber_rot_x.track"

track_4_data_no_adr:
    .incbin "data/rocket/rubber_rot_y.track"

track_5_data_no_adr:
    .incbin "data/rocket/rubber_rot_z.track"

track_6_data_no_adr:
    .incbin "data/rocket/rubber_line_delay.track"

track_7_data_no_adr:
    .incbin "data/rocket/rubber_line_split.track"

track_8_data_no_adr:
    .incbin "data/rocket/rubber_y_pos.track"

.endif
