;
; hello.s
;
; Author: Matthew Justice
; Description: A simple Hello World style program for the NES
;

.include "constants.inc"

; imports from init.s
.import reset_handler
; imports from ppu.s
.import dma_oam_transfer
; imports from controllers.s
.import get_controller_inputs
; imports from game.s
.import update_state_from_inputs, prepare_oam

; make available for linked code
.global game_loop, oam, palette_data, controller1_state, ship_x, ship_y, ship_orientation

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
; of RAM. Accessing this area of memory is faster than
; accessing other areas. Store in-memory variables here.
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

; game_loop
; The game_loop game logic
; This code is invoked from reset_handler after it initializes the NES
.proc game_loop
forever:
    ; Read the state of the controllers
    jsr get_controller_inputs

    ; Update game state based on controller state
    jsr update_state_from_inputs

    ; prepare OAM data
    jsr prepare_oam

    ; wait on a VBLANK NMI
    lda nmi_count
game_loop_vblank_wait:
    cmp nmi_count
    beq game_loop_vblank_wait

    ; Copy OAM data to the PPU
    jsr dma_oam_transfer

    jmp forever
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
