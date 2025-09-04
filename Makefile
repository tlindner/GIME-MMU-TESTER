
DEPENDS		= ./Makefile

AS			= lwasm -r --pragma=condundefzero
ASOUT		= -o
ECHO		= echo

BINS		= gmmut.bin
DSKS		= gmmut.dsk
ROMS		= gmmut.ccc
LSTS		= gmmut.lst gmmut.ccc.lsgt

all:	banner bin dsk $(DEPENDS)

banner:
	@$(ECHO) "**************************"
	@$(ECHO) "*                        *"
	@$(ECHO) "*    GIME-MMU_TESTER     *"
	@$(ECHO) "*                        *"
	@$(ECHO) "**************************"

dsk:	bin
	-rm -f gmmut.dsk
	decb dskini gmmut.dsk
	decb copy -r gmmut.bas gmmut.dsk,GMMUT.BAS -0 -t
	decb copy -r -2 gmmut.bin gmmut.dsk,GMMUT.BIN

bin:	gmmut.asm marchu_6809.asm
	$(AS) $(ASOUT)gmmut.bin gmmut.asm $(AFLAGS) --list=gmmut.lst --decb
	$(AS) --define=CART $(ASOUT)gmmut.ccc gmmut.asm $(AFLAGS) --list=gmmut.ccc.lst --raw

clean:
	-rm $(BINS) $(DSKS) $(ROMS) $(LSTS)

