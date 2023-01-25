; ============================================================================
; Library module BSS.
; ============================================================================

.p2align 6

.if _INCLUDE_POLYGON
polygon_span_table_no_adr:
    .skip Screen_Height * 4     ; per scanline.
.endif

; ============================================================================

.if _USE_RECIPROCAL_TABLE
reciprocal_table_no_adr:
	.skip 65536*4
.endif

; ============================================================================

.if _INCLUDE_SPAN_GEN
gen_code_pointers_no_adr:
	.skip	4*8*MAXSPAN

gen_code_start_no_adr:
.endif

; ============================================================================
