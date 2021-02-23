;
; ppu.s
;
; Author: Matthew Justice
; Description: Code for interacting with the
; NES's Picture Processing Unit (PPU)
;

.include "constants.inc"
.import oam, palette_data
.global dma_oam_transfer, turn_on_screen, show_background, load_palette, clear_background_tiles, clear_background_attributes

.segment "CODE"

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

; dma_oam_transfer
; Use DMA to transfer the local RAM OAM data
; to the PPU's internal OAM 
.proc dma_oam_transfer
    lda #0      ; Set OAM address to 0
    sta OAMADDR
    lda #>oam   ; a = high byte of OAM start address ($XX)
    sta OAMDMA  ; Upload 256 bytes from RAM $XX00 to PPU OAM
    rts
.endproc

;
; clear_background_tiles
; Sets all the background tiles to the same tile value
; Params:
;  x            - nametable address high byte (NAMETABLE_HIGH_BYTE_*)
;  a            - The tile value to set
.proc clear_background_tiles
    ; Increment VRAM addresses by 1 (horizontal updates)
    ldy #PPU_ENABLE_VBLANK|PPU_SPRITE_SIZE_16|PPU_BG_TABLE_AT_0000|PPU_BASE_NAMETABLE_0|PPU_VRAM_INCREMENT_01
    sty PPUCTRL

    ; Set the nametable address
    stx PPUADDR
    ldx #0
    stx PPUADDR

    ; We need to write 960 tiles, or 240 tiles 4 times.
    ldy #4                  ; y is the outer loop counter
outer_write_tiles_loop:
    ldx #240                ; x is the inner loop counter
inner_write_tiles_loop:
    sta PPUDATA
    dex
    bne inner_write_tiles_loop
    dey
    bne outer_write_tiles_loop

    rts
.endproc

; clear_background_attributes
; Set all background attributes for the specified nametable to 0
; Params:
;  x            - x - attrib table address high byte (ATTRIB_TABLE_HIGH_BYTE_*)
.proc clear_background_attributes
    ; Increment VRAM addresses by 1 (horizontal updates)
    ldy #PPU_ENABLE_VBLANK|PPU_SPRITE_SIZE_16|PPU_BG_TABLE_AT_0000|PPU_BASE_NAMETABLE_0|PPU_VRAM_INCREMENT_01
    sty PPUCTRL

    ; x (passed in) is the high byte of the nametable
    stx PPUADDR
    ldx #$C0
    stx PPUADDR

    lda #0  ; attribute value is 0
    ldy #0  ; y is our counter
clear_background_attribute_loop:
    sta PPUDATA
    iny
    cpy #ATTRIBUTE_TABLE_SIZE
    bne clear_background_attribute_loop
    rts
.endproc
