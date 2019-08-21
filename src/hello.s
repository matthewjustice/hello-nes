;
; hello.s
;
; Author: Matthew Justice
; Description: A simple Hello World style program for the NES
;

; The HEADER segment contains the 16-byte iNES signature.
.segment "HEADER"
INES_MAPPER_NROM        = 0  
INES_MIRROR_VERTICAL    = 1
INES_SRAM_FALSE         = 0
.byte "NES", $1A        ; magic
.byte 2                 ; PRG ROM size, count of 16K chunks
.byte 1                 ; CHR ROM size, count of  8k chunks
.byte INES_MIRROR_VERTICAL | (INES_SRAM_FALSE << 1) | ((INES_MAPPER_NROM & $F) << 4)
.byte (INES_MAPPER_NROM & $F0)
.byte $0, $0, $0, $0, $0, $0, $0, $0