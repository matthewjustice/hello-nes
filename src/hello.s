;
; hello.s
;
; Author: Matthew Justice
; Description: A simple Hello World style program for the NES
;


; iNES header constants
INES_MAPPER_NROM        = 0  
INES_MIRROR_VERTICAL    = 1
INES_SRAM_FALSE         = 0

; constants for PPU registers mapped into memory
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS =	$2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014

; constants to APU registers mapped into memory
APUDMC_IRQ  = $4010
APUSTATUS   = $4015
APUFRAME    = $4017

; The HEADER segment contains the 16-byte iNES signature.
.segment "HEADER"
.byte "NES", $1A        ; magic
.byte 2                 ; PRG ROM size, count of 16K chunks
.byte 1                 ; CHR ROM size, count of  8k chunks
.byte INES_MIRROR_VERTICAL | (INES_SRAM_FALSE << 1) | ((INES_MAPPER_NROM & $F) << 4)
.byte (INES_MAPPER_NROM & $F0)
.byte $0, $0, $0, $0, $0, $0, $0, $0

; The VECTORS segment defines the handlers for 3 interrupts
.segment "VECTORS"
.addr nmi_handler
.addr reset_handler
.addr irq_handler

; The CODE segment contains, well, code.
.segment "CODE"

; reset_handler
; Handles the interrupt that occurs when the system is reset
.proc reset_handler
    sei             ; Disable interrupts
    ldx #$00    
    stx PPUCTRL     ; Disable PPU NMI
    stx PPUMASK     ; Hide backgrounds and sprites
    bit APUSTATUS   ; Clear the APU frame interrupt flag
    stx APUSTATUS   ; Disable all APU channels
    stx APUDMC_IRQ  ; Disable APU DMC IRQ
    dex             ; x = $FF
    txs             ; set stack pointer to $01FF
    bit PPUSTATUS   ; Acknowledge PPU VBLANK if already set
    lda #$40
    sta APUFRAME    ; Disable APU Frame IRQ
    cld             ; Disable decimal mode (unsupported on NES)

    ; Wait on the PPU to "warm up". We'll know the PPU is ready
    ; once two VBLANKs have occurred. Normally we are notified
    ; of VBLANK by the PPU's NMI, but the NMI method isn't reliable
    ; at this stage. Instead, spin on bit 7 of PPUSTATUS.
    ; Wait on the first VBLANK
vblank_wait_1:
    bit PPUSTATUS       ; set flag N = bit 7 of PPUSTATUS (1 = in VBLANK)
    bpl vblank_wait_1   ; loop while flag N=0 (while not in VBLANK)

    ; We have some time now before the second VBLANK.

    ; Wait on the second VBLANK
vblank_wait_2:
    bit PPUSTATUS       ; set flag N = bit 7 of PPUSTATUS (1 = in VBLANK)
    bpl vblank_wait_2   ; loop while flag N=0 (while not in VBLANK)

    ; PPU is now warmed up.

    rti
.endproc

; nmi_handler
; Handles the NMI that occurs as a result of VBLANK from the PPU
.proc nmi_handler
    rti
.endproc

; irq_handler
; Handles the interrupt for the BRK command
.proc irq_handler
    rti
.endproc

