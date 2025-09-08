 PRAGMA autobranchlength
 PRAGMA cescapes

 org $6001
out_param rmb 1
gime_flag rmb 1 # boolean; true if gime, false if jr
text_block rmb 1 # mmu block of text screen
text_address rmb 2 # address of text screen
text_position rmb 2 # cursor offset
gime_0 rmb 1 # shadow register
gime_1 rmb 1 # shadow register
gime_video_mode rmb 1 # shadow register
save_pia0a rmb 1
save_pia0b rmb 1
save_palette rmb 1
tts_pass_flag rmb 1
randomseed rmb 1  
saved_task rmb 8
keybuf rmb 8 keyboard memory buffer
casflg rmb 1 upper case/lower case flag: $ff=upper, 0=lower
first_buffer rmb 256
last_buffer rmb 256
which_buffer rmb 2
check_address rmb 2
mmu_width_flag rmb 1

 ifdef CART
 rmb 32 stack space
stack equ *
 org $C000
 endif
 
start
init_tests
# Test for coco3
# CoCo 3 will have $38, Jr. will have $00
# Mooh is currently unknown
 lda $ffa0
 anda #%00111111
 cmpa #$38
 beq init_gime
 cmpa #$0
 beq init_jr
# unknown MMU
 ldx #unknown_message
error_loop
 lda ,x+
 beq error_done
 jsr [$a002] ; Color BASIC ROM CHROUT
 bra error_loop
error_done
 rts ; Go Back to BASIC
unknown_message
 fcn "\rUNKNOWN MMU.\r"

init_gime
# don't use stack
 lda #$ff
 sta gime_flag
 lda #$38
 sta text_block
 ldd #$0400
 std text_address
# gime mmu slots are initialized by Color BASIC
# get video mode from coco3 ROM for 32 col screen
 clr gime_video_mode
 bra init_common

init_jr
# set video mode to 0
 clr gime_video_mode
# don't use stack
# flag Jr
 lda #$0
 sta gime_flag
 lda #$38 # lowest banks start at $38
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
# initialize internal variables
 lda #$0
 sta text_block
 ldd #$0400
 std text_address
# # change to all ram mode
#  ldx #$8000
#  bsr turn_off_ints # need to turn off interrupts before swapping in RAM
# ram_loop
#  sta $ffde
#  ldd ,x
#  sta $ffdf
#  std ,x++
#  cmpx #$ff00
#  bne ram_loop

init_common
 bsr turn_off_ints  
 lds #stack # initialize our stack

 ifdef CART
# copy code to RAM if on CART
 ldx #ramrom_cc3
 ldy #first_buffer
code_copy_loop
 lda ,x+
 sta ,y+
 cmpx #ramrom_cc3_end
 bne code_copy_loop
 jsr first_buffer
 bra ramrom_done

ramrom_cc3
 ldx #$8000
ram_cc3_loop
 sta $ffde
 ldd ,x
 sta $ffdf
 std ,x++
 cmpx #$ff00
 bne ram_cc3_loop
 rts
ramrom_cc3_end equ *
ramrom_done equ *
 endif
 
 clr $71 # force cold start on reset
 bsr turn_off_ints
# turn on mmu, task 0, no const ram (for both gime and jr)
 lda #$c4
 sta gime_0
 sta $ff90
 lda #$0
 sta gime_1
 sta $ff91
# init casflg
 lda #$ff
 sta casflg
 
main_menu
 bsr clear_screen
 bsr strout
 fcc "GIME MMU TESTER\r"
 fcc "2MB AWARE\r"
 fcn "CURRENT VIDEO FREQUENCY: "
 lda gime_video_mode
 anda #%00001000
 beq mm_60hz
mm_50hz
 bsr strout
 fcn "5"
 bra mm_continue
mm_60hz
 bsr strout
 fcn "6"
