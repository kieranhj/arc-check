; ============================================================================
; Library module config header (include at start).
; ============================================================================

.equ _INCLUDE_DIVIDE, 0
.equ _USE_RECIPROCAL_TABLE, (_INCLUDE_DIVIDE && 1)

.equ _INCLUDE_SQRT, 0

.equ _INCLUDE_POLYGON, 0
.equ _INCLUDE_SPAN_GEN, 0

.equ _INCLUDE_SINE, 1
.equ _MAKE_SINUS_TABLE, 0       ; TODO: Put back sine table generation!

.equ _INCLUDE_VECTOR, 0
.equ _INCLUDE_MATRIX, 0
