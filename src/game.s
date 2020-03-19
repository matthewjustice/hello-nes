;
; game.s
;
; Author: Matthew Justice
; Description: Contains the game logic code.
;

.include "constants.inc"
.import oam
.importzp ship_x, ship_y, ship_orientation, controller1_state
.global set_initial_game_state, update_state_from_inputs, prepare_oam

; set_initial_game_state
; Sets the initial game state
.proc set_initial_game_state
    lda #SHIP_INITIAL_X
    sta ship_x
    lda #SHIP_INITIAL_Y
    sta ship_y
    lda #SHIP_ORIENTATION_UP
    sta ship_orientation
    rts
.endproc

; update_state_from_inputs
; Check the various controller buttons and set game state
.proc update_state_from_inputs
check_up:
    lda controller1_state
    and #CONTROLLER_UP      ; if up is pressed, zero flag is 0
    beq check_down          ; branch if up isn't pressed
    ; up is pressed, move ship up if we aren't at the boundary
    lda ship_y
    cmp #SHIP_MIN_Y_POSITION ; if ship_y == min and up was pressed, then
    beq orient_up            ; we are at the boundary, don't move the ship  
    dec ship_y               ; otherwise, move ship up
orient_up:
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_UP
    stx ship_orientation
    ; if up is pressed, down should not be pressed too
    ; jump ahead to checking left/right
    jmp check_left

check_down:
    lda controller1_state
    and #CONTROLLER_DOWN    ; if down is pressed, zero flag is 0
    beq check_left          ; branch if down isn't pressed
    ; down is pressed, move ship down if we aren't at the boundary
    lda ship_y
    cmp #SHIP_MAX_Y_POSITION ; if ship_y == max and down was pressed, then
    beq orient_down          ; we are at the boundary, don't move the ship 
    inc ship_y               ; otherwise, move ship down       
orient_down:
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_DOWN
    stx ship_orientation

check_left:
    lda controller1_state
    and #CONTROLLER_LEFT  ; if left is pressed, zero flag is 0
    beq check_right       ; branch if left isn't pressed
    ; left is pressed, move ship left if we aren't at the boundary
    lda ship_x
    cmp #SHIP_MIN_X_POSITION ; if ship_x == min and left was pressed, then
    beq orient_left          ; we are at the boundary, don't move the ship
    dec ship_x               ; otherwise, move ship left
orient_left:
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_LEFT
    stx ship_orientation
    ; if left is pressed, right should not be pressed too
    ; jump ahead to checking buttons
    jmp check_a

check_right:
    lda controller1_state
    and #CONTROLLER_RIGHT   ; if right is pressed, zero flag is 0
    beq check_a             ; branch if right isn't pressed
    ; right is pressed, move ship right if we aren't at the boundary
    lda ship_x
    cmp #SHIP_MAX_X_POSITION ; if ship_x == max and right was pressed, then
    beq orient_right         ; we are at the boundary, don't move the ship     
    inc ship_x               ; otherwise, move ship right
orient_right:
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_RIGHT
    stx ship_orientation

check_a:
    ; TODO - buttons
    rts
.endproc

; prepare_oam
; Use the current game state to prepare the OAM data in RAM
; for later transfer to the PPU's internal OAM.
; This bridges the gap between pure game logic and interacting
; with the display (PPU).
.proc prepare_oam
    ldx #$00

    ; ship sprite, byte 0, y position
    ; sprites are displayed one scanline lower than requested
    ; so decrement the desired position before writing it to oam
    ldy ship_y
    dey
    tya
    sta oam, x

    ; ship sprite, byte 1, tile number
    inx
    ldy ship_orientation
    lda ship_tile_table, y
    sta oam, x

    ; ship sprite, byte 2, attributes
    inx
    lda ship_attrib_table, y
    sta oam, x

    ; ship sprite, byte 3, x position
    inx
    lda ship_x
    sta oam, x

    rts
.endproc

; The RODATA segment is read-only data in PRG ROM 
.segment "RODATA"

; Use lookup tables to map between game state 
; (ship_orientation in particular) and oam
; data (tile number and attributes)
ship_tile_table:
.byte TILE_SHIP_UP_DOWN     ; table[SHIP_ORIENTATION_UP]
.byte TILE_SHIP_UP_DOWN     ; table[SHIP_ORIENTATION_DOWN]
.byte TILE_SHIP_LEFT_RIGHT  ; table[SHIP_ORIENTATION_LEFT]
.byte TILE_SHIP_LEFT_RIGHT  ; table[SHIP_ORIENTATION_RIGHT]

ship_attrib_table:
.byte OAM_ATTR_PALETTE_4                     ; table[SHIP_ORIENTATION_UP]
.byte OAM_ATTR_PALETTE_4|OAM_ATTR_FLIP_VERT  ; table[SHIP_ORIENTATION_DOWN]
.byte OAM_ATTR_PALETTE_4|OAM_ATTR_FLIP_HORIZ ; table[SHIP_ORIENTATION_LEFT]
.byte OAM_ATTR_PALETTE_4                     ; table[SHIP_ORIENTATION_RIGHT]