mm_continue
 bsr strout
 fcc "0HZ\r"
 fcc "0) CHANGE VIDEO MODE FREQUENCY\r"
 fcc "1) COUNT AVAILABLE MMU BANKS\r"
 fcc "2) MMU SLOT REGISTER WIDTH\r"
 fcc "3) TEST TASK SWITCHING\r"
 fcc "4) TEST CONSTANT RAM\r"
 fcc "5) TEST RAM\r"
 fcc "6) SHOW VDG WRAP AROUND\r"
 fcn "7) SLOW TIMER TEST\r"
init_loop
 decb
 bne mm_skip
 pshs b
 ldx text_address
 ldd text_position
 leax d,x
 com ,x
 puls b
mm_skip
 bsr keyin
 cmpa #0
 beq init_loop
 pshs a
 bsr chrout
 lda #$0d
 bsr chrout
 ldb ,s
 subb #'0
 cmpb #6
 bhi mm_done
 lslb
 ldx #jump_table
 jsr [b,x]
done_after
 ldb ,s
 subb #'0
 cmpb #6
 bhi mm_done
 lslb
 ldx #post_jump_table
 jsr [b,x]
mm_done
 bsr strout
 fcn "PRESS ANY KEY TO CONTINUE\r"
 bsr wait
 puls b
 jmp main_menu

jump_table
 fdb flip_flop_hz
 fdb count_mmu_blocks
 fdb mmu_register_width
 fdb test_task_switching
 fdb test_constant_ram
 fdb test_ram
 fdb vdg_wrap
 fdb timer_test

post_jump_table
 fdb return
 fdb report_count_mmu
 fdb return
 fdb return
 fdb return
 fdb return
 fdb return
 fdb return

return
 rts

flip_flop_hz
 lda gime_video_mode
 eora #%00001000
 sta gime_video_mode
 sta $ff98
 rts
 
count_mmu_blocks
 bsr switch_to_task_0
 bsr turn_on_mmu
 bsr turn_off_ints
 
 ldx #first_buffer
 stx which_buffer
 ldx #$4000
 stx check_address
 bsr cmb_do
 
 ldx #last_buffer
 stx which_buffer
 ldx #$5FFF
 stx check_address
 bsr cmb_do
 rts
 
# Put mmu block number in first/last byte of each block
cmb_do
 clrb
 ldx which_buffer
cb_loop1
 stb $ffa2
 stb [check_address]
 incb
 bne cb_loop1

# fill buffer with what is
# left in the first byte of each block
 ldx which_buffer
 clrb
cb_loop2
 stb $ffa2
 lda [check_address]
 sta ,x+
 incb
 bne cb_loop2
# report first byte of buffer
 lda first_buffer
 sta out_param
 rts 

report_count_mmu
# compare two buffers, they should be equal
 ldx #first_buffer
 ldy #last_buffer
 clrb
rcm_compare_loop
 lda ,x+
 cmpa ,y+
 bne rcm_compare_fail
 decb
 bne rcm_compare_loop
 bra rcm_compare_pass
rcm_compare_fail
 bsr strout
 fcn "FIRST BYTE BUFFER DOES NOT EQUALLAST BYTE BUFFER.\rBAIL\r"
 rts
rcm_compare_pass
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
 bra rc_printTable
rc_128k
 bsr strout
 fcn "128K - $30 TO $3F\r"
 bra rc_printTable
rc_256k
 bsr strout
 fcn "256K - $20 TO $3F\r"
 bra rc_printTable
rc_512k
 bsr strout
 fcn "512K - $00 TO $3F\r"
 bra rc_printTable
rc_1024k
 bsr strout
 fcn "1024K - $00 TO $7F\r"
 bra rc_printTable
rc_2048k
 bsr strout
 fcn "2048K - $00 TO $FF\r"
rc_printTable
 bsr strout
 fcn "FIRST BYTE OF TABLE: "
 lda first_buffer
 jsr charout_hex
 bsr strout
 fcn "\r"
# look for anomaly in table
 lda out_param
 ldx #first_buffer
