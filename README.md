# GIME-MMU-Tester

## Progress

Options 1-2, 4-5: not implemented

Option 3:
* Write block number to first byte of each block, 0 to 255, in order
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
* Write text on the following graphics pages:
** Page 3f, offset 0
** Page 3f, offset 1e00
** Page 7, offset 0
** Page 7, offset 1e00
** Page 7, offset 0
** Page 40, offset 0
** Page 8, offset 0
* You will see two pages listed, the FE00 pages and the wrap around page.
* A GIME in a CoCo 3 will wrap from page 3f to 0.
* Currently, Mame will wrap from 3f, to 40.


