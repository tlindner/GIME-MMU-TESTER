# GIME-MMU-Tester

## Progress

Options 1-5: not implemented

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