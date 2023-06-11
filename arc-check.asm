; ============================================================================
; Archimedes Checkerboard Challenge!
; ============================================================================

.equ _DEBUG, 1
.equ _ENABLE_RASTERMAN, 0
.equ _ENABLE_MUSIC, 1
.equ _ENABLE_ROCKET, 0
.equ _SYNC_EDITOR, 0                    ; (_ENABLE_ROCKET && 1)
.equ _ENABLE_LUAPOD, 1
.equ _FIX_FRAME_RATE, 0					; useful for !DDT breakpoints

.equ _DEBUG_RASTERS, (_DEBUG && !_ENABLE_RASTERMAN && 1)
.equ _DEBUG_STOP_ON_FRAME, -1
.equ _DEBUG_DEFAULT_PLAY_PAUSE, 1		; play
.equ _DEBUG_DEFAULT_SHOW_RASTERS, 0
.equ _DEBUG_DEFAULT_SHOW_INFO, 1		; slow

.equ _SET_DISPLAY_BANK_AT_VSYNC, 0		; as per Sarah's original framework.
.equ _WRITE_VIDC_REGS_AT_VSYNC, 1		; to avoid flicker also faster than OS_Word.

.equ MaxFrames, 2224                    ; for now!

; ============================================================================

.equ Screen_Banks, 2
.equ Screen_Mode, 9
.equ Screen_Width, 320
.equ Screen_Height, 256
.equ Mode_Height, 256
.equ Screen_PixelsPerByte, 2
.equ Screen_Stride, Screen_Width/Screen_PixelsPerByte
.equ Screen_Bytes, Screen_Stride*Screen_Height
.equ Mode_Bytes, Screen_Stride*Mode_Height

; ============================================================================

.include "lib/swis.h.asm"
.include "src/lib-config.h.asm"
.include "src/rocket-config.h.asm"

; ============================================================================

.macro SET_BORDER rgb
	.if _DEBUG_RASTERS
	mov r4, #\rgb
	ldrb r0, debug_show_rasters
	cmp r0, #0
	blne palette_set_border
	.endif
.endm

; ============================================================================
; Start
; ============================================================================

.org 0x8000

Start:
    ldr sp, stack_p
	B main

stack_p:
	.long stack_base_no_adr

; ============================================================================
; Main
; ============================================================================

main:
	SWI OS_WriteI + 22		; Set base MODE
	SWI OS_WriteI + Screen_Mode

	SWI OS_WriteI + 23		; Disable cursor
	SWI OS_WriteI + 1
	MOV r0,#0
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC

	mov r0, #9
	mov r1, #0
	swi OS_Byte				; *FX 9,0 to disable flashing colours.

	; Set screen size for number of buffers
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	MOV r0, #DynArea_Screen
	MOV r2, #Mode_Bytes * Screen_Banks
	SUBS r1, r2, r1
	SWI OS_ChangeDynamicArea
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	CMP r1, #Mode_Bytes * Screen_Banks
	ADRCC r0, error_noscreenmem
	SWICC OS_GenerateError

	; LOAD STUFF HERE!

.if _ENABLE_MUSIC
	; QTM Init.
	; Required to make QTM play nicely with RasterMan.
	.if _ENABLE_RASTERMAN
	mov r0, #4
	mov r1, #-1
	mov r2, #-1
	swi QTM_SoundControl
	.endif

	; Load module
	mov r0, #0
	ldr r1, music_data_p
	swi QTM_Load
.endif

	; Clear all screen buffers
	mov r1, #1
.1:
	str r1, scr_bank

	; CLS bank N
	mov r0, #OSByte_WriteVDUBank
	swi OS_Byte
	mov r0, #12
	SWI OS_WriteC

	ldr r1, scr_bank
	add r1, r1, #1
	cmp r1, #Screen_Banks
	ble .1

	; EARLY INITIALISATION HERE! (Tables etc.)
	.if _ENABLE_RASTERMAN
	bl rasters_init
	.endif
	bl maths_init

	; Make buffers.
	bl check_rows_init

	.if _ENABLE_ROCKET
	bl rocket_init
	.endif
    .if _ENABLE_LUAPOD
    bl luapod_init
    .endif

	; Start with bank 1
	mov r1, #1
	str r1, scr_bank
	
	; Claim the Error vector
	MOV r0, #ErrorV
	ADR r1, error_handler
	MOV r2, #0
	SWI OS_Claim

	; Claim the Event vector
	.if !_ENABLE_RASTERMAN
	mov r0, #EventV
	adr r1, event_handler
	mov r2, #0
	swi OS_AddToVector
	.endif

	; LATE INITALISATION HERE!
	adr r2, grey_palette
	bl palette_set_block

	; Sync tracker.
	.if _ENABLE_ROCKET
	bl rocket_start		; handles music.
	.else
	.IF _ENABLE_MUSIC
	swi QTM_Start
	.endif
	.endif

	; Fire up the RasterMan!
	.if _ENABLE_RASTERMAN
	swi RasterMan_Install
	.else
	; Enable Vsync 
	mov r0, #OSByte_EventEnable
	mov r1, #Event_VSync
	SWI OS_Byte
	.endif

