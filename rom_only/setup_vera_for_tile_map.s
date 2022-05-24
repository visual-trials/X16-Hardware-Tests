; This sets up VERA for a petscii tile map (8x8) in layer 0
; It uses no RAM (ROM only)

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
    
    ; -- Change some colors in the palette
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda #$FA
    sta VERA_ADDR_HIGH
    lda #$08                 ; We use color 4 in the pallete (each color takes 2 bytes)
    sta VERA_ADDR_LOW

    lda #$05                 ; gb
    sta VERA_DATA0
    lda #$05                 ; -r
    sta VERA_DATA0
    
    lda #$FA
    sta VERA_ADDR_HIGH
    lda #$04                 ; We use color 2 in the pallete (each color takes 2 bytes)
    sta VERA_ADDR_LOW

    lda #$00                 ; gb
    sta VERA_DATA0
    lda #$0F                 ; -r
    sta VERA_DATA0
    
    ; -- Copy petscii charset to VRAM at $1F000-$1F7FF
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda #$F0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
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
