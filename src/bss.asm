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
	.skip Rows_Width * Rows_Height / 2

.p2align 6
check_rows_pixel_1_no_adr:
	.skip Rows_Width * Rows_Height / 2

.p2align 6
check_rows_pixel_2_no_adr:
	.skip Rows_Width * Rows_Height / 2

.p2align 6
check_rows_pixel_3_no_adr:
	.skip Rows_Width * Rows_Height / 2

.p2align 6
check_rows_pixel_4_no_adr:
	.skip Rows_Width * Rows_Height / 2

.p2align 6
check_rows_pixel_5_no_adr:
	.skip Rows_Width * Rows_Height / 2

.p2align 6
check_rows_pixel_6_no_adr:
	.skip Rows_Width * Rows_Height / 2

.p2align 6
check_rows_pixel_7_no_adr:
	.skip Rows_Width * Rows_Height / 2

.p2align 6
check_line_combos:
	.skip Screen_Stride * Check_Combos

; ============================================================================

.include "lib/lib_bss.asm"

; ============================================================================
