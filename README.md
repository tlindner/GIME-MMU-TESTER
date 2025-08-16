# GIME-MMU-Tester

## Progress

Options 1-2, 4-5: not implemented

Option 3:
* Write block number to first byte of each block, 0 to 255
* Copy first byte of each block to buffer
* First byte of buffer will indicate how many block are avaiable
* f0:  128k - $30 to $3f"
* e0:  256k - $20 to $3f"
* c0:  512k - $00 to $3f"
* 80: 1024k - $00 to $7f"
* 00: 2048k - $00 to $ff"


Option 6:
* Setup PMODE 4 screen.
* Change base addres to $FE00
* Write 0 to page 38, byte 0
* Write FF to address fe00 in page 3f
* Write FF to page 40, byte 0
* in a loop:
* complement the three above bytes
* You will see two blinking lines
	
* If blinking is in sync, the VDG does not wrap around during display
* If blinking is alternating, then VDG does wrap around during display