rc_loop
 cmpa ,x+
 bne rs_fail
 cmpx #first_buffer+256
 beq rc_done
 inca
 cmpa #0
 bne rc_loop
 lda out_param

 bra rc_loop
rc_done
 rts

rs_fail
 leax -1,x
 pshs a
 ldb ,x
 pshs b
 ldd #first_buffer
 pshs d
 pshs x
 bsr strout
 fcn "ANOMALY IN TABLE POSITION: $"
 puls d
 subd ,s++
 tfr b,a
 jsr charout_hex
 bsr strout
 fcn "\rFOUND: $"
 puls a
 jsr charout_hex
 bsr strout
 fcn "\rEXPECTED: $"
 puls a
 jsr charout_hex
 bsr strout
 fcn "\r"
# print entire buffer
 ldx #first_buffer+(0*64)
 jsr print_8_row 
 jsr wait
 ldx #first_buffer+(1*64)
 jsr print_8_row 
 jsr wait
 ldx #first_buffer+(2*64)
 jsr print_8_row 
 jsr wait
 ldx #first_buffer+(3*64)
 jsr print_8_row 
 jsr wait
 rts

mmu_register_width
 bsr strout
 fcn "CHECK FOR STUCK BITS IN MMU PAGETABLE:\r"
 
#  print raw results
#  bsr strout
#  fcn "$FF: $"
#  lda #$ff
#  sta $ffa7
#  eora $ffa7
#  bsr charout_hex
#  bsr strout
#  fcn "\r$00: $"
#  lda #$0
#  sta $ffa7
#  eora $ffa7
#  bsr charout_hex
#  bsr strout
#  fcn "\r"
 
 lda #$ff
 sta mmu_width_flag
 lda #$ff
 sta $ffa7
 eora $ffa7
 rola
 pshs a
 bcc mrw_check_next1
 bsr strout
 fcn "BIT 7 STUCK LOW\r"
 clr mmu_width_flag
mrw_check_next1
 puls a
 rola
 bcc mrw_check_next2 
 bsr strout
 fcn "BIT 6 STUCK LOW\r"
 clr mmu_width_flag
mrw_check_next2
 clra
 sta $ffa7
 eora $ffa7
 rola
 pshs a
 bcc mrw_check_next3
 bsr strout
 fcn "BIT 7 STUCK HIGH\r"
 clr mmu_width_flag
mrw_check_next3
 puls a
 rola
 bcc mrw_check_next4
 bsr strout
 fcn "BIT 6 STUCK HIGH\r"
 clr mmu_width_flag
mrw_check_next4
 lda mmu_width_flag
 beq mrw_done
 bsr strout
 fcn "NO STUCK BITS\r"
mrw_done
 rts
 


vdg_wrap
 bsr save_task_0
# explain what is going to happen
 bsr strout
 fcc "THE NEXT SCREEN WILL BE A\r"
 fcc "PMODE 4 GRAPHICS SCREEN WITH\r"
 fcc "THE START ADDRESS SET TO $FE00.\r"
 fcc "THE WRAP AROUND MMU PAGE WILL\r"
 fcc "BE IDENTIFIED.\r"
 fcn "PRESS ANY KEY TO CONTINUE\r"
 bsr wait

# Set Sam to PMODE 4
 lda #%11110000
 sta $ffc5
 sta $ffc3
 sta $ffc0
 sta $ff22
