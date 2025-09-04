# GIME-MMU-Tester

This is a program to test the Color Computer 3's GIME chip.
Everything non-graphical is fair game. It has code to test for the
presence of a CoCo Mem Jr., and will accommodate it as necessary.

This project produces a DECB binary file useable with LOADM.
It also produces a raw binary suitable for a Program Pak ROM.

## Progress

Option 1, Count avaiable mmu banks:
1. Write block number to first byte of each block, 0 to 255, in order
2. Copy first byte of each block to buffer
3. Do again for last byte of each block.
4. Each buffer should match exactly. Bail if not.
5. First byte of buffer will indicate how many blocks are avaiable
 - f0:  128k - $30 to $3f
 - e0:  256k - $20 to $3f
 - c0:  512k - $00 to $3f
 - 80: 1024k - $00 to $7f
 - 00: 2048k - $00 to $ff
6. Check for table anomaly:
 - The 256 entry result table should contain number incrementing by 1 from start to finish
 - If there is less than 2mb of RAM, the table should repeat.
 - If this pattern is not seen, the first wrong table entry is reported.
 
Option 2, MMU slot register width:

 0 ^ 1 == 1
 1 ^ 1 == 0
 
 0 ^ 0 == 0
 1 ^ 0 == 1
 
1. Store and exor $ff in $ffa7
2. report stuck low bits
3. Store and exor $00 in $ffa7
4. Report stuck high bits

Option 3, Test task switching:
1. Copy current slot 2 and 3 to task 1
2. Switch to task 1
3. set task 0 slot 4,5 to 30,3f
4. set task 1 slot 4,5 to 3f,30
5. write seed #19 to $8000-$9fff,
6. switch to task 0
7. test $a000-$bfff, expect pass
8. write seed #154 to $8000-$9fff
9. switch to task 1
10. test $8000-$9fff expect fail

Option 4, Test constant ram:
1. Set bank $ffa4 to $3f (task 0, slot 5, $8000-$9fff)
2. Set bank $ffa7 to $30 (task 0, slot 7, $e000-$ffff)
3. Turn on const ram
4. Write seed #87 to $fe00-$feff
5. Test seed #87 on $9e00-$9eff, pass if match
6. Turn off const ram
7. Write seed #92 to $fe00-$feff
8. Test seed #87 on $9e00-$9eff, pass if match

Option 5:
1. MarchU memory test
 - Currently uses two patterns: $A5, $5A
 - Only test pages with no heap, stack or code
 - Skip otherwise
 - Does not test page overlap

Option 6, Show VDG wrap around:
1. Setup PMODE 4 screen.
2. Change base addres to $FE00
3. Write text on the following graphics pages:
 - Page 3f, offset 0
 - Page 3f, offset 1e00
 - Page 7, offset 0
 - Page 7, offset 1e00
 - Page 7, offset 0
 - Page 40, offset 0
 - Page 8, offset 0
5. You will see two pages listed, the FE00 page at the top and the wrap around page next.
6. A GIME in a CoCo 3 will wrap from page 3f to 0.
7. Currently, Mame will wrap from 3f, to 40.

Option 7, slow Timer Test:
1. Turn off PIA interrupts
2. Set GIME FIRQ to timer
3. Set GIME IRQ to Vertical blanking
4. Set time source to 0 (15,476 ticks per second)
5. initialize timer value to 0
6. On IRQ (vertical black) set palette to white, set timer value to start timer
7. On FIRQ (timer) set palette to black, halt timer
8. 'A' and 'S' keys can adjust timer value by +10/-10
9. 'Z' and 'X' keys can adjust timer value by +1/-1
10. 'Q' to exit
