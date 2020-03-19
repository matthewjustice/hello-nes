;
; init.s
;
; Author: Matthew Justice
; Description: Code for initializing the NES hardware
;

.include "constants.inc"
.import oam, game_loop, set_initial_game_state, turn_on_screen, show_background, load_palette
.global reset_handler

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

    ; set the initial game state
    jsr set_initial_game_state

    ; Wait on the second VBLANK
vblank_wait_2:
    bit PPUSTATUS       ; set flag N = bit 7 of PPUSTATUS (1 = in VBLANK)
    bpl vblank_wait_2   ; loop while flag N=0 (while not in VBLANK)

    ; We just read PPUSTATUS and should be in VBLANK
    ; Load the palette
    jsr load_palette

    ; Show the background
    jsr show_background

    ; Turn on screen
    jsr turn_on_screen

    ; All set up; transfer execution to game_loop 
    jmp game_loop 
.endproc
