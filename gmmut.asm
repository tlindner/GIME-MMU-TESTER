 PRAGMA autobranchlength
 PRAGMA cescapes
 org $6000
in_param rmb 1
out_param rmb 1
gime rmb 1 # boolean; true if gime, false if jr
text_block rmb 1 # mmu block of text screen
text_address rmb 2 # address of text screen
text_position fdb 0
gime_0 rmb 1 shadow register
gime_1 rmb 1 shadow register

start
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
 bsr turn_off_ints
# turn on mmu, task 0 (for both gime and jr)
 lda #$cc
 sta gime_0
 sta $ff90
 lda #$0
 sta gime_1
 sta $ff91

main_menu
 bsr clear_screen
 bsr strout
 fcc "GIME MMU TESTER\r"
 fcc "2MB AWARE\r"
 fcc "1) MMU READ BACK 6 BITS?\r"
 fcc "2) MMU READ BACK 8 BITS?\r"
 fcc "3) COUNT AVAILABLE BANKS\r"
 fcc "4) TEST CONSTANT RAM, TASK 0\r"
 fcc "5) TEST CONSTANT RAM, TASK 1\r"
 fcn "6) SHOW VDG WRAP AROUND\r"
init_loop
 ldx #text_address
 ldd text_position
 leax d,x
 com ,x
 bsr keyin
 cmpa #0
 beq init_loop
 pshs a
 bsr chrout
 lda #$0d
 bsr chrout
 lda ,s
 cmpa #'3
 beq count_mmu_blocks
 cmpa #'6
 beq vdg_wrap
 bra done_after
return_from_test
 puls a
 cmpa #'3
 beq report_count_mmu
done_after
 bsr strout
 fcn "PRESS ANY KEY TO CONTINUE\r"
da_wait
 bsr keyin
 cmpa #0
 beq da_wait
 jmp main_menu

count_mmu_blocks
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
 jmp return_from_test 

report_count_mmu
 lda out_param
 cmpa #$f0
 beq rc_128k
 cmpa #$e0
 beq rc_256k
 cmpa #$c0
 beq rc_512k
 cmpa #$80
 beq rc_1024k
 cmpa #$00
 beq rc_2048k
 bsr strout
 fcn "UNKNOWN RAM AMOUNT\r"
 bra done_after
rc_128k
 bsr strout
 fcn "128K - $30 TO $3F\r"
 bra done_after
rc_256k
 bsr strout
 fcn "256K - $20 TO $3F\r"
 bra done_after
rc_512k
 bsr strout
 fcn "512K - $00 TO $3F\r"
 bra done_after
rc_1024k
 bsr strout
 fcn "1024K - $00 TO $7F\r"
 bra done_after
rc_2048k
 bsr strout
 fcn "2048K - $00 TO $FF\r"
 bra done_after


 
vdg_wrap
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

loop1 bra loop1

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

clear_screen
#
# subroutine
# clear the text screen
#
 ldx #$0400
 ldd #$6060
cs_loop
 std ,x++
 cmpx #$600
 bne cs_loop
 clr text_position
 clr text_position+1
 rts
 
strout
#
# subroutine
# Output string to screen
#
 puls u
so_loop
 lda ,u+
 beq so_done
 jsr chrout
 bra so_loop
so_done
 tfr u,pc
 
chrout
#
# subroutine
# output to text screen
#
 cmpa #$0d
 beq co_carrage_return
 cmpa #$60
 bge co_sub60
 cmpa #$40
 bge co_out
co_add40
 adda #$40
 bra co_out
co_sub60
 suba #$60
co_out
 pshs a
 ldx text_address
 ldd text_position
 leax d,x
 addd #1
 std text_position
 puls a
 sta ,x
 ldd text_position
 bra co_check_scroll
co_carrage_return
 ldd text_position
 addd #32
 andb #%11100000
 std text_position
co_check_scroll
 cmpd #512
 beq co_scroll
 rts
co_scroll
 ldx text_address
co_scroll_loop
 ldd 32,x
 std ,x++
 cmpx #$0600-32
 bne co_scroll_loop
 ldd #$6060
co_clear_last_line_loop
 std ,x++
 cmpx #$0600
 bne co_clear_last_line_loop
 ldd text_position
 subd #32
 std text_position
 rts

pia0 equ $ff00
keybuf rmb 8 keyboard memory buffer
casflg rmb 1 upper case/lower case flag: $ff=upper, 0=lower
debval fdb $45e keyboard debounce delay (set to $45e)

la1c1 clr pia0+2 clear column strobe
 lda pia0 read key rows
 coma complement row data
 asla shift off joystick data
 beq la244 return if no keys or fire buttons down
