 PRAGMA autobranchlength
 org $6000
in_param rmb 1
out_param rmb 1
gime rmb 1 # boolean; true if gime, false if jr
text_block rmb 1 # mmu block of text screen
text_address rmb 2 # address of text screen
gime_0 rmb 1 shadow register
gime_1 rmb 1 shadow register

start
 lda in_param
 cmpa #0
 beq init_tests
 cmpa #3
 beq count_mmu_blocks
 cmpa #6
 beq vdg_wrap
# nothing to do exit.
 rts

init_tests
# flag gime
 lda $ffa0
 beq init_jr
 
init_gime
 lda #$ff
 sta gime
 lda #$38
 sta text_block
 ldd #$0400
 std text_address
# gime mmu blocks initialized by Color BASIC
 bra init_done

init_jr
# flag Jr
 lda #$0
 sta gime
# load default mmu
 ldx #$ffa0
 ldy #$ffa8
 ldb #8
init_jr_loop
 sta ,x+
 sta ,y+
 inca
 decb
 bne init_jr_loop
 lda #$0
 sta text_block
 ldd #$0400
 std text_address
# all ram mode
 ldx #$8000
ram_loop
 sta $ffde
 lda ,x
 sta $ffdf
 sta ,x+
 cmpx #$ff00
 bne ram_loop

init_done
# turn on mmu, task 0 (for both gime and jr)
 lda #$cc
 sta gime_0
 sta $ff90
 lda #$0
 sta gime_1
 sta $ff91
 rts
 
count_mmu_blocks
 bsr turn_off_ints
 bsr save_task_0
# Put mmu block number in first byte of each block
# and save value
 clrb
 ldx #buffer2
count_bocks_loop
 stb $ffa1
 lda $2000
 sta ,x+
 stb $2000
 incb
 bne count_bocks_loop
# fill buffer with what is
# left in the first byte of each block
 clrb
 ldx #buffer
count_loop
 stb $ffa1
 lda $2000
 sta ,x+
 incb
 bne count_loop
# report first byte of buffer
 lda buffer
 sta out_param
# fix up overwritten bytes
 clrb
 ldx #buffer2
restore_loop
 stb $ffa1
 lda ,x+
 sta $2000
 incb
 bne restore_loop
 bsr restore_task_0
 bsr turn_on_ints
 rts 

vdg_wrap
 bsr turn_off_ints
 sta $ffdf # all ram mode

# set SAM to highest base address ($FE00)
# for video
 lda #%01111111
 bsr store_a_into_sam_offset

 lda #$3f
 sta $ffa2
 bsr write_string
 fdb $4000
 fcn "Page: 3f, Offset: 0000 "
 bsr write_string
 fdb $5e00
 fcn "Page: 3f, Offset: 1e00 "
 
 lda #$7
 sta $ffa2
 bsr write_string
 fdb $4000
 fcn "Page: 07, Offset: 0000 "
 bsr write_string
 fdb $5e00
 fcn "Page: 07, Offset: 1e00 "

 lda #$00
 sta $ffa2
 bsr write_string
 fdb $4000
 fcn "Page: 00, Offset: 0000 "
 
 lda #$40
 sta $ffa2
 bsr write_string
 fdb $4000
 fcn "Page: 40, Offset: 0000 "

 lda #$8
 sta $ffa2
 bsr write_string
 fdb $4000
 fcn "Page: 08, Offset: 0000 "

loop bra loop

 clra
 pshs a
loop_a
 lda ,s
 tfr a,b
 andb #%00111111
 cmpb #$3b
 beq skip
 sta $ffa0
 ldx #hex
 lsra
 lsra
 lsra
 lsra
 lda a,x
 sta string+6
 sta string1+6
 lda ,s
 anda #%00001111 
 lda a,x
 sta string+7
 sta string1+7

 bsr write_string
 fdb $0000
string
 fcn "Page: XX, Offset: 0000 "
 
 bsr write_string
 fdb $1000
string1
 fcn "Page: XX, Offset: 1000 "
 
