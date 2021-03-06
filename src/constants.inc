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

; High byte values of nametable addresses
NAMETABLE_HIGH_BYTE_UPPER_LEFT  = $20       ; at $2000
NAMETABLE_HIGH_BYTE_UPPER_RIGHT = $24       ; at $2400
NAMETABLE_HIGH_BYTE_LOWER_LEFT  = $28       ; at $2800
NAMETABLE_HIGH_BYTE_LOWER_RIGHT = $2C       ; at $2C00

; High byte values of nametable attribute tables
ATTRIB_TABLE_HIGH_BYTE_UPPER_LEFT  = $23    ; at $23C0
ATTRIB_TABLE_HIGH_BYTE_UPPER_RIGHT = $27    ; at $27C0
ATTRIB_TABLE_HIGH_BYTE_LOWER_LEFT  = $2B    ; at $2BC0
ATTRIB_TABLE_HIGH_BYTE_LOWER_RIGHT = $2F    ; at $2FC0

; Size of attribute table
ATTRIBUTE_TABLE_SIZE               =  64

; constants used by PPUCTRL
PPU_ENABLE_VBLANK     = $80
PPU_SPRITE_SIZE_8     = $00
PPU_SPRITE_SIZE_16    = $20
PPU_BG_TABLE_AT_0000  = $00
PPU_BG_TABLE_AT_1000  = $10
PPU_SP_TABLE_AT_0000  = $00
PPU_SP_TABLE_AT_1000  = $08
PPU_VRAM_INCREMENT_01 = $00
PPU_VRAM_INCREMENT_32 = $04
PPU_BASE_NAMETABLE_3  = $03
PPU_BASE_NAMETABLE_2  = $02
PPU_BASE_NAMETABLE_1  = $01
PPU_BASE_NAMETABLE_0  = $00

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
SHIP_ORIENTATION_UP     = 0
SHIP_ORIENTATION_DOWN   = 1
SHIP_ORIENTATION_LEFT   = 2
SHIP_ORIENTATION_RIGHT  = 3
SHIP_INITIAL_X          = 127
SHIP_INITIAL_Y          = 140

; constants for sprite tiles
TILE_SHIP_UP_DOWN       = 0
TILE_SHIP_LEFT_RIGHT    = 1

; constants for sprite positioning
DISPLAY_WIDTH           = 256
DISPLAY_HEIGHT          = 240
SHIP_HEIGHT             = 8
SHIP_WIDTH              = 8
SHIP_MIN_X_POSITION     = 0
SHIP_MIN_Y_POSITION     = 1
SHIP_MAX_Y_POSITION     = DISPLAY_HEIGHT - SHIP_HEIGHT
SHIP_MAX_X_POSITION     = DISPLAY_WIDTH  - SHIP_WIDTH