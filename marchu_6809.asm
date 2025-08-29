; March U
; Inspired by
; https://github.com/misterblack1/appleII_deadtest

start_memory equ $8000
end_memory equ $a000

mu_start
 ldy #test_table
 
marchU
 lda ,y			; get the test value into a
 tfr a,b		; save the test value into b
 ldx #start_memory

marchU0
 sta ,x+		; w0 - write the test value
 cmpx #end_memory
 bne marchU0
 
 ldx #start_memory
marchU1
 eora ,x		; r0 - read and compare with test value (by XOR'ing with accumulator)
 bne mem_bad	; if bits differ, location is bad
 tfr b,a		; get the test value
 coma			; invert
 sta ,x			; w1 - write the inverted test value
 eora ,x		; r1 - read the same value back and compare using XOR
 bne mem_bad	; if bits differ, location is bad
 tfr b,a		; get the test value
 sta ,x+		; w0 - write the test value to the memory location
 cmpx #end_memory
 bne marchU1
 
marchU1delay
 bsr delay100ms
 	
 ldx #start_memory
#step 2; up - r0,w1
marchU2
 tfr b,a		; recover test value
 eora ,x		; r0 - read and compare with test value (by XOR'ing with accumulator)
 bne mem_bad	; if bits differ, location is bad
 tfr b,a		; get the test value
 coma			; invert
 sta ,x+		; w1 - write the inverted test value
 cmpx #end_memory
 bne marchU2
 
marchU2delay
 bsr delay100ms
 bra continue
 
mem_bad
 jmp mem_error

delay100ms
 ldx #$0
!
 leax 1,x
 bne <
 rts
	 
continue
 ldx #end_memory-1
 tfr b,a		; recover test value
 coma			; invert

; step 3; down - r1,w0,r0,w1
marchU3
 eora ,x		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
 bne mem_bad	; if bits differ, location is bad
 tfr b,a		; get the test value
 sta ,x			; w0 - write the test value
 eora ,x		; r0 - read the same value back and compare using XOR
 bne mem_bad	; if bits differ, location is bad
 tfr b,a		; get a fresh copy of the test value
 coma			; invert
 sta ,x			; w1 - write the inverted test value
 leax -1,x		; count down
 cmpx #start_memory-1	; did we wrap?
 bne marchU3	; repeat until Y overflows back to FF

; step 4; down - r1,w0
 ldx #end_memory-1
marchU4
 eora ,x		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
 bne mem_bad	; if bits differ, location is bad
 tfr b,a		; get the test value
 sta ,x			; w0 - write the test value
 coma			; invert
 leax -1,x		; count down
 cmpx #start_memory-1	; did we wrap?
 bne marchU4	; repeat until Y overflows back to FF

 leay 1,y		; choose the next one
 cmpy #test_table_end
 lbne marchU		; start again with next value

mem_good
 orcc #%00000100 # set z
 rts

mem_error
 andcc #%11111011 # clear z
 rts

test_table
 fcb $80,$40,$20,$10
 fcb $08,$04,$02,$01
 fcb $00,$FF,$A5,$5A 
test_table_end equ *
 
