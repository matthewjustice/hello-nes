;
; game.s
;
; Author: Matthew Justice
; Description: Contains the game logic code.
;

.include "constants.inc"
.import oam
.importzp ship_x, ship_y, ship_orientation, controller1_state
.global set_initial_game_state, handle_controller_state, prepare_oam

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

; handle_controller_state
; Check the various controller buttons and set game state
.proc handle_controller_state
check_left:
    lda controller1_state
    and #CONTROLLER_LEFT  ; if left is pressed, zero flag is 0
    beq check_right       ; branch if left isn't pressed
    ; left is pressed, move ship left
    dec ship_x
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
    inc ship_x
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_RIGHT
    stx ship_orientation

check_up:
    lda controller1_state
    and #CONTROLLER_UP      ; if up is pressed, zero flag is 0
    beq check_down          ; branch if up isn't pressed
    ; up is pressed, move ship up
    dec ship_y
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
    inc ship_y
    ; set ship orientation 
    ldx #SHIP_ORIENTATION_DOWN
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
    lda ship_y
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

    ; ship sprite, byte 4, x position
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
