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
APUFRAME    = $4017 ; write for APU (read is controller 2)

; constants for contollers
CONTROLLER_1      = $4016
CONTROLLER_2      = $4017
CONTROLLER_RIGHT  = $01
CONTROLLER_LEFT   = $02
CONTROLLER_DOWN   = $04
CONTROLLER_UP     = $08
CONTROLLER_START  = $10
CONTROLLER_SELECT = $20
CONTROLLER_B      = $40
CONTROLLER_A      = $80

; constants for game state
SHIP_ORIENTATION_UP    = 1
SHIP_ORIENTATION_DOWN  = 2
SHIP_ORIENTATION_LEFT  = 3
SHIP_ORIENTATION_RIGHT = 4

; constants for sprite tiles
TILE_SHIP_UP_DOWN       = 0
TILE_SHIP_LEFT_RIGHT    = 1

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
locals:             .res 16 ; save 16 bytes for local variables
nmi_count:          .res 1  ; increments on VBLANK NMI
controller1_state:  .res 1  ; the last read state of controller 1
ship_x:             .res 1  ; the x coordinate of the ship
ship_y:             .res 1  ; the y coordinate of the ship
ship_orientation:   .res 1  ; the orientation of the ship

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

    ; Initial game state
    lda #10
    sta ship_x
    lda #20
    sta ship_y
    lda #SHIP_ORIENTATION_UP
    sta ship_orientation
forever:
    ; Read the state of the controllers
    jsr read_controllers

    ; Update game state based on controller state
    jsr handle_controller_state

    ; prepare OAM data
    jsr prepare_oam

    ; wait on a VBLANK NMI
    lda nmi_count
main_vblank_wait:
    cmp nmi_count
    beq main_vblank_wait

    ; Copy OAM data to the PPU
    jsr dma_oam_transfer

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
    ; define addresses of local variables
    tile_number = 0
    oam_attribs   = 1

    lda ship_orientation
check_ship_up:
    cmp #SHIP_ORIENTATION_UP
    bne check_ship_down
    ; Ship is up
    ldx #TILE_SHIP_UP_DOWN
    stx tile_number
    ldx #OAM_ATTR_PALETTE_4
    stx oam_attribs
    jmp write_oam_data

check_ship_down:
    cmp #SHIP_ORIENTATION_DOWN
    bne check_ship_left
    ; Ship is down
    ldx #TILE_SHIP_UP_DOWN
    stx tile_number
    ldx #OAM_ATTR_PALETTE_4|OAM_ATTR_FLIP_VERT
    stx oam_attribs
    jmp write_oam_data

check_ship_left:
    cmp #SHIP_ORIENTATION_LEFT
    bne check_ship_right
    ; Ship is left
    ldx #TILE_SHIP_LEFT_RIGHT
    stx tile_number
    ldx #OAM_ATTR_PALETTE_4|OAM_ATTR_FLIP_HORIZ
    stx oam_attribs
    jmp write_oam_data

check_ship_right:
    cmp #SHIP_ORIENTATION_RIGHT
    bne write_oam_data
    ; Ship is right
    ldx #TILE_SHIP_LEFT_RIGHT
    stx tile_number
    ldx #OAM_ATTR_PALETTE_4
    stx oam_attribs

write_oam_data:
    ; ship sprite, byte 0, y pos
    ldx #$00
    lda ship_y
    sta oam, x

    ; ship sprite, byte 1, tile number
    inx
    lda tile_number
    sta oam, x

    ; ship sprite, byte 2, attributes
    inx
    lda oam_attribs
    sta oam, x

    ; ship sprite, byte 4, x pos
    inx
    lda ship_x
    sta oam, x

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

.proc read_controllers
    ; Write 1 to $CONTROLLER_1 to retrieve the buttons currently held
    lda #1
    sta CONTROLLER_1

    ; Write 0 to $CONTROLLER_1 to go finish the poll of buttons
    lda #0
    sta CONTROLLER_1

    ; Read the polled data button at a time (8 buttons total)
    ; Each button's state comes back one byte at at time
    ldx #8
controller_read_loop:
    lda CONTROLLER_1 ; bit 0 = NES/Famicom, bit 1 = Fami Expansion
    and #%00000011   ; ignore the other bits 
    cmp #1           ; carry = 1 if bits are => 1, carry = 0 otherwise
    rol controller1_state ; move the carry bit to lsb of controller1_state
    dex
    bne controller_read_loop
    rts
.endproc

; handle_controller_state
; Check the various controller buttons and set game state
.proc handle_controller_state
check_left:
    lda controller1_state
    and #CONTROLLER_LEFT  ; if left is pressed, zero flag is 0
    beq check_right       ; branch if left isn't pressed
    ; left is pressed, move ship left
    ldx ship_x
    dex
    stx ship_x
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_LEFT
    stx ship_orientation
    ; if left is pressed, right should not be pressed too
    ; jump ahead to checking up/down
    jmp check_up

check_right:
    lda controller1_state
    and #CONTROLLER_RIGHT   ; if right is pressed, zero flag is 0
    beq check_up            ; branch if right isn't pressed
    ; right is pressed, move ship right
    ldx ship_x
    inx
    stx ship_x
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_RIGHT
    stx ship_orientation

check_up:
    lda controller1_state
    and #CONTROLLER_UP      ; if up is pressed, zero flag is 0
    beq check_down          ; branch if up isn't pressed
    ; up is pressed, move ship up
    ldx ship_y
    dex
    stx ship_y
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_UP
    stx ship_orientation
    ; if up is pressed, down should not be pressed too
    ; jump ahead to checking buttons
    jmp check_a

check_down:
    lda controller1_state
    and #CONTROLLER_DOWN    ; if down is pressed, zero flag is 0
    beq check_a             ; branch if down isn't pressed
    ; down is pressed, move ship down
    ldx ship_y
    inx
    stx ship_y
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_DOWN
    stx ship_orientation

check_a:
    ; TODO - buttons
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
