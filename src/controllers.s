;
; controllers.s
;
; Author: Matthew Justice
; Description: Code for interacting with the
; NES's controllers
;

.include "constants.inc"
.importzp controller1_state
.global read_controllers

.segment "CODE"

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