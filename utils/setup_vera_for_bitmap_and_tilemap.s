; This sets up VERA for a bitmap (320x240) in layer 0 and a tile map (8x8) in layer 1

BITMAP_WIDTH = 320
BITMAP_HEIGHT = 240
TILE_MAP_WIDTH = 128
TILE_MAP_HEIGHT = 64

setup_vera_for_bitmap_and_tile_map:

    ; -- First wait until VERA is ready

    ldx #$A5
wait_for_vera:
    lda #42
    sta VERA_ADDR_LOW

    lda VERA_ADDR_LOW
    cmp #42
    beq vera_ready
    
    ldy #0
vera_boot_snooze:
    nop
    nop
    nop
    nop
    nop
    nop
    iny
    bne vera_boot_snooze
    
    dex
    bne wait_for_vera
    
vera_not_working:

    ; TODO: VERA is not responding, we should fall back into outputting to VIA and/or maybe the YM2151
    
vera_ready:    

    ; -- Show first sign of live by enabling VGA as soon as possible
  
    ; lda #%00010001           ; Enable Layer 0, Enable VGA
    ; lda #%00100001           ; Enable Layer 1, Enable VGA
    ; lda #%00110001           ; Enable Layer 0 and 1, Enable VGA
    lda #%01110001           ; Enable Layer 0 and 1 and sprites, Enable VGA
    ; lda #%01000001           ; Enable sprites, Enable VGA
    sta VERA_DC_VIDEO

    lda #0                   ; Set Horizontal and vertical scoll to 0
    sta VERA_L0_HSCROLL_L
    sta VERA_L0_HSCROLL_H
    sta VERA_L0_VSCROLL_L
    sta VERA_L0_VSCROLL_H
    
    sta VERA_L1_HSCROLL_L
    sta VERA_L1_HSCROLL_H
    sta VERA_L1_VSCROLL_L
    sta VERA_L1_VSCROLL_H

    lda #$40                 ; 2:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    ; -- Layer 0 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; VERA.layer0.config = (4 + 3) ; enable bitmap mode and color depth = 8bpp on layer 0
    lda #(4+3)
    sta VERA_L0_CONFIG

    ; VERA.layer0.tilebase = ; set new tilebase for layer 0 (0x00000)
    ; NOTE: this also sets the TILE WIDTH to 320 px!!
    lda #($000 >> 1)
    sta VERA_L0_TILEBASE
    
    ; -- Layer 1 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; TODO: use TILE_MAP_HEIGHT and TILE_MAP_WIDTH to determine this value!
    lda #%10100000           ; Set map height/width to 64/128, and Tile mode 1 bpp (16 color text mode)
    sta VERA_L1_CONFIG
    
    lda #($1B0 >> 1)         ; Set mapbase for layer 1 to 0x1B000. This also sets the tile width and height to 8 px
    sta VERA_L1_MAPBASE
    
    lda #($1F0 >> 1)         ; Set tilebase for layer 1 to 0x1F000. This also sets the tile width and height to 8 px
    sta VERA_L1_TILEBASE

    rts
    
    
copy_petscii_charset:

    ; -- Copy petscii charset to VRAM at $1F000-$1F7FF
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda #$F0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW

    .ifdef CREATE_PRG
    
; FIXME: IMPLEMENT LOADING PETSCII CHARSET FROM ROM BANK 6!
; FIXME: IMPLEMENT LOADING PETSCII CHARSET FROM ROM BANK 6!
; FIXME: IMPLEMENT LOADING PETSCII CHARSET FROM ROM BANK 6!

; Maybe we can define copy_petscii_0-7 and set them to ROM addresses?
; Maybe we can define copy_petscii_0-7 and set them to ROM addresses?
; Maybe we can define copy_petscii_0-7 and set them to ROM addresses?
    
    .else
    ldy #0
copy_petscii_0:
    lda petscii_0, y
    sta VERA_DATA0
    iny
    bne copy_petscii_0
    
    ldy #0
copy_petscii_1:
    lda petscii_1, y
    sta VERA_DATA0
    iny
    bne copy_petscii_1
    
    ldy #0
copy_petscii_2:
    lda petscii_2, y
    sta VERA_DATA0
    iny
    bne copy_petscii_2
    
    ldy #0
copy_petscii_3:
    lda petscii_3, y
    sta VERA_DATA0
    iny
    bne copy_petscii_3
    
    ldy #0
copy_petscii_4:
    lda petscii_4, y
    sta VERA_DATA0
    iny
    bne copy_petscii_4
    
    ldy #0
copy_petscii_5:
    lda petscii_5, y
    sta VERA_DATA0
    iny
    bne copy_petscii_5
    
    ldy #0
copy_petscii_6:
    lda petscii_6, y
    sta VERA_DATA0
    iny
    bne copy_petscii_6
    
    ldy #0
copy_petscii_7:
    lda petscii_7, y
    sta VERA_DATA0
    iny
    bne copy_petscii_7
    .endif

    rts

clear_tilemap_screen:
    
    ; This will clear the screen without using RAM.

    ; -- Fill tilemap into VRAM at $1B000-$1EBFF (FIXME: should this not be $1B000 - $1EFFF?, since (TILE_MAP_HEIGHT / (256 / TILE_MAP_WIDTH)) = 32?) -> $20 * 2 * 256

vera_clear_start:
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ldy #(TILE_MAP_HEIGHT / (256 / TILE_MAP_WIDTH))
vera_clear_fill_tile_map:
    ldx #0
vera_clear_fill_tile_map_row:
    lda #$20
    sta VERA_DATA0           ; character index = 'space'
    lda #COLOR_TRANSPARANT
    sta VERA_DATA0           ; Fill Foreground and background color
    inx
    bne vera_clear_fill_tile_map_row
    dey
    bne vera_clear_fill_tile_map

    rts
    
init_cursor:

    ; Init cursor for printing to screen
    ; lda #(LEFT_MARGIN+INDENT_SIZE)
    lda #(LEFT_MARGIN)   ; no indenting at the start
    sta INDENTATION
    sta CURSOR_X
    lda #(TOP_MARGIN)
    sta CURSOR_Y

    rts
    
    

clear_bitmap_screen:
    ldx #0
fill_bitmap_once:

    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #BITMAP_HEIGHT
fill_bitmap_col_once:
    sta VERA_DATA0           ; store pixel
    dey
    bne fill_bitmap_col_once
    inx
    bne fill_bitmap_once

    ; Right part of the screen

    ldx #0
fill_bitmap_once2:

    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$01                ; The right side part of the screen has a start byte starting at address 256 and up
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #BITMAP_HEIGHT
fill_bitmap_col_once2:
    sta VERA_DATA0           ; store pixel
    dey
    bne fill_bitmap_col_once2
    inx
    cpx #64                  ; The right part of the screen is 320 - 256 = 64 pixels
    bne fill_bitmap_once2

    
    rts
    
clear_sprite_data:
    
    ; Sprite data is from $1FC00 - $1FFFF	
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit (=1), setting auto-increment value to 1px
    sta VERA_ADDR_BANK
    lda #$FC
    sta VERA_ADDR_HIGH
    sta VERA_ADDR_LOW
    
    lda #0 ; clear with zero
    
    ldy #4
clear_sprite_data_256:
    ldx #0
clear_sprite_data_1:
    sta VERA_DATA0
    inx
    bne clear_sprite_data_1
    dey
    bne clear_sprite_data_256
    
    rts