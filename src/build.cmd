del hello.nes
del hello.o
del hello.nes.dbg
del hello.map.txt
del hello.labels.txt

ca65 hello.s -g -o hello.o
ld65 -o hello.nes -C nrom-256.cfg hello.o -m hello.map.txt -Ln hello.labels.txt --dbgfile hello.nes.dbg