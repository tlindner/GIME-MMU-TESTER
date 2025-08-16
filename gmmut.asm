 PRAGMA autobranchlength
 org $6000
input rmb 1
output rmb 1
start
 lda input
 cmpa #3
 beq count_mmu_blocks
 cmpa #6
 beq vdg_wrap
# nothing to do exit.
 rts

count_mmu_blocks
 bsr turn_off_ints
 bsr save_task_0
# Put mmu block number
# in first byte of each block
 clrb
 ldx #buffer2
count_bocks_loop
 stb $ffa0
 lda >$0
 sta ,x+
 stb >$0
 incb
 bne count_bocks_loop
# fill buffer with what is
# left in the first byte of each block
 clrb
 ldx #buffer
count_loop
 stb $ffa0
 lda >$0
 sta ,x+
 incb
 bne count_loop
# report first byte of buffer
 lda buffer
 sta output
# fix up overwritten bytes
 clrb
 ldx #buffer2
restore_loop
 stb $ffa0
 lda ,x+
 sta >$0
 incb
 bne restore_loop
 bsr restore_task_0
 bsr turn_on_ints
 rts 

vdg_wrap
 bsr turn_off_ints
 bsr save_task_0
# set SAM to highest base address ($FE00)
# for video
 sta $ffc7
 sta $ffc9
 sta $ffcb
 sta $ffcd
 sta $ffcf
 sta $ffd1
 sta $ffd3
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
# turn off all interrupts
#
turn_off_ints
# turn off pia0 ints
 clra
 sta $ff01
 sta $ff03
# turn off pia1 ints
 clra
 sta $ff21
 sta $ff23
# turn off gime ints
 lda #$cc
 anda #%11001111
 sta $ff90
 rts

#
# subroutine
# turn on all interrupts
#
turn_on_ints
# turn on pia0 ints
 lda #$34
 sta $ff01
 lda #$b5
 sta $ff03
# turn on pia1 ints
 lda #$34
 sta $ff21
 lda #$37
 sta $ff23
# reset gime
 lda #$cc
 sta $ff90
 rts
 
save_task_0
#
# subroutine
# save mmu regs at ffa0
#
 ldy #$ffa0
 ldx #saved_task
 ldd ,y++
 std ,x++
 ldd ,y++
 std ,x++
 ldd ,y++
 std ,x++
 ldd ,y++
 std ,x++
 rts

restore_task_0
#
# subroutine
# restore mmu regs at ffa0
#
 ldy #saved_task
 ldx #$ffa0
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
max_program equ *
 IFGT max_program-$7fff
 ERROR "Program to large"
 ENDC

 end start
 
 
 
 