# set SAM to highest base address ($FE00)
# for video
 lda #%01111111
 bsr store_a_into_sam_offset

 lda #$3f
 sta $ffa1
 bsr write_string
 fdb $2000
 fcn "Page: 3f, Offset: 0000 "
 bsr write_string
 fdb $3e00
 fcn "Page: 3f, Offset: 1e00 "
 
 lda #$7
 sta $ffa1
 bsr write_string
 fdb $2000
 fcn "Page: 07, Offset: 0000 "
 bsr write_string
 fdb $3e00
 fcn "Page: 07, Offset: 1e00 "

 lda #$38
 sta $ffa1
 bsr write_string
 fdb $2000
 fcn "Page: 38, Offset: 0000 "

 lda #$40
 sta $ffa1
 bsr write_string
 fdb $2000
 fcn "Page: 40, Offset: 0000 "

 lda #$00
 sta $ffa1
 bsr write_string
 fdb $2000
 fcn "Page: 00, Offset: 0000 "
 
 lda #$8
 sta $ffa1
 bsr write_string
 fdb $2000
 fcn "Page: 08, Offset: 0000 "

 bsr wait

 bsr restore_task_0
# Set Sam to text mode
 lda #$00
 sta $ffc0
 sta $ffc2
 sta $ffc4
 sta $ff22
# set SAM to text screen base address ($0400)
# for video
 lda #%00000010
 bsr store_a_into_sam_offset
 rts

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

timer_test
# save palette
 lda $ffbd
 anda #%00111111
 sta save_palette
 
# turn off all pia interrupts
 lda $ff01
 sta save_pia0a
 anda #%00111110
 sta $ff01
 lda $ff00
 
 lda $ff03
 sta save_pia0b
 anda #%00111110
 sta $ff03
 lda $ff02
 
# install both isr
 lda #$7e # JMP instruction extended
 sta $fef4
 sta $fef7
 ldd #tt_isr_firq
 std $fef5
 ldd #tt_isr_irq
 std $fef8

# setup timer
 lda #0 # lsb of timer
 sta $ff95
 lda #0 # msb of timer
 sta $ff94
 lda #%00100000 # firq for timer
 sta $ff93
 lda #%00001000 # irq for vertical border
 sta $ff92
 lda $ff92
 lda $ff93

# set timer source
 lda gime_1
 ora #%00000000 # slow - 15khz
 sta gime_1
 sta $ff91
 
# turn on gime interrupts
 lda gime_0
 ora #%00110000
 sta gime_0
 sta $ff90

 bsr clear_screen
 ldd #$e6e6
 ldx #$400+31
checker_loop
 std ,x
 leax 32,x
 cmpx #$400+31+(32*16)
 bne checker_loop
 
 ldx #hex

 bsr turn_on_ints

tt_loop
 ldy #$400
 ldd timer_value
 anda #$0f
 lda a,x
 sta ,y+
 tfr b,a
 lsra
 lsra
 lsra
 lsra
 lda a,x
 sta ,y+
 tfr b,a
 anda #$0f
 lda a,x
 sta ,y++
 
 bsr keyin
 cmpa #'S
 beq tt_inc10
 cmpa #'A
 beq tt_dec10
 cmpa #'X
 beq tt_inc1
 cmpa #'Z
 beq tt_dec1
 cmpa #'Q
 beq tt_cleanup
 bra tt_loop
tt_inc10
 ldd timer_value
 addd #10
 std timer_value
 bra tt_loop
tt_dec10
 ldd timer_value
 subd #10
 std timer_value
 bra tt_loop
tt_inc1
 ldd timer_value
 addd #1
 std timer_value
 bra tt_loop
tt_dec1
 ldd timer_value
 subd #1
 std timer_value
 bra tt_loop
hex fcb 48,49,50,51,52,53,54,55,56,57,1,2,3,4,5,6
tt_cleanup
 bsr turn_off_ints
# turn off gime interrupts
 lda gime_0
 anda #%11001111
 sta gime_0
 sta $ff90
# turn off interrupt flags
 clra
 sta $ff93
 sta $ff92
# restore PIA
 lda save_pia0a
 sta $ff01
 lda save_pia0b
 sta $ff03
# restore palette
 lda save_palette
 sta $ffbd
 rts
 
tt_isr_firq
 pshs a
 lda #0 
 sta $ffbd
 sta $ff95 # zero timer count down
 sta $ff94
 lda $ff93
 puls a
#  inc $401
 rti