#
# subroutine
# this routine gets a keystroke from the keyboard if a key
# is down. it returns zero true if there was no key down.
#
keyin pshs u,x,b save registers
 ldu #pia0 point u to pia0
 ldx #keybuf point x to keyboard memory buffer
 clra * clear carry flag, set column counter (acca)
 deca * to $ff
 pshs x,a save column ctr & 2 blank (x reg) on stack
 sta 2,u initialize column strobe to $ff
la1d9 rol 2,u * rotate column strobe data left 1 bit, carry
 bcc la220 * into bit 0 - branch if 8 shifts done
 inc ,s increment column counter
 bsr la23a read keyboard row data
 sta 1,s temp store key data
 eora ,x set any bit where a key has moved
 anda ,x acca=0 if no new key down, <70 if key was released
 ldb 1,s get new key data
 stb ,x+ store it in key memory
 tsta was a new key down?
 beq la1d9 no-check another column
 ldb 2,u * get column strobe data and
 stb 2,s * temp store it on the stack
* this routine converts the key depression into a number
* from 0-50 in accb corresponding to the key that was down
 ldb #$f8 to make sure accb=0 after first addb #8
la1f4 addb #$08 add 8 for each row of keyboard
 lsra acca has the row number of this key - add 8 for each row
 bcc la1f4 go on until a zero appears in the carry flag
 addb ,s add in the column number
* now convert the value in accb into ascii
 beq la245
 cmpb #26 the ‘at sign’ key was down was it a letter?
 bhi la247 no
 orb #$40 yes, convert to upper case ascii
 bsr la22e check for the shift key
 ora casflg * ‘or’ in the case flag & branch if in upper
 bne la20c * case mode or shift key down
 orb #$20 convert to lower case
la20c stb ,s temp store ascii value
 ldx debval get keyboard debounce
 bsr la1ae
 ldb #$ff set column strobe to all ones (no
 bsr la238 strobe) and read keyboard
 inca = incr row data, acca now 0 if no joystick
 bne la220 = button down. branch if joystick button down
la21a ldb 2,s get column strobe data
 bsr la238 read a key
 cmpa 1,s is it the same key as before debounce?
la220 puls a,x remove temp slots from the stack and recover
* the ascii value of the key
 bne la22b not the same key or joystick button
 cmpa #$12 is shift zero down?
 bne la22c no
 com casflg yes, toggle upper case/lower case flag
la22b clra set zero flag to indicate no new key down
la22c puls b,x,u,pc restore registers

* test for the shift key
la22e lda #$7f column strobe
 sta 2,u store to pla
 lda ,u read key data
 coma *
 anda #$40 * set bit 6 if shift key down
 rts return

* read the keyboard
la238 stb 2,u save new column strobe value
la23a lda ,u read pia0, port a to see if key is down
* a bit will be zero if one is
 ora #$80 mask off the joystick comparator input
 tst $02,u are we strobing column 7?
 bmi la244 no
 ora #$c0 yes, force row 6 to be high - this will cause
* the shift key to be ignored
la244 rts return

la245 ldb #51 code for ‘at sign’
la247 ldx #contab-$36 point x to control code table
 cmpb #33 key number <33?
 blo la264 yes (arrow keys, space bar, zero)
 ldx #contab-$54 point x to middle of control table
 cmpb #48 key number >48?
 bhs la264 yes (enter,clear,break,at sign)
 bsr la22e check shift key (acca will contain status)
 cmpb #43 is key a number, colon or semicolon?
 bls la25d yes
 eora #$40 toggle bit 6 of acca which contains the shift data
* only for slash,hyphen,period,comma
la25d tsta shift key down?
 bne la20c yes
 addb #$10 no, add in ascii offset correction
 bra la20c go check for debounce
la264 aslb mult accb by 2 - there are 2 entries in control
* table for each key - one shifted, one not
 bsr la22e check shift key
 beq la26a not down
 incb add one to get the shifted value
la26a ldb b,x get ascii code from control table
 bra la20c go check debounce
la1ae jmp la7d3 delay while x decrements to zero
* delay while decrementing x to zero
la7d3 leax -1,x decrement x
 bne la7d3 branch if not zero
 rts
*
*
* control table unshifted, shifted values
contab fcb $5e,$5f up arrow
 fcb $0a,$5b down arrow
 fcb $08,$15 right arrow
 fcb $09,$5d left arrow
 fcb $20,$20 space bar
 fcb $30,$12 zero
 fcb $0d,$0d enter
 fcb $0c,$5c clear
 fcb $03,$03 break
 fcb $40,$13 at sign




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
 
 
 
 


