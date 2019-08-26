;
; constants.s
;
; Author: Matthew Justice
; Description: Constant values used to represent NES hardware 
; and game logic state.
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
SHIP_ORIENTATION_UP     = 1
SHIP_ORIENTATION_DOWN   = 2
SHIP_ORIENTATION_LEFT   = 3
SHIP_ORIENTATION_RIGHT  = 4
SHIP_INITIAL_X          = 127
SHIP_INITIAL_Y          = 140

; constants for sprite tiles
TILE_SHIP_UP_DOWN       = 0
TILE_SHIP_LEFT_RIGHT    = 1