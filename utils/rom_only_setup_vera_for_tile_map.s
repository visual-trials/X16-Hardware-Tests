; This sets up VERA for a tile map (8x8) in layer 0
; It uses no RAM (ROM only)

TILE_MAP_WIDTH = 128
TILE_MAP_HEIGHT = 64

    ; -- First wait until VERA is ready
    
wait_for_vera:
    lda #42
    sta VERA_ADDR_LOW

    lda VERA_ADDR_LOW
    cmp #42
    bne wait_for_vera
    
    ; -- Show first sign of live by enabling VGA as soon as possible
  
    lda #%00010001           ; Enable Layer 0, Enable VGA
    sta VERA_DC_VIDEO

    lda #0                   ; Set Horizontal and vertical scoll to 0
    sta VERA_L0_HSCROLL_L
    sta VERA_L0_HSCROLL_H
    sta VERA_L0_VSCROLL_L
    sta VERA_L0_VSCROLL_H

    lda #$80                 ; 1:1 scale (640 x 480 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; TODO: use TILE_MAP_HEIGHT and TILE_MAP_WIDTH to determine this value!
    lda #%10100000           ; Set map height/width to 64/128, and Tile mode 1 bpp (16 color text mode)
    sta VERA_L0_CONFIG
    
    lda #($1B0 >> 1)         ; Set mapbase for layer 0 to 0x1B000. This also sets the tile width and height to 8 px
    sta VERA_L0_MAPBASE
    
    lda #($1F0 >> 1)         ; Set tilebase for layer 0 to 0x1F000. This also sets the tile width and height to 8 px
    sta VERA_L0_TILEBASE
    