skip
 inc ,s
 bne loop_a

# show all pages
 clr ,s
loop_show_pages
 lda ,s
 bsr store_a_into_sam_offset
 ldx #0
delay_loop
 leax 1,x
 bne delay_loop
 inc ,s
 bra loop_show_pages
 
wait jmp wait

hex fcc "0123456789abcdef"

write_string
 puls u
 ldy ,u++
write_string_loop
 lda ,u+
 beq write_string_done
 suba #32
 bsr write_character
 leay (-8*32)+1,y
 bra write_string_loop
write_string_done
 tfr u,pc

write_character
 ldx #bitmap_font
 ldb #8
 mul
 leax d,x
 ldb #8
write_character_loop
 lda ,x+
 sta ,y
 leay 32,y
 decb
 bne write_character_loop
 rts

vdg_wait
# Set bank zero to first VDG page
 lda #$3f-8
 sta $ffa0
# Set bank one to page after 64k
 lda #$3f+1
 sta $ffa1
# save three bytes, and set
# their initial value
 lda >$0
 sta saved_bytes+0
 clr >$0
 lda $2000
 sta saved_bytes+1
 lda $fe00
 sta saved_bytes+2
 lda #$ff
 sta $2000
 sta $fe00
 ldx #0
 ldb #15
vdg_loop
 leax 1,x
 bne vdg_loop
 com >$0
 com $2000
 com $fe00
 decb
 bne vdg_loop

# restore memory values
 lda saved_bytes+0
 sta >$0
 lda saved_bytes+1
 sta $2000
 lda saved_bytes+2
 sta $fe00

# restore mmu banks
 bsr restore_task_0
 bsr turn_on_ints

# return
 rts
saved_task rmb 8
saved_bytes rmb 3
 
#
# subroutine
# Store reg a into sam video offset register
#
store_a_into_sam_offset
 ldb #7
 ldx #$ffc6
 rola
loop_store_a
 rola
 bcc set_clear
set_set
 leax 1,x
 sta ,x+
 bra set_done
set_clear
 sta ,x++
set_done 
 decb
 bne loop_store_a
 rts

#
# subroutine
# turn off all interrupts
#
turn_off_ints
 orcc #$50
# turn off pia0 ints
#  clra
#  sta $ff01
#  sta $ff03
# # turn off pia1 ints
#  clra
#  sta $ff21
#  sta $ff23
# # turn off gime ints
#  lda gime_0
#  anda #%11001111
#  sta $ff90
 rts

#
# subroutine
# turn on all interrupts
#
turn_on_ints
# turn on pia0 ints
#  lda #$34
#  sta $ff01
#  lda #$b5
#  sta $ff03
# # turn on pia1 ints
#  lda #$34
#  sta $ff21
#  lda #$37
#  sta $ff23
# # turn off gime ints
#  lda gime_0
#  anda #%11001111
#  sta $ff90
 andcc #$af
 rts
 
restore_task_0
#
# subroutine
# restore mmu regs at ffa0
#
 ldy #saved_task
 ldx #$ffa0
 bra copy_task
 
save_task_0
#
# subroutine
# save mmu regs at ffa0
#
 ldy #$ffa0
 ldx #saved_task
copy_task
 ldd ,y++
 std ,x++
 ldd ,y++
 std ,x++
 ldd ,y++
 std ,x++
 ldd ,y++
 std ,x++
 rts

