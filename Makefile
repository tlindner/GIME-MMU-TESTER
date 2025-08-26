
DEPENDS		= ./Makefile

AS			= lwasm -r --pragma=condundefzero
ASOUT		= -o
ECHO		= echo

BINS		= gmmut.bin
DSKS		= gmmut.dsk

all:	banner bin dsk $(DEPENDS)

banner:
	@$(ECHO) "**************************"
	@$(ECHO) "*                        *"
	@$(ECHO) "*    GIME-MMU_TESTER     *"
	@$(ECHO) "*                        *"
	@$(ECHO) "**************************"

dsk:	bin
	-rm gmmut.dsk
	decb dskini gmmut.dsk
	decb copy -r gmmut.bas gmmut.dsk,GMMUT.BAS -0 -t
	decb copy -r -2 gmmut.bin gmmut.dsk,GMMUT.BIN

bin:	gmmut.asm
	$(AS) $(ASOUT)gmmut.bin gmmut.asm $(AFLAGS) --list=gmmut.lst --decb

clean:
	-rm $(BINS) $(DSKS)

