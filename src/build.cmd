del hello.nes
del init.o
del ppu.o
del controllers.o
del game.o
del hello.o
del hello.nes.dbg
del hello.map.txt
del hello.labels.txt

ca65 init.s -g -o init.o
ca65 ppu.s -g -o ppu.o
ca65 controllers.s -g -o controllers.o
ca65 game.s -g -o game.o
ca65 hello.s -g -o hello.o
ld65 -o hello.nes -C nrom-256.cfg init.o ppu.o controllers.o game.o hello.o -m hello.map.txt -Ln hello.labels.txt --dbgfile hello.nes.dbg

del init.o
del ppu.o
del controllers.o
del game.o
del hello.o