buffer rmb 256
buffer2 rmb 256
bitmap_font
 fcb $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ( )
 fcb $e7,$c3,$c3,$e7,$e7,$ff,$e7,$ff (!)
 fcb $93,$93,$ff,$ff,$ff,$ff,$ff,$ff (")
 fcb $93,$93,$01,$93,$01,$93,$93,$ff (#)
 fcb $cf,$83,$3f,$87,$f3,$07,$cf,$ff ($)
 fcb $ff,$39,$33,$e7,$cf,$99,$39,$ff (%)
 fcb $c7,$93,$c7,$89,$23,$33,$89,$ff (&)
 fcb $9f,$9f,$3f,$ff,$ff,$ff,$ff,$ff (')
 fcb $e7,$cf,$9f,$9f,$9f,$cf,$e7,$ff (()
 fcb $9f,$cf,$e7,$e7,$e7,$cf,$9f,$ff ())
 fcb $ff,$99,$c3,$00,$c3,$99,$ff,$ff (*)
 fcb $ff,$cf,$cf,$03,$cf,$cf,$ff,$ff (+)
 fcb $ff,$ff,$ff,$ff,$ff,$cf,$cf,$9f (,)
 fcb $ff,$ff,$ff,$03,$ff,$ff,$ff,$ff (-)
 fcb $ff,$ff,$ff,$ff,$ff,$cf,$cf,$ff (.)
 fcb $f9,$f3,$e7,$cf,$9f,$3f,$7f,$ff (/)
 fcb $83,$39,$31,$21,$09,$19,$83,$ff (0)
 fcb $cf,$8f,$cf,$cf,$cf,$cf,$03,$ff (1)
 fcb $87,$33,$f3,$c7,$9f,$33,$03,$ff (2)
 fcb $87,$33,$f3,$c7,$f3,$33,$87,$ff (3)
 fcb $e3,$c3,$93,$33,$01,$f3,$e1,$ff (4)
 fcb $03,$3f,$07,$f3,$f3,$33,$87,$ff (5)
 fcb $c7,$9f,$3f,$07,$33,$33,$87,$ff (6)
 fcb $03,$33,$f3,$e7,$cf,$cf,$cf,$ff (7)
 fcb $87,$33,$33,$87,$33,$33,$87,$ff (8)
 fcb $87,$33,$33,$83,$f3,$e7,$8f,$ff (9)
 fcb $ff,$cf,$cf,$ff,$ff,$cf,$cf,$ff (:)
 fcb $ff,$cf,$cf,$ff,$ff,$cf,$cf,$9f (;)
 fcb $e7,$cf,$9f,$3f,$9f,$cf,$e7,$ff (<)
 fcb $ff,$ff,$03,$ff,$ff,$03,$ff,$ff (=)
 fcb $9f,$cf,$e7,$f3,$e7,$cf,$9f,$ff (>)
 fcb $87,$33,$f3,$e7,$cf,$ff,$cf,$ff (?)
 fcb $83,$39,$21,$21,$21,$3f,$87,$ff (@)
 fcb $cf,$87,$33,$33,$03,$33,$33,$ff (A)
 fcb $03,$99,$99,$83,$99,$99,$03,$ff (B)
 fcb $c3,$99,$3f,$3f,$3f,$99,$c3,$ff (C)
 fcb $07,$93,$99,$99,$99,$93,$07,$ff (D)
 fcb $01,$9d,$97,$87,$97,$9d,$01,$ff (E)
 fcb $01,$9d,$97,$87,$97,$9f,$0f,$ff (F)
 fcb $c3,$99,$3f,$3f,$31,$99,$c1,$ff (G)
 fcb $33,$33,$33,$03,$33,$33,$33,$ff (H)
 fcb $87,$cf,$cf,$cf,$cf,$cf,$87,$ff (I)
 fcb $e1,$f3,$f3,$f3,$33,$33,$87,$ff (J)
 fcb $19,$99,$93,$87,$93,$99,$19,$ff (K)
 fcb $0f,$9f,$9f,$9f,$9d,$99,$01,$ff (L)
 fcb $39,$11,$01,$01,$29,$39,$39,$ff (M)
 fcb $39,$19,$09,$21,$31,$39,$39,$ff (N)
 fcb $c7,$93,$39,$39,$39,$93,$c7,$ff (O)
 fcb $03,$99,$99,$83,$9f,$9f,$0f,$ff (P)
 fcb $87,$33,$33,$33,$23,$87,$e3,$ff (Q)
 fcb $03,$99,$99,$83,$93,$99,$19,$ff (R)
 fcb $87,$33,$1f,$8f,$e3,$33,$87,$ff (S)
 fcb $03,$4b,$cf,$cf,$cf,$cf,$87,$ff (T)
 fcb $33,$33,$33,$33,$33,$33,$03,$ff (U)
 fcb $33,$33,$33,$33,$33,$87,$cf,$ff (V)
 fcb $39,$39,$39,$29,$01,$11,$39,$ff (W)
 fcb $39,$39,$93,$c7,$c7,$93,$39,$ff (X)
 fcb $33,$33,$33,$87,$cf,$cf,$87,$ff (Y)
 fcb $01,$39,$73,$e7,$cd,$99,$01,$ff (Z)
 fcb $87,$9f,$9f,$9f,$9f,$9f,$87,$ff ([)
 fcb $3f,$9f,$cf,$e7,$f3,$f9,$fd,$ff (\)
 fcb $87,$e7,$e7,$e7,$e7,$e7,$87,$ff (])
 fcb $ef,$c7,$93,$39,$ff,$ff,$ff,$ff (^)
 fcb $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00 (_)
 fcb $cf,$cf,$e7,$ff,$ff,$ff,$ff,$ff (`)
 fcb $ff,$ff,$87,$f3,$83,$33,$89,$ff (a)
 fcb $1f,$9f,$9f,$83,$99,$99,$23,$ff (b)
 fcb $ff,$ff,$87,$33,$3f,$33,$87,$ff (c)
 fcb $e3,$f3,$f3,$83,$33,$33,$89,$ff (d)
 fcb $ff,$ff,$87,$33,$03,$3f,$87,$ff (e)
 fcb $c7,$93,$9f,$0f,$9f,$9f,$0f,$ff (f)
 fcb $ff,$ff,$89,$33,$33,$83,$f3,$07 (g)
 fcb $1f,$9f,$93,$89,$99,$99,$19,$ff (h)
 fcb $cf,$ff,$8f,$cf,$cf,$cf,$87,$ff (i)
 fcb $f3,$ff,$f3,$f3,$f3,$33,$33,$87 (j)
 fcb $1f,$9f,$99,$93,$87,$93,$19,$ff (k)
 fcb $8f,$cf,$cf,$cf,$cf,$cf,$87,$ff (l)
 fcb $ff,$ff,$33,$01,$01,$29,$39,$ff (m)
 fcb $ff,$ff,$07,$33,$33,$33,$33,$ff (n)
 fcb $ff,$ff,$87,$33,$33,$33,$87,$ff (o)
 fcb $ff,$ff,$23,$99,$99,$83,$9f,$0f (p)
 fcb $ff,$ff,$89,$33,$33,$83,$f3,$e1 (q)
 fcb $ff,$ff,$23,$89,$99,$9f,$0f,$ff (r)
 fcb $ff,$ff,$83,$3f,$87,$f3,$07,$ff (s)
 fcb $ef,$cf,$83,$cf,$cf,$cb,$e7,$ff (t)
 fcb $ff,$ff,$33,$33,$33,$33,$89,$ff (u)
 fcb $ff,$ff,$33,$33,$33,$87,$cf,$ff (v)
 fcb $ff,$ff,$39,$29,$01,$01,$93,$ff (w)
 fcb $ff,$ff,$39,$93,$c7,$93,$39,$ff (x)
 fcb $ff,$ff,$33,$33,$33,$83,$f3,$07 (y)
 fcb $ff,$ff,$03,$67,$cf,$9b,$03,$ff (z)
 fcb $e3,$cf,$cf,$1f,$cf,$cf,$e3,$ff ({)
 fcb $e7,$e7,$e7,$ff,$e7,$e7,$e7,$ff (|)
 fcb $1f,$cf,$cf,$e3,$cf,$cf,$1f,$ff (})
 fcb $89,$23,$ff,$ff,$ff,$ff,$ff,$ff (~)
 fcb $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ( )
 
 IFGT *-$7fff
 ERROR "Program to large"
 ENDC

 end start
 
 
 
 


