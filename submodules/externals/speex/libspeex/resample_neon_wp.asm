	AREA resampleNeonWP,CODE,READONLY,THUMB
	EXPORT inner_product_single_neon
	EXPORT inner_product_neon

inner_product_single_neon FUNCTION
	; r0 contains a, r1 contains b, r2 contains len
	stmdb sp!,{r4-r6,lr}	; save registers on the stack
	; save len
	mov r4, r2
	mov r5, r0
	mov r6, r1
	vmov.i16 q0, #0			; clear q0
	
loop_single
	vld1.16 {d2,d3},[r5]!	; load 8 values from a in q1
	vld1.16 {d4,d5},[r6]!	; load 8 values from b in q2
	vmlal.s16 q0, d2, d4	; multiply-add 4 first values (16b) into q0 (32b)
	vmlal.s16 q0, d3, d5	; multiply-add 4 last values (16b) into q0 (32b)
	subs r4, r4, #8			; decrement len by 8
	bne loop_single			; loop if needed

	vpaddl.s32 q0, q0		; add individual 32b results
	vqadd.s64 d0, d0, d1	; store in 64b
	vmov.32 r0, d0[0]		; store result in ret as 32b
	ldmeq sp!,{r4-r6,pc}	; restore registers from the stack
	ENDP

inner_product_neon FUNCTION
	; r0 contains a, r1 contains b, r2 contains len
	stmdb sp!,{r4-r6,lr}	; save registers on the stack
	; save len
	mov r4, r2
	mov r5, r0
	mov r6, r1
	vmov.i16 q0, #0			; clear q0

loop
	vld1.16 {d2,d3},[r5]!	; load 8 values from a in q1
	vld1.16 {d4,d5},[r6]!	; load 8 values from b in q2
	vmlal.s16 q0, d2, d4	; multiply-add 4 first values (16b) into q0 (32b)
	vmlal.s16 q0, d3, d5	; multiply-add 4 last values (16b) into q0 (32b)
	subs r4, r4, #8			; decrement len by 8
	bne loop				; loop if needed

	vpaddl.s32 q0, q0		; add individual 32b results
	vshr.s64 q0, q0, #6		; right shit >> 6
	vqadd.s64 d0, d0, d1	; store in 64b
	vmov.32 r0, d0[0]		; store result in ret as 32b
	ldmeq sp!,{r4-r6,pc}	; restore registers from the stack
	ENDP

	END