timer_value fdb $0080
tt_isr_irq
 lda #$ff
 sta $ffbd
 ldd timer_value # reset timer count down
 stb $ff95
 sta $ff94
#  inc $402
 lda $ff92 # clear the irq interrupt
 lda $ff93 # Also clear the firq interrupt
 rti

test_task_switching
# Copy current code, heap, and stack to task 1

 bsr strout

 ifdef CART
 fcn "COPY CURRENT SLOT 3 AND 6 TO\rTASK 1\r"
 lda $ffa3
 sta $ffab
 lda $ffa6
 sta $ffae
 else
 fcn "COPY CURRENT SLOT 3 TO TASK 1\r"
 lda $ffa3
 sta $ffab
 endif
 
# Switch to task 1
 bsr switch_to_task_1

# set task 0 slot 4,5 to 3e and 3f
# set task 1 slot 4,5 to 3f and 3e
 bsr strout
 fcc "SET TASK 0 SLOT 4,5 TO 30 AND 3F"
 fcn "SET TASK 1 SLOT 4,5 TO 3F AND 30"
 lda #$30
 sta $ffa4
 sta $ffad
 lda #$3f
 sta $ffa5
 sta $ffac
 
# write to $8000-$9fff
 bsr strout
 fcn "WRITE TO $8000-$9FFF\r"
 lda #19 # random seed
 sta randomseed
 ldx #$8000
tts_loop1
 bsr randomeor
 sta ,x+
 cmpx #$a000
 bne tts_loop1
 
# switch to task 0
 bsr switch_to_task_0
 
# test $a000-$bfff, expect pass
 bsr strout
 fcn "TEST $A000-$BFFF\r"
 lda #19 # random seed
 sta randomseed
 ldx #$a000
tts_loop2
 bsr randomeor
 cmpa ,x+
 bne tts_fail
 cmpx #$c000
 bne tts_loop2

# write to $8000-$9fff
 bsr strout
 fcn "WRITE TO $8000-$9FFF\r"
 lda #154 # different random seed
 sta randomseed
 ldx #$8000
tts_loop3
 bsr randomeor
 sta ,x+
 cmpx #$a000
 bne tts_loop3

# switch to task 1
 bsr switch_to_task_1

# test $8000-$9fff expect fail
 bsr strout
 fcn "TEST $8000-$9FFF\r"
 lda #$ff
 sta tts_pass_flag
 lda #154 # different random seed
 sta randomseed
 ldx #$8000
tts_loop4
 bsr randomeor
 cmpa ,x+
 beq tts_skip
 clr tts_pass_flag
tts_skip
 cmpx #$a000
 bne tts_loop4
 lda tts_pass_flag
 beq tts_pass
 bra tts_fail

# pass
tts_pass
 bsr strout
 fcn "PASS\r"
 bra tts_done

tts_fail
 bsr strout
 fcn "FAIL\r"
 
# switch to task 0
tts_done
 bsr switch_to_task_0
 rts

test_constant_ram
# switch to task 0
 jsr switch_to_task_0

# copy code to task 1
 lda $ffa2
 sta $ffaa
 lda $ffa3
 sta $ffab
 
 bsr strout
 fcn "SETUP BANKS (TASK 0)\r"
 lda #$3f
 sta $ffa4
 lda #$30
 sta $ffa7
 
 jsr do_const_ram_test
 beq tcr_do_task_1
tcr_fail
# switch to task 0
 jsr switch_to_task_0
# bail
 bsr strout
 fcn "FAIL\r"
 rts

tcr_do_task_1
 bsr strout
 fcn "PASS\r"
# switch to task 1
 jsr switch_to_task_1

 bsr strout
 fcn "SETUP BANKS (TASK 1)\r"
 lda #$3f
 sta $ffac
 lda #$3e
 sta $ffaf

# clear out test buffers
 lda #0
 ldx #$fe00
 jsr write_seed_256
 lda #0
 ldx #$9e00
 jsr write_seed_256

 jsr do_const_ram_test
 bne tcr_fail
 bsr switch_to_task_0 
 bsr strout
 fcn "PASS\r"
 rts
 
