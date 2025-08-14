#!/bin/sh -x

lwasm gmmut.asm --decb -ogmmut.bin --list=gmmut.lst
decb dskini GMMUT.DSK
decb copy -t gmmut.bas GMMUT.DSK,GMMUT.BAS
decb copy -2b gmmut.bin GMMUT.DSK,GMMUT.BIN
