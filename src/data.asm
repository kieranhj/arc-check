; ============================================================================
; DATA.
; ============================================================================

.data   ; TODO: Do we need an rodata segment?

.p2align 6
.if _ENABLE_MUSIC
music_data_no_adr:
;.incbin "data/music/arcchoon.mod"
.incbin "data/music/cheqacid.mod"
.endif

; ============================================================================

.p2align 6
text_screen_1_no_adr:
.incbin "data/raw/screen1.bin"

text_screen_2_no_adr:
.incbin "data/raw/screen2.bin"

text_screen_3_no_adr:
.incbin "data/raw/screen3.bin"

; ============================================================================

.if _ENABLE_LUAPOD && !_SYNC_EDITOR
.p2align 2
luapod_frame_data_no_adr:
.incbin "data/lua_frames.bin"
.endif

; ============================================================================

.p2align 6
.include "lib/lib_data.asm"

; ============================================================================