main_loop:

    .if _ENABLE_LUAPOD
    ldr r0, frame_counter
    bl luapod_set_sync_time
    .endif

	.if _DEBUG
	bl debug_controls
	.endif

	; exit if Escape is pressed
	.if _ENABLE_RASTERMAN
	swi RasterMan_ScanKeyboard
	mov r1, #0xc0c0
	cmp r0, r1
	beq exit
	.else
	swi OS_ReadEscapeState
	bcs exit
	.endif
	
	.if _DEBUG
	ldrb r0, debug_play_pause
	cmp r0, #0
	bne .3

	ldrb r0, debug_play_step
	cmp r0, #0
	beq main_loop_skip_tick
	.3:
	.endif


	; ========================================================================
	; TICK
	; ========================================================================

	; R0 = vsync delta since last frame.
	.if _ENABLE_ROCKET
	ldr r0, vsync_delta
	bl rocket_update
	.endif

	SET_BORDER 0x00ff00	; green

	bl update_check_layers

	SET_BORDER 0x0000ff	; red

	bl plot_check_combos

	SET_BORDER 0xff0000	; blue

	bl calculate_scanline_bitmasks

    ; Update frame counter.
    ldr r0, frame_counter
    cmp r0, #MaxFrames
    addlt r0, r0, #1
    str r0, frame_counter

main_loop_skip_tick:

	; ========================================================================
	; VSYNC
	; ========================================================================

	SET_BORDER 0x000000	; black
	; Really we need something more sophisticated here.
	; Block only if there's no free buffer to write to.

	.if _ENABLE_RASTERMAN
	swi RasterMan_Wait
	mov r0, #1				; TODO: Ask Steve for RasterMan_GetVsyncCounter.
	.else

	; Block if we've not even had a vsync since last time - we're >50Hz!
	.if (Screen_Banks == 2 && 0)
	; Block if there's a buffer pending to be displayed when double buffered.
	; This means that we overran the previous frame. Triple buffering may
	; help here. Or not. ;)
	.2:
	ldr r1, buffer_pending
	cmp r1, #0
	bne .2	
	.endif

	ldr r1, last_vsync
.1:
	ldr r2, vsync_count
	cmp r1, r2
	beq .1
	.if _FIX_FRAME_RATE
	mov r0, #1
	.else
	sub r0, r2, r1
	.endif
	str r2, last_vsync
	.endif
	str r0, vsync_delta
	; R0 = vsync delta since last frame.

	; ========================================================================
	; DRAW
	; ========================================================================

	.if 0 ; if need to double-buffer raster table.
	bl rasters_copy_table
	.endif

	; DO STUFF HERE!
	bl get_next_screen_for_writing

	SET_BORDER 0xff00ff	; magenta

	ldr r12, screen_addr
	bl plot_checks_to_screen

	SET_BORDER 0x00ffff	; yellow

	ldr r12, scr_bank
	bl check_layers_set_colours

	SET_BORDER 0xffff00	; cyan

	; show debug
	.if _DEBUG
	bl debug_write_vsync_count
	.endif

	SET_BORDER 0x000000	; black
	bl show_screen_at_vsync

	; ========================================================================
	; LOOP
	; ========================================================================

	b main_loop

.if _ENABLE_MUSIC
music_data_p:
	.long music_data_no_adr
.endif

error_noscreenmem:
	.long 0
	.byte "Cannot allocate screen memory!"
	.p2align 2
	.long 0

