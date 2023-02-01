; ============================================================================
; BSS.
; ============================================================================

.bss

.p2align 6

; ============================================================================

stack_no_adr:
    .skip 1024
stack_base_no_adr:

; ============================================================================

.if _ENABLE_RASTERMAN
vidc_table_1_no_adr:
	.skip 256*4*4

; TODO: Can we get rid of these?
vidc_table_2_no_adr:
	.skip 256*4*4

vidc_table_3_no_adr:
	.skip 256*8*4

memc_table_no_adr:
	.skip 256*2*4
.endif

; ============================================================================

.p2align 6
check_rows_pixel_0_no_adr:
	.skip Rows_Width_Bytes * Check_Num_Depths

.p2align 6
check_rows_pixel_1_no_adr:
	.skip Rows_Width_Bytes * Check_Num_Depths

.p2align 6
check_rows_pixel_2_no_adr:
	.skip Rows_Width_Bytes * Check_Num_Depths

.p2align 6
check_rows_pixel_3_no_adr:
	.skip Rows_Width_Bytes * Check_Num_Depths

.p2align 6
check_rows_pixel_4_no_adr:
	.skip Rows_Width_Bytes * Check_Num_Depths

.p2align 6
check_rows_pixel_5_no_adr:
	.skip Rows_Width_Bytes * Check_Num_Depths

.p2align 6
check_rows_pixel_6_no_adr:
	.skip Rows_Width_Bytes * Check_Num_Depths

.p2align 6
check_rows_pixel_7_no_adr:
	.skip Rows_Width_Bytes * Check_Num_Depths

.p2align 6
check_line_combos_no_adr:
	.skip Screen_Stride * Check_Combos

.if _DUAL_PF
.p2align 6
check_line_combos_PF_no_adr:
	.skip Screen_Stride * Check_Combos

.if check_line_combos_PF_no_adr - check_line_combos_no_adr != Screen_Stride * Check_Combos
.error "Expected check_line_combos_PF_no_adr to be immediately after check_line_combos_no_adr."
.endif

.p2align 6
check_scanline_bitmask_no_adr:
	.skip Screen_Height * 4
.endif

.p2align 6
check_depths_dx_no_adr:
	.skip Check_Num_Depths * 4

; ============================================================================

.include "lib/lib_bss.asm"

; ============================================================================