do_const_ram_test 
 bsr strout
 fcn "TURN ON CONST RAM\r"
 lda gime_0
 ora #%00001000
 sta gime_0
 sta $ff90
 
 bsr strout
 fcn "WRITE SEED #87 TO $FE00-$FEFF\r"
 lda #87
 ldx #$fe00
 jsr write_seed_256
 
 bsr strout
 fcn "TEST SEED #87 ON $9E00-$9EFF\r"
 lda #87
 ldx #$9e00
 jsr test_seed_256
 bne do_tcr_fail
 
 bsr strout
 fcn "TURN OFF CONST RAM\r"
 lda gime_0
 anda #%11110111
 sta gime_0
 sta $ff90

 bsr strout
 fcn "WRITE SEED #92 TO $FE00-$FEFF\r"
 lda #92
 ldx #$fe00
 jsr write_seed_256

 bsr strout
 fcn "TEST SEED #87 ON $9E00-$9EFF\r"
 lda #87
 ldx #$9e00
 jsr test_seed_256
 bne do_tcr_fail

 orcc #%00000100 # set z, pass
 rts
 
do_tcr_fail
 andcc #%11111011 # clear z, fail
 rts

# subroutine
write_seed_256
 sta randomseed
 tfr x,d
 addd #$100
 pshs d
ws256_loop
 jsr randomeor
 sta ,x+
 cmpx ,s
 bne ws256_loop
 puls x,pc
 
# subroutine
test_seed_256
 sta randomseed
 tfr x,d
 addd #$100
 pshs d
ts256_loop
 jsr randomeor
 cmpa ,x+
 bne ts256_fail
 cmpx ,s
 bne ts256_loop
ts256_pass
 orcc #%00000100 # set z
 puls x,pc
ts256_fail
 andcc #%11111011 # clear z
 puls x,pc

# subroutine
switch_to_task_1
 bsr strout
 fcn "SWITCH TO TASK 1\r"
 lda gime_1
 ora #%00000001
 bra stt1_entry

# subroutine
switch_to_task_0
 bsr strout
 fcn "SWITCH TO TASK 0\r"
 lda gime_1
 anda #%11111110
stt1_entry
 sta gime_1
 sta $ff91
 rts
 
#subroutine
turn_off_mmu
 lda gime_0
 anda #%10111111
 bra tom_entry
#subroutine
turn_on_mmu
 lda gime_0
 ora #%01000000
tom_entry
 sta gime_0
 sta $ff90
 rts

#
# subroutine
#
print_8_bytes
 pshs x
 lda ,s
 bsr charout_hex
 lda 1,s
 bsr charout_hex
 bsr strout
 fcn ":"
 puls x
 ldb #8
p8b_loop
 pshs b,x
 bsr strout
 fcn " "
 puls b,x
 lda ,x+
 pshs d,x
 bsr charout_hex
 puls d,x
 decb
 bne p8b_loop
 bsr strout
 fcn "\r"
 rts
 
#
# subroutine
#
print_8_row
 ldb #8
p8w_loop
 pshs b,x
 bsr print_8_bytes
 puls b,x
 leax 8,x
 decb
 bne p8w_loop
 rts

# ---------------------------------------------------------------
# RandomEor sub
# Pick random number from 0 to 255
# Entry: randomseed
# Exit: A = number produced
# Uses a,b
# ---------------------------------------------------------------
randomeor:
 ldb randomseed # get last random number
 beq doeor # handle input of zero
 aslb # shift it left, clear bit zero
 beq rndready # if the input was $80, skip the eor
 bcc rndready # if the carry is now clear skip the eor
doeor:
 eorb #$1d # eor with magic number %00011101
rndready:
 stb randomseed # save the output as the new seed
 tfr b,a
 rts          

