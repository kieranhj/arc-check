; ============================================================================
; DATA.
; ============================================================================

.data   ; TODO: Do we need an rodata segment?

.p2align 6
.if _ENABLE_MUSIC
music_data_no_adr:
;.incbin "data/music/arcchoon.mod"
.incbin "data/music/4mat-l-f-f.mod"
.endif

; ============================================================================

.p2align 6
test_screen_no_adr:
.incbin "data/raw/screen1.bin"

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
