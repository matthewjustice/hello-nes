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

; constants used by PPUCTRL
PPU_ENABLE_VBLANK    = $80
PPU_BG_TABLE_AT_0000 = $00
PPU_BG_TABLE_AT_1000 = $10
PPU_SP_TABLE_AT_0000 = $00
PPU_SP_TABLE_AT_1000 = $08

; constants used by PPUMASK
PPU_SHOW_SPRITES     = $14 ; 10 (show) & 04 (show in leftmost)
PPU_SHOW_BACKGROUND  = $0A ; 08 (show) & 02 (show in leftmost)

; constants used in OAM attributes
OAM_ATTR_PALETTE_4   = $00
OAM_ATTR_PALETTE_5   = $01
OAM_ATTR_PALETTE_6   = $02
OAM_ATTR_PALETTE_7   = $03
OAM_ATTR_BEHIND_BGND = $20
OAM_ATTR_FLIP_HORIZ  = $40
OAM_ATTR_FLIP_VERT   = $80

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

; The ZEROPAGE segment defines the first page (256 bytes)
; of RAM. Instructions that access it are faster. Store
; global variables here.
.segment "ZEROPAGE"
nmi_count: .res 1  ; increments on VBLANK NMI

; The OAM (Object Attribute Memory) segment contains data
; to be copied to OAM memory in the PPU during VBLANK
; It contains a list of up to 64 sprites, each 4 bytes in size.
.segment "OAM"
oam: .res 256

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
    ; During our extra cycles, first zero out the zero page
    ldx #$00
    lda #$00
clear_zp_loop:
    sta $0000, x        ; set value at [0000+x] = 0
    inx
    bne clear_zp_loop

    ; Next move all sprites below the visible area
    ldx #$00
    lda #$FF    ; Y offset 255 if off screen
offscreen_sprites_loop:
    sta oam, x  ; set sprite Y pos = 255
    inx         ; x = x + 4 to move to the next sprite
    inx         ; The first bye of each sprite represents
    inx         ; its y position.
    inx
    bne offscreen_sprites_loop ; do this for all 64 sprites

    ; Wait on the second VBLANK
vblank_wait_2:
    bit PPUSTATUS       ; set flag N = bit 7 of PPUSTATUS (1 = in VBLANK)
    bpl vblank_wait_2   ; loop while flag N=0 (while not in VBLANK)

    ; PPU is now warmed up.
    jmp main
.endproc

; nmi_handler
; Handles the NMI that occurs as a result of VBLANK from the PPU
.proc nmi_handler
    inc nmi_count
    rti
.endproc

; irq_handler
; Handles the interrupt for the BRK command
.proc irq_handler
    rti
.endproc

; main
; The main game logic
.proc main
    ; We just read PPUSTATUS and should be in VBLANK
    ; Load the palette
    jsr load_palette

    ; Show the background
    jsr show_background

    ; Turn on screen
    jsr turn_on_screen
forever:
    ; game logic here
    ; prepare OAM data
    jsr prepare_oam

    ; wait on a VBLANK NMI
    lda nmi_count
main_vblank_wait:
    cmp nmi_count
    beq main_vblank_wait

    ; Copy OAM data to the PPU
    lda #0
    sta OAMADDR
    lda #>oam
    sta OAMDMA

    jmp forever
.endproc

; load_palette
; Load palette data to PPU palette memory
.proc load_palette
    ; first set the VRAM address, upper byte first ($3F00)
    ldx #$3F
    stx PPUADDR
    ldx #$00
    stx PPUADDR
load_palette_loop:
    lda palette_data, x
    sta PPUDATA
    inx
    cpx #32 ; If x >= 32, set carry flag
    bcc load_palette_loop ; Only copy 32 byte
    rts
.endproc

.proc show_background
    ; first set the VRAM address, to a location in the nametable ($2020)
    ; upper byte first
    ; #21C0 is the 15th row down (about the middle of the screen vertically)
    ; Then slide it right 11 tiles (0xB) to put the tiles in roughly the 
    ; center of the screen giving us $21CB
    ldx #$21
    stx PPUADDR
    ldx #$CB
    stx PPUADDR

    ; Our background consists of only 11 tiles, numbered 1 - 11.
    ; Place them on the screen starting at the location indicated
    ; above. We want them displayed in order.
    ldx #$01
show_background_loop:
    stx PPUDATA
    inx
    cpx #11 ; if x >= 11, set carry flag
    bcc show_background_loop
    rts
.endproc

.proc turn_on_screen
    ; set initial scroll coordinates
    ldx #0
    stx PPUSCROLL
    stx PPUSCROLL

    ; Enable VBLANK NMI
    ; set the background table address to $0000
    ; set the sprint table address to $1000 
    ldx #PPU_ENABLE_VBLANK|PPU_BG_TABLE_AT_0000|PPU_SP_TABLE_AT_1000
    stx PPUCTRL

    ; Show sprites and background
    ldx #PPU_SHOW_SPRITES|PPU_SHOW_BACKGROUND
    stx PPUMASK

    rts
.endproc

.proc prepare_oam
    ; cursor sprite, byte 0, y pos = 5
    ldx #$00
    lda #5
    sta oam, x

    ; cursor sprite, byte 1, tile = 0
    inx
    lda #0
    sta oam, x

    ; cursor sprite, byte 2, attributes
    inx
    lda #OAM_ATTR_PALETTE_4
    sta oam, x

    ; cursor sprite, byte 4, x pos = 5
    inx
    lda #5
    sta oam, x

    rts
.endproc

; The RODATA segment is read-only data in PRG ROM 
.segment "RODATA"
palette_data:
.byte $0F, $20, $21, $15 ; background palette 0 - black, white, blue, red
.byte $0F, $00 ,$00, $00 ; background palette 1
.byte $0F, $00, $00, $00 ; background palette 2
.byte $0F, $00, $00, $00 ; background palette 3
.byte $0F, $20, $21, $15 ; sprite palette 0 - black, white, blue, red
.byte $0F, $00, $00, $00 ; sprite palette 1
.byte $0F, $00, $00, $00 ; sprite palette 2
.byte $0F, $00, $00, $00 ; sprite palette 3

; The TILES segment contains the graphics data in CHR ROM
.segment "TILES"
.incbin "background.chr"
.incbin "sprites.chr"
