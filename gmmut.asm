 PRAGMA autobranchlength
 org $6000
input rmb 1
start
 lda input
 cmpa #6
 beq vdg_wrap
 
vdg_wrap
 clr $71
 bsr turn_off_ints
 bsr save_task_0
# set VDG to highest base address
 sta $ffc7
 sta $ffc9
 sta $ffcb
 sta $ffcd
 sta $ffcf
 sta $ffd1
 sta $ffd3
 ldx #vdg_wait
 ldb #vdg_end-vdg_wait
 bsr move_to_constant_ram_and_execute
# no return
 
vdg_wait
# set mmu task 0 to all zeros
 lda #$3f-8
 sta $ffa0
 lda #$3f+1
 sta $ffa1
 clr $0000
 lda #$ff
 sta $2000
 sta $fe00
 ldx #$0
vdg_loop
 leax 1,x
 bne vdg_loop
 com $0000
 com $2000
 com $fe00
 bra vdg_loop
# reset 
 ldx $fffe
 
# put roms in MMU 
 lda #$3c
 sta $ffa4
 lda #$3d
 sta $ffa5
 lda #$3e
 sta $ffa6
 lda #$3f
 sta $ffa7

# set rom mode 
 sta $ffd4
 sta $ffde
# cold/warm restart 
 tfr x,pc
vdg_end

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
# turn on gime ints
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

move_to_constant_ram_and_execute
 ldu #code
move_loop
 lda ,x+
 sta ,u+
 decb
 beq move_done
 bra move_loop
move_done
 jmp code
# no return

 org $fe00
saved_task rmb 8
code equ *

 end start
 
 
 
 