test_ram
 bsr count_mmu_blocks
 lda out_param
 cmpa #$f0
 beq tr_128k
 cmpa #$e0
 beq tr_256k
 cmpa #$c0
 beq tr_512k
 cmpa #$80
 beq tr_1024k
 cmpa #$00
 beq tr_2048k
# unknown amount of RAM
 bsr strout
 fcn "UNKNOWN AMOUNT OF RAM.\rFAIL\r"
 rts
# start bank, end back+1
tr_128k
 ldd #$3040
 pshs d
 bra tr_start
tr_256k
 ldd #$2040
 pshs d
 bra tr_start
tr_512k
 ldd #$0040
 pshs d
 bra tr_start
tr_1024k
 ldd #$0080
 pshs d
 bra tr_start
tr_2048k
 ldd #$0000
 pshs d
 bra tr_start
 
tr_start 
tr_main_loop
 jsr keyin
 cmpa #0
 bne tr_abort
 lda ,s
 sta $ffa4
 cmpa #$38 # skip screen location
 beq tr_next
 cmpa #$3b # heap/stack/code location
 beq tr_next
 ifdef CART
 cmpa #$3e # skip cartridge code page
 endif
 
 beq tr_next
# Write page number
 jsr charout_hex
 bsr strout
 fcn ": MMU PAGE UNDER TEST\r"
 bsr mu_start
 bne tr_fail
tr_next 
 inc ,s
 lda ,s
 cmpa 1,s
 bne tr_main_loop
 bra tr_pass
tr_abort
 bsr strout
 fcn "ABORT\r"
tr_pass
 puls x
 bsr strout
 fcn "PASS\r"
 rts
tr_fail
 puls x
 pshs a,y
 bsr strout
 fcn "FAIL BITS: $"
 puls a
 bsr charout_hex

 bsr strout
 fcn "\rFAIL ADDRESS: $"
 puls a
 bsr charout_hex
 puls a
 bsr charout_hex
 bsr strout
 fcn "\r"
 rts
 
 include "marchu_6809.asm"

#
# subroutine
# Store reg a into sam video offset register
#
store_a_into_sam_offset
 ldb #7
 ldx #$ffc6
loop_store_a
 rora
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
 rts

#
# subroutine
# turn on all interrupts
#
turn_on_ints
 andcc #$af
 rts
 
#
# subroutine
# restore mmu regs at ffa0
#
restore_task_0
 ldy #saved_task
 ldx #$ffa0
 bra copy_task
 
#
# subroutine
# save mmu regs at ffa0
#
save_task_0
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

#
# subroutine
# clear the text screen
#
clear_screen
 ldx #$0400
 ldd #$6060
cs_loop
 std ,x++
 cmpx #$600
 bne cs_loop
 clr text_position
 clr text_position+1
 rts
 
#
# subroutine
# Output string to screen
#
strout
 puls u
so_loop
 lda ,u+
 beq so_done
 jsr chrout
 bra so_loop
so_done
 tfr u,pc

charout_hex
 pshs a,y,x
 ldy #hex_ascii
 lsra
 lsra
 lsra
 lsra
 lda a,y
 jsr chrout
 lda ,s
 anda #$0f
 lda a,y
 jsr chrout
 puls a,y,x
 rts

hex_ascii fcc "0123456789ABCDEF"

#
# subroutine
# output to text screen
#
chrout
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

#
# subroutine
#
wait
 jsr keyin
 cmpa #0
 beq wait
 rts
 
# subroutine
# this routine gets a keystroke from the keyboard if a key
# is down. it returns zero true if there was no key down.
# Copied from Color BASIC

pia0 equ $ff00

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
 ldx #$45e get keyboard debounce
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

 ifdef CART
 
 IFGT *-$dfff
 ERROR "Cartridge program to large"
 ENDC
 
 else

 rmb 32 stack space
 
 IFGT *-$7ffe
 ERROR "DECB program to large"
 ENDC
 
 org $8000-1
stack equ *

 endif


 end start
 
 
 
 