.if _DEBUG
debug_write_vsync_count:
	ldrb r0, debug_show_info
	cmp r0, #0
	moveq pc, lr

	str lr, [sp, #-4]!
	swi OS_WriteI+30			; home text cursor

    ldr r0, frame_counter
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex4

	adr r0, debug_string
	swi OS_WriteO
	
.if _ENABLE_MUSIC && 0
	swi OS_WriteI+32			; ' '

    ; read current tracker position
    mov r0, #-1
    mov r1, #-1
    swi QTM_Pos

	mov r3, r1

	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex2
	adr r0, debug_string
	swi OS_WriteO

	swi OS_WriteI+58			; ':'

	mov r0, r3
	adr r1, debug_string
	mov r2, #8
	swi OS_ConvertHex2
	adr r0, debug_string
	swi OS_WriteO
.endif
	ldr pc, [sp], #4

debug_string:
	.skip 16

debug_controls:
	str lr, [sp, #-4]!

	MOV r0, #OSByte_ReadKey
	MOV r1, #IKey_Space
	MOV r2, #0xff
	SWI OS_Byte
	CMP r1, #0xff
	CMPEQ r2, #0xff
	BNE .1 ; not pressed
	ldrb r0, debug_debounce_space
	cmp r0, #0
	bne .1 ; still pressed

	; Toggle play/pause.
	ldrb r0, debug_play_pause
	eor r0, r0, #1
	strb r0, debug_play_pause

    .if _ENABLE_MUSIC
    cmp r0, #0
    swieq QTM_Pause			    ; pause
    swine QTM_Start             ; play
    .endif

    .if _ENABLE_LUAPOD && _SYNC_EDITOR
    mov r3, r1
    bl luapod_set_is_playing
    mov r1, r3
    .endif
	.1:
	strb r1, debug_debounce_space

	mov r0, #0
	strb r0, debug_play_step

	; Advance frame (with repeat):
	MOV r0, #OSByte_ReadKey
	MOV r1, #IKey_ArrowRight
	MOV r2, #0xff
	SWI OS_Byte
	CMP r1, #0xff
	CMPEQ r2, #0xff
	streqb r1, debug_play_step

	.2:
	; Advance frame (without repeat):
	MOV r0, #OSByte_ReadKey
	MOV r1, #IKey_S
	MOV r2, #0xff
	SWI OS_Byte
	CMP r1, #0xff
	CMPEQ r2, #0xff
	bne .3
	ldrb r0, debug_debounce_s
	cmp r0, #0
	bne .3
	strb r1, debug_play_step
	.3:
	strb r1, debug_debounce_s

	; Toggle debug info.
	MOV r0, #OSByte_ReadKey
	MOV r1, #IKey_D
	MOV r2, #0xff
	SWI OS_Byte
	CMP r1, #0xff
	CMPEQ r2, #0xff
	bne .4
	ldrb r0, debug_debounce_d
	cmp r0, #0
	bne .4
	ldrb r0, debug_show_info
	eor r0, r0, #1
	strb r0, debug_show_info
	.4:
	strb r1, debug_debounce_d

	; Toggle rasters
	MOV r0, #OSByte_ReadKey
	MOV r1, #IKey_R
	MOV r2, #0xff
	SWI OS_Byte
	CMP r1, #0xff
	CMPEQ r2, #0xff
	bne .5
	ldrb r0, debug_debounce_r
	cmp r0, #0
	bne .5
	ldrb r0, debug_show_rasters
	eor r0, r0, #1
	strb r0, debug_show_rasters
	.5:
	strb r1, debug_debounce_r

	MOV r0, #OSByte_ReadKey
	MOV r1, #IKey_A
	MOV r2, #0xff
	SWI OS_Byte
	CMP r1, #0xff
	CMPEQ r2, #0xff
	BNE .6 ; not pressed
	ldrb r0, debug_debounce_a
	cmp r0, #0
	bne .6 ; still pressed

    ; Start Again.
    mov r0, #0
    str r0, frame_counter

    .if _ENABLE_MUSIC
    mov r1, #0
	swi QTM_Pos
    .endif

	.6:
	strb r1, debug_debounce_a

	ldr pc, [sp], #4

debug_debounce_space:
	.byte 0

debug_debounce_s:
	.byte 0

debug_debounce_d:
	.byte 0

debug_debounce_r:
	.byte 0

debug_debounce_a:
	.byte 0

debug_play_pause:
	.byte _DEBUG_DEFAULT_PLAY_PAUSE

debug_play_step:
	.byte 0

debug_show_info:
	.byte _DEBUG_DEFAULT_SHOW_INFO

debug_show_rasters:
	.byte _DEBUG_DEFAULT_SHOW_RASTERS

	.p2align 2
d_StopOnFrame:
	.long _DEBUG_STOP_ON_FRAME
.endif

get_screen_addr:
	str lr, [sp, #-4]!
	adrl r0, screen_addr_input
	adrl r1, screen_addr
	swi OS_ReadVduVariables
	ldr pc, [sp], #4
	
screen_addr_input:
	.long VD_ScreenStart, -1

exit:	
	; wait for vsync (any pending buffers)
	.if _ENABLE_RASTERMAN
	swi RasterMan_Wait
	swi RasterMan_Release
	swi RasterMan_Wait
	.endif

	.if _ENABLE_MUSIC
	; disable music
	mov r0, #0
	swi QTM_Clear
	.endif

	; disable vsync event
	.if !_ENABLE_RASTERMAN
	mov r0, #OSByte_EventDisable
	mov r1, #Event_VSync
	swi OS_Byte

	; release our event handler
	mov r0, #EventV
	adr r1, event_handler
	mov r2, #0
	swi OS_Release
	.endif

	; release our error handler
	mov r0, #ErrorV
	adr r1, error_handler
	mov r2, #0
	swi OS_Release

	; Display whichever bank we've just written to
	mov r0, #OSByte_WriteDisplayBank
	ldr r1, scr_bank
	swi OS_Byte
	; and write to it
	mov r0, #OSByte_WriteVDUBank
	ldr r1, scr_bank
	swi OS_Byte

	; CLS
	mov r0, #12
	SWI OS_WriteC

	; Flush keyboard buffer.
	mov r0, #15
	mov r1, #1
	swi OS_Byte

	SWI OS_Exit

; R0=event number
.if !_ENABLE_RASTERMAN
event_handler:
	cmp r0, #Event_VSync
	movnes pc, r14

	STMDB sp!, {r0-r1, lr}

	; update the vsync counter
	LDR r0, vsync_count
	ADD r0, r0, #1
	STR r0, vsync_count

.if _SET_DISPLAY_BANK_AT_VSYNC
	; is there a new screen buffer ready to display?
	LDR r1, buffer_pending
	CMP r1, #0
	LDMEQIA sp!, {r0-r1, pc}

	; set the display buffer
	MOV r0, #0
	STR r0, buffer_pending
	MOV r0, #OSByte_WriteDisplayBank
	; some SVC stuff I don't understand :)
	STMDB sp!, {r2-r12}
	MOV r9, pc     ;Save old mode
	ORR r8, r9, #3 ;SVC mode
	TEQP r8, #0
	MOV r0,r0
	STR lr, [sp, #-4]!
	SWI XOS_Byte
.endif

.if _WRITE_VIDC_REGS_AT_VSYNC
	; is there a palette update ready to display?
	LDR r1, palette_pending
	CMP r1, #0
	.if _SET_DISPLAY_BANK_AT_VSYNC	; we're already in Supervisor Mode.
	beq .2
	.else
	LDMEQIA sp!, {r0-r1, pc}

	; Switch to Supervisor mode
	STMDB sp!, {r2-r12}
	MOV r9, pc     ;Save old mode
	ORR r8, r9, #3 ;SVC mode
	TEQP r8, #0
	MOV r0,r0
	STR lr, [sp, #-4]!
	.endif

	; Write palette directly to VIDC.
	adr r2, palette_blocks_for_banks_no_adr - 64	; THIS IS OK FOR US!
	add r1, r2, r1, lsl #6

	mov r4, #-1
	mov r0, #VIDC_Write
	mov r3, #16
.1:
	ldr r2, [r1]
	str r4, [r1], #4
	cmp r2, #-1
	beq .2
	str r2, [r0]			; write VIDC register.
	subs r3, r3, #1
	bne .1
.2:
	mov r0, #0
	str r0, palette_pending

	LDR lr, [sp], #4
	TEQP r9, #0    ;Restore old mode
	MOV r0, r0
	LDMIA sp!, {r2-r12}
.endif

	LDMIA sp!, {r0-r1, pc}
.endif

error_handler:
	STMDB sp!, {r0-r2, lr}
	.if _ENABLE_RASTERMAN
	swi RasterMan_Release
	.endif

	.if _ENABLE_MUSIC
	; disable music
	mov r0, #0
	swi QTM_Clear
	.endif
.if !_ENABLE_RASTERMAN
	MOV r0, #OSByte_EventDisable
	MOV r1, #Event_VSync
	SWI OS_Byte
	MOV r0, #EventV
	ADR r1, event_handler
	mov r2, #0
	SWI OS_Release
.endif
	MOV r0, #ErrorV
	ADR r1, error_handler
	MOV r2, #0
	SWI OS_Release
	MOV r0, #OSByte_WriteDisplayBank
	LDR r1, scr_bank
	SWI OS_Byte
	LDMIA sp!, {r0-r2, lr}
	MOVS pc, lr

show_screen_at_vsync:
	; Show current bank at next vsync
	ldr r1, scr_bank
	str r1, palette_pending
.if _SET_DISPLAY_BANK_AT_VSYNC
	str r1, buffer_pending
	; Including its associated palette
.else
	MOV r0, #OSByte_WriteDisplayBank
	swi OS_Byte
.endif
;	ldr r1, palette_block_addr
	mov pc, lr

get_next_screen_for_writing:
	; Increment to next bank for writing
	ldr r1, scr_bank
	add r1, r1, #1
	cmp r1, #Screen_Banks
	movgt r1, #1
	str r1, scr_bank

	; Now set the screen bank to write to
	mov r0, #OSByte_WriteVDUBank
	swi OS_Byte

	; Back buffer address for writing bank stored at screen_addr
	b get_screen_addr

; ============================================================================
; Global vars.
; ============================================================================

; TODO: rename these to be clearer.
scr_bank:
	.long 0				; current VIDC screen bank being written to.

palette_block_addr:
	.long 0				; (optional) ptr to a block of palette data for the screen bank being written to.

vsync_count:
	.long 0				; current vsync count from start of exe.

last_vsync:
	.long 0				; vsync count at start of previous frame.

vsync_delta:
	.long 0

frame_counter:
    .long 0

buffer_pending:
	.long 0				; screen bank number to display at vsync.

palette_pending:
	.long 0				; (optional) ptr to a block of palette data to set at vsync.

screen_addr:
	.long 0				; ptr to the current VIDC screen bank being written to.


; ============================================================================
; Additional code modules
; ============================================================================

.include "src/check-rows.asm"

.include "lib/maths.asm"
.include "lib/mode9-screen.asm"
.include "lib/mode9-palette.asm"
.if _ENABLE_RASTERMAN
.include "lib/rasters.asm"
.endif

.if _ENABLE_ROCKET
.include "lib/rocket.asm"
.endif

.if _ENABLE_LUAPOD
.include "src/luapod.asm"
.endif

; ============================================================================
; Data Segment
; ============================================================================

grey_palette:
.if Check_Layers_per_bitplane == 4
	.long 0x00000000	; 00 00
	.long 0x000000ff	; 00 01	<= layer 0
	.long 0x0000ff00	; 00 10	<= layer 1
	.long 0x0000ffff	; 00 11	<= layer 2
	.long 0x00ff0000	; 01 00	<= layer 3
	.long 0x00555555	; 01 01
	.long 0x00666666	; 01 10
	.long 0x00777777	; 01 11
	.long 0x00888888	; 10 00 
	.long 0x00ff00ff	; 10 01	<= layer 4
	.long 0x00ffff00	; 10 10	<= layer 5
	.long 0x00880088	; 10 11	<= layer 6
	.long 0x00888800	; 11 00	<= layer 7
	.long 0x00DDDDDD	; 11 01
	.long 0x00EEEEEE	; 11 10
	.long 0x00FFFFFF	; 11 11
.else
	.long 0x00000000	; 00 00
	.long 0x000000ff	; 00 01	<= layer 0
	.long 0x0000ff00	; 00 10	<= layer 1
	.long 0x0000ffff	; 00 11	<= layer 2
	.long 0x00ff0000	; 01 00	<= layer 3
	.long 0x00ff0000	; 01 01	<= layer 3
	.long 0x00ff0000	; 01 10	<= layer 3
	.long 0x00ff0000	; 01 11	<= layer 3
	.long 0x00ff00ff	; 10 00	<= layer 4
	.long 0x00ff00ff	; 10 01	<= layer 4
	.long 0x00ff00ff	; 10 10	<= layer 4
	.long 0x00ff00ff	; 10 11	<= layer 4
	.long 0x00ffff00	; 11 00	<= layer 5
	.long 0x00ffff00	; 11 01	<= layer 5
	.long 0x00ffff00	; 11 10	<= layer 5
	.long 0x00ffff00	; 11 11	<= layer 5
.endif

; ============================================================================

palette_blocks_for_banks_no_adr:
.rept Screen_Banks
	.long 0xffffffff
	.skip 60
.endr

palette_osword_block:
    .skip 8
    ; logical colour
    ; physical colour (16)
    ; red
    ; green
    ; blue
    ; (pad)

; ============================================================================
; DATA Segment
; ============================================================================

.include "src/data.asm"

; ============================================================================
; BSS Segment
; ============================================================================

.include "src/bss.asm"
