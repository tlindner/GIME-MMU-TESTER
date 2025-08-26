# GIME-MMU-Tester

## Progress

Options ?: not implemented

Option 1:
1. Write block number to first byte of each block, 0 to 255, in order
2. Copy first byte of each block to buffer
3. First byte of buffer will indicate how many block are avaiable
 - f0:  128k - $30 to $3f"
 - e0:  256k - $20 to $3f"
 - c0:  512k - $00 to $3f"
 - 80: 1024k - $00 to $7f"
 - 00: 2048k - $00 to $ff"


Option 5:
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

Option 6:
1. Turn off PIA interrupts
2. Set GIME FIRQ to timer
3. Set GIME IRQ to Vertical blanking
4. Set time source to 0 (15,476 ticks per second)
5. Set timer value to $080
6. On vertical blank interrupt set palette display to white
7. On timer interrupt set palette display to black.
8. 'A' and 'S' keys can adjust time value by 10
9. 'Z' and 'X' keys can adjust timer value by 1
10. 'Q' to exit